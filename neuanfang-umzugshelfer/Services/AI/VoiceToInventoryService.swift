//
//  VoiceToInventoryService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import AVFoundation
import Speech
import CoreData

/// Service für die Umwandlung von Spracheingaben in Item-Kategorien
@MainActor
final class VoiceToInventoryService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var recognizedText = ""
    @Published var extractedItems: [ParsedItem] = []
    @Published var errorMessage: String?
    @Published var recordingLevel: Float = 0.0
    
    // MARK: - Dependencies
    
    private let foundationService: FoundationModelsService
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Audio & Speech Recognition
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession: AVAudioSession = .sharedInstance()
    
    // MARK: - Initialization
    
    init(foundationService: FoundationModelsService = .shared,
         viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.foundationService = foundationService
        self.viewContext = viewContext
        super.init()
        
        setupSpeechRecognition()
    }
    
    // MARK: - Public Methods
    
    /// Startet die Sprachaufnahme für Inventarisierung
    func startVoiceRecording() async throws {
        guard await requestPermissions() else {
            throw VoiceError.permissionDenied
        }
        
        try await startRecording()
    }
    
    /// Stoppt die Sprachaufnahme
    func stopVoiceRecording() {
        stopRecording()
    }
    
    /// Verarbeitet erkannten Text zu Items
    func processRecognizedText(_ text: String) async throws -> [ParsedItem] {
        isProcessing = true
        defer { isProcessing = false }
        
        let items = try await parseItemsFromText(text)
        extractedItems = items
        
        return items
    }
    
    /// Erstellt Items aus geparsten Daten in Core Data
    func createItemsFromParsedData(_ parsedItems: [ParsedItem], in box: Box) async throws -> [Item] {
        var createdItems: [Item] = []
        
        for parsedItem in parsedItems {
            let item = Item(context: viewContext)
            item.name = parsedItem.name
            item.category = parsedItem.category.rawValue
            item.isFragile = parsedItem.isFragile
            item.estimatedValue = parsedItem.estimatedValue
            item.itemDescription = parsedItem.description
            item.createdDate = Date()
            item.box = box
            
            createdItems.append(item)
        }
        
        try viewContext.save()
        return createdItems
    }
    
    /// Kontinuierliche Spracherkennung für Live-Inventarisierung
    func startContinuousRecognition() async throws {
        guard await requestPermissions() else {
            throw VoiceError.permissionDenied
        }
        
        try await startContinuousListening()
    }
    
    /// Stoppt kontinuierliche Spracherkennung
    func stopContinuousRecognition() {
        stopRecording()
    }
    
    /// Korrigiert erkannte Items durch Nachbearbeitung
    func refineRecognizedItems(_ items: [ParsedItem]) async throws -> [ParsedItem] {
        let prompt = buildRefinementPrompt(items: items)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 300)
        
        return parseRefinedItems(response)
    }
    
    // MARK: - Private Methods - Speech Recognition Setup
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
        speechRecognizer?.delegate = self
    }
    
    private func requestPermissions() async -> Bool {
        // Request Speech Recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        guard speechStatus else {
            errorMessage = "Spracherkennung nicht erlaubt"
            return false
        }
        
        // Request Microphone permission
        let microphoneStatus = await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
        
        guard microphoneStatus else {
            errorMessage = "Mikrofon-Zugriff nicht erlaubt"
            return false
        }
        
        return true
    }
    
    // MARK: - Recording Methods
    
    private func startRecording() async throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.setupFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw VoiceError.setupFailed
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
            
            // Calculate recording level for UI
            let level = self.calculateRecordingLevel(from: buffer)
            DispatchQueue.main.async {
                self.recordingLevel = level
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        guard let speechRecognizer = speechRecognizer else {
            throw VoiceError.recognizerUnavailable
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    self.errorMessage = "Erkennungsfehler: \(error.localizedDescription)"
                    self.stopRecording()
                }
            }
        }
        
        isRecording = true
    }
    
    private func startContinuousListening() async throws {
        try await startRecording()
        
        // Setup timer for processing recognized text in chunks
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            if !self.recognizedText.isEmpty && !self.isProcessing {
                Task {
                    do {
                        let _ = try await self.processRecognizedText(self.recognizedText)
                        await MainActor.run {
                            self.recognizedText = "" // Clear for next chunk
                        }
                    } catch {
                        await MainActor.run {
                            self.errorMessage = "Verarbeitungsfehler: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
    
    private func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
        
        isRecording = false
        recordingLevel = 0.0
        
        try? audioSession.setActive(false)
    }
    
    private func calculateRecordingLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataValueArray.count))
        let avgPower = 20 * log10(rms)
        let normalizedPower = max(0, (avgPower + 50) / 50) // Normalize to 0-1
        
        return min(normalizedPower, 1.0)
    }
    
    // MARK: - Text Processing Methods
    
    private func parseItemsFromText(_ text: String) async throws -> [ParsedItem] {
        let prompt = buildParsingPrompt(text: text)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 400)
        
        return parseItemsFromAIResponse(response)
    }
    
    private func buildParsingPrompt(text: String) -> String {
        return """
        Analysiere den folgenden deutschen Text und extrahiere alle genannten Gegenstände für einen Umzug:
        
        Text: "\(text)"
        
        Für jeden Gegenstand bestimme:
        - Name (normalisiert)
        - Kategorie (electronics, clothing, books, kitchen, furniture, decoration, documents, tools, toys, sports, other)
        - Ob zerbrechlich (ja/nein)
        - Geschätzter Wert in Euro (falls erkennbar)
        - Zusätzliche Beschreibung
        
        Format pro Gegenstand:
        Name: [Name]
        Kategorie: [Kategorie]
        Zerbrechlich: [ja/nein]
        Wert: [Zahl in Euro]
        Beschreibung: [Text]
        ---
        
        Beispiel:
        Name: Laptop
        Kategorie: electronics
        Zerbrechlich: ja
        Wert: 800
        Beschreibung: Gaming-Laptop, 15 Zoll
        ---
        """
    }
    
    private func buildRefinementPrompt(items: [ParsedItem]) -> String {
        let itemDescriptions = items.map { item in
            "Name: \(item.name), Kategorie: \(item.category.rawValue), Zerbrechlich: \(item.isFragile ? "ja" : "nein")"
        }.joined(separator: "\n")
        
        return """
        Überprüfe und verfeinere die folgenden erkannten Gegenstände:
        
        \(itemDescriptions)
        
        Korrigiere:
        - Rechtschreibfehler
        - Falsche Kategorisierungen
        - Fehlende Zerbrechlichkeits-Markierungen
        - Unpassende Wertschätzungen
        
        Gib die korrigierten Gegenstände im gleichen Format zurück.
        """
    }
    
    private func parseItemsFromAIResponse(_ response: String) -> [ParsedItem] {
        var items: [ParsedItem] = []
        let sections = response.components(separatedBy: "---")
        
        for section in sections {
            let lines = section.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            var name = ""
            var category = ItemCategory.other
            var isFragile = false
            var estimatedValue = 0.0
            var description = ""
            
            for line in lines {
                if line.lowercased().hasPrefix("name:") {
                    name = extractValue(from: line)
                } else if line.lowercased().hasPrefix("kategorie:") {
                    let categoryString = extractValue(from: line)
                    category = ItemCategory.fromString(categoryString)
                } else if line.lowercased().hasPrefix("zerbrechlich:") {
                    let fragileString = extractValue(from: line).lowercased()
                    isFragile = fragileString.contains("ja") || fragileString.contains("yes")
                } else if line.lowercased().hasPrefix("wert:") {
                    let valueString = extractValue(from: line)
                    estimatedValue = parseValue(from: valueString)
                } else if line.lowercased().hasPrefix("beschreibung:") {
                    description = extractValue(from: line)
                }
            }
            
            if !name.isEmpty {
                let item = ParsedItem(
                    name: name,
                    category: category,
                    isFragile: isFragile,
                    estimatedValue: estimatedValue,
                    description: description.isEmpty ? nil : description,
                    confidence: calculateConfidence(for: name)
                )
                items.append(item)
            }
        }
        
        return items
    }
    
    private func parseRefinedItems(_ response: String) -> [ParsedItem] {
        // Verwende die gleiche Parsing-Logik wie für die ursprüngliche Antwort
        return parseItemsFromAIResponse(response)
    }
    
    private func extractValue(from line: String) -> String {
        let components = line.components(separatedBy: ":")
        if components.count > 1 {
            return components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
    
    private func parseValue(from string: String) -> Double {
        let cleanString = string.replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Double(cleanString) ?? 0.0
    }
    
    private func calculateConfidence(for itemName: String) -> Double {
        // Einfache Konfidenzberechnung basierend auf Namenslänge und bekannten Begriffen
        let commonItems = ["buch", "tasse", "laptop", "stuhl", "tisch", "bild", "lampe"]
        let nameWords = itemName.lowercased().components(separatedBy: .whitespaces)
        
        let hasCommonWord = nameWords.contains { word in
            commonItems.contains { $0.contains(word) || word.contains($0) }
        }
        
        if hasCommonWord {
            return 0.9
        } else if itemName.count > 3 {
            return 0.7
        } else {
            return 0.5
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceToInventoryService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.errorMessage = "Spracherkennung temporär nicht verfügbar"
            }
        }
    }
}

// MARK: - Supporting Types

struct ParsedItem: Identifiable {
    let id = UUID()
    let name: String
    let category: ItemCategory
    let isFragile: Bool
    let estimatedValue: Double
    let description: String?
    let confidence: Double
    
    var isHighConfidence: Bool {
        return confidence >= 0.8
    }
    
    var needsReview: Bool {
        return confidence < 0.7
    }
}

// MARK: - Voice Command Processing

extension VoiceToInventoryService {
    
    /// Verarbeitet spezielle Sprachbefehle
    func processVoiceCommands(_ text: String) async -> [VoiceCommand] {
        var commands: [VoiceCommand] = []
        
        let lowerText = text.lowercased()
        
        // Erkenne Befehle
        if lowerText.contains("neue kiste") || lowerText.contains("neue box") {
            commands.append(.createNewBox)
        }
        
        if lowerText.contains("als zerbrechlich markieren") {
            commands.append(.markAsFragile)
        }
        
        if lowerText.contains("fertig") || lowerText.contains("aufhören") {
            commands.append(.finishRecording)
        }
        
        if lowerText.contains("wiederholen") || lowerText.contains("nochmal") {
            commands.append(.repeatLast)
        }
        
        if lowerText.contains("löschen") || lowerText.contains("entfernen") {
            commands.append(.deleteLastItem)
        }
        
        return commands
    }
}

enum VoiceCommand {
    case createNewBox
    case markAsFragile
    case finishRecording
    case repeatLast
    case deleteLastItem
    case setCategory(ItemCategory)
    case setPriority(BoxPriority)
    
    var description: String {
        switch self {
        case .createNewBox: return "Neue Kiste erstellen"
        case .markAsFragile: return "Als zerbrechlich markieren"
        case .finishRecording: return "Aufnahme beenden"
        case .repeatLast: return "Letzten Gegenstand wiederholen"
        case .deleteLastItem: return "Letzten Gegenstand löschen"
        case .setCategory(let category): return "Kategorie setzen: \(category.displayName)"
        case .setPriority(let priority): return "Priorität setzen: \(priority.displayName)"
        }
    }
}

// MARK: - Voice Recording State

struct VoiceRecordingState {
    var isRecording: Bool = false
    var isPaused: Bool = false
    var duration: TimeInterval = 0
    var level: Float = 0
    var recognizedText: String = ""
    var extractedItemsCount: Int = 0
}

// MARK: - Error Types

enum VoiceError: LocalizedError {
    case permissionDenied
    case setupFailed
    case recognizerUnavailable
    case recordingFailed
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Mikrofon- oder Spracherkennungs-Berechtigung wurde verweigert"
        case .setupFailed:
            return "Audio-Setup fehlgeschlagen"
        case .recognizerUnavailable:
            return "Spracherkennung nicht verfügbar"
        case .recordingFailed:
            return "Aufnahme fehlgeschlagen"
        case .processingFailed:
            return "Verarbeitung der Spracheingabe fehlgeschlagen"
        }
    }
}