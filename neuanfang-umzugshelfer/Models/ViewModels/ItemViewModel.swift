
import SwiftUI
import CoreData

@MainActor
class ItemViewModel: ObservableObject {
    @Published var item: Item
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // Voice-to-Inventory Properties
    @Published var isVoiceRecording = false
    @Published var recognizedText = ""
    @Published var voiceExtractedItems: [ParsedItem] = []
    @Published var isProcessingVoice = false
    @Published var recordingLevel: Float = 0.0
    @Published var voiceCommands: [VoiceCommand] = []
    
    // AI Enhancement Properties
    @Published var suggestedCategory: ItemCategory?
    @Published var suggestedProperties: ItemProperties?
    @Published var isAnalyzingItem = false
    
    // Dependencies
    private let voiceService: VoiceToInventoryService
    private let foundationService: FoundationModelsService

    init(item: Item,
         voiceService: VoiceToInventoryService = VoiceToInventoryService(),
         foundationService: FoundationModelsService = FoundationModelsService.shared) {
        self.item = item
        self.voiceService = voiceService
        self.foundationService = foundationService
        
        setupVoiceServiceBindings()
    }

    func save() {
        do {
            try item.managedObjectContext?.save()
        } catch {
            errorMessage = "Fehler beim Speichern des Gegenstands: \(error.localizedDescription)"
        }
    }
    
    func updateItem(name: String, value: Double, isFragile: Bool) {
        item.name = name
        item.estimatedValue = value
        item.isFragile = isFragile
        save()
    }

    func deleteItem() {
        guard let context = item.managedObjectContext else { return }
        context.delete(item)
        save()
    }
    
    // MARK: - Voice-to-Inventory Methods
    
    /// Startet die Sprachaufnahme für Inventarisierung
    func startVoiceInventory() async {
        do {
            try await voiceService.startVoiceRecording()
        } catch {
            errorMessage = "Fehler beim Starten der Sprachaufnahme: \(error.localizedDescription)"
        }
    }
    
    /// Stoppt die Sprachaufnahme
    func stopVoiceInventory() {
        voiceService.stopVoiceRecording()
    }
    
    /// Verarbeitet den erkannten Text zu Items
    func processRecognizedSpeech() async {
        guard !recognizedText.isEmpty else { return }
        
        isProcessingVoice = true
        
        do {
            let items = try await voiceService.processRecognizedText(recognizedText)
            voiceExtractedItems = items
            
            // Verarbeite Sprachbefehle
            let commands = await voiceService.processVoiceCommands(recognizedText)
            voiceCommands = commands
            
            // Führe Befehle automatisch aus
            await executeVoiceCommands(commands)
            
        } catch {
            errorMessage = "Fehler bei der Sprachverarbeitung: \(error.localizedDescription)"
        }
        
        isProcessingVoice = false
    }
    
    /// Erstellt Items aus Spracheingabe in der aktuellen Box
    func createItemsFromVoice() async {
        guard let box = item.box, !voiceExtractedItems.isEmpty else { return }
        
        isLoading = true
        
        do {
            let createdItems = try await voiceService.createItemsFromParsedData(voiceExtractedItems, in: box)
            
            // Leere die verarbeiteten Items
            voiceExtractedItems = []
            recognizedText = ""
            
        } catch {
            errorMessage = "Fehler beim Erstellen der Items: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Startet kontinuierliche Spracherkennung
    func startContinuousVoiceRecognition() async {
        do {
            try await voiceService.startContinuousRecognition()
        } catch {
            errorMessage = "Fehler bei kontinuierlicher Spracherkennung: \(error.localizedDescription)"
        }
    }
    
    /// Stoppt kontinuierliche Spracherkennung
    func stopContinuousVoiceRecognition() {
        voiceService.stopContinuousRecognition()
    }
    
    /// Verfeinert erkannte Items durch AI-Nachbearbeitung
    func refineVoiceRecognizedItems() async {
        guard !voiceExtractedItems.isEmpty else { return }
        
        isProcessingVoice = true
        
        do {
            let refinedItems = try await voiceService.refineRecognizedItems(voiceExtractedItems)
            voiceExtractedItems = refinedItems
        } catch {
            errorMessage = "Fehler bei der Verfeinerung: \(error.localizedDescription)"
        }
        
        isProcessingVoice = false
    }
    
    // MARK: - AI Item Enhancement
    
    /// Analysiert das aktuelle Item und schlägt Verbesserungen vor
    func analyzeAndEnhanceItem() async {
        isAnalyzingItem = true
        
        do {
            // Kategorisiere das Item basierend auf Name und Beschreibung
            let description = "\(item.displayName) \(item.itemDescription ?? "")"
            let suggestedCat = try await foundationService.categorizeItem(description: description)
            
            // Analysiere Text für weitere Eigenschaften
            let analysis = try await foundationService.analyzeText(description)
            
            await MainActor.run {
                self.suggestedCategory = suggestedCat
                self.suggestedProperties = ItemProperties(
                    isFragile: analysis.keywords.contains { $0.lowercased().contains("zerbrechlich") || $0.lowercased().contains("fragile") },
                    estimatedValue: self.extractValueFromKeywords(analysis.keywords),
                    tags: analysis.keywords
                )
                self.isAnalyzingItem = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler bei der Item-Analyse: \(error.localizedDescription)"
                self.isAnalyzingItem = false
            }
        }
    }
    
    /// Wendet vorgeschlagene Verbesserungen auf das Item an
    func applySuggestedEnhancements() {
        if let category = suggestedCategory {
            item.category = category.rawValue
        }
        
        if let properties = suggestedProperties {
            if properties.isFragile && !item.isFragile {
                item.isFragile = true
            }
            
            if properties.estimatedValue > item.estimatedValue {
                item.estimatedValue = properties.estimatedValue
            }
            
            // Erweitere Beschreibung mit Tags
            let newTags = properties.tags.filter { tag in
                !(item.itemDescription?.lowercased().contains(tag.lowercased()) ?? false)
            }
            
            if !newTags.isEmpty {
                let additionalInfo = newTags.joined(separator: ", ")
                if let currentDescription = item.itemDescription, !currentDescription.isEmpty {
                    item.itemDescription = "\(currentDescription). Tags: \(additionalInfo)"
                } else {
                    item.itemDescription = "Tags: \(additionalInfo)"
                }
            }
        }
        
        save()
        
        // Leere Vorschläge nach Anwendung
        suggestedCategory = nil
        suggestedProperties = nil
    }
    
    /// Lehnt vorgeschlagene Verbesserungen ab
    func dismissSuggestedEnhancements() {
        suggestedCategory = nil
        suggestedProperties = nil
    }
    
    // MARK: - Voice Command Processing
    
    private func executeVoiceCommands(_ commands: [VoiceCommand]) async {
        for command in commands {
            switch command {
            case .markAsFragile:
                item.isFragile = true
                save()
                
            case .finishRecording:
                stopVoiceInventory()
                
            case .deleteLastItem:
                if !voiceExtractedItems.isEmpty {
                    voiceExtractedItems.removeLast()
                }
                
            case .setCategory(let category):
                item.category = category.rawValue
                save()
                
            case .setPriority(let priority):
                // Setze Priorität auf Box-Ebene falls verfügbar
                if let box = item.box {
                    box.setPriority(priority)
                    try? item.managedObjectContext?.save()
                }
                
            default:
                break
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupVoiceServiceBindings() {
        // Überwache Änderungen im Voice Service
        voiceService.$isRecording
            .assign(to: &$isVoiceRecording)
        
        voiceService.$recognizedText
            .assign(to: &$recognizedText)
        
        voiceService.$extractedItems
            .assign(to: &$voiceExtractedItems)
        
        voiceService.$isProcessing
            .assign(to: &$isProcessingVoice)
        
        voiceService.$recordingLevel
            .assign(to: &$recordingLevel)
        
        voiceService.$errorMessage
            .compactMap { $0 }
            .assign(to: &$errorMessage)
    }
    
    private func extractValueFromKeywords(_ keywords: [String]) -> Double {
        for keyword in keywords {
            // Suche nach Geldbeträgen in den Keywords
            let pattern = #"(\d+(?:\.\d+)?)\s*(?:€|EUR|euro)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: keyword, range: NSRange(keyword.startIndex..., in: keyword)),
               let range = Range(match.range(at: 1), in: keyword) {
                return Double(keyword[range]) ?? 0.0
            }
        }
        return 0.0
    }
    
    /// Gibt den aktuellen Voice-Status zurück
    func getVoiceStatus() -> VoiceInventoryStatus {
        return VoiceInventoryStatus(
            isRecording: isVoiceRecording,
            isProcessing: isProcessingVoice,
            hasRecognizedText: !recognizedText.isEmpty,
            extractedItemsCount: voiceExtractedItems.count,
            recordingLevel: recordingLevel,
            pendingCommands: voiceCommands.count
        )
    }
    
    /// Gibt AI-Enhancement Status zurück
    func getEnhancementStatus() -> ItemEnhancementStatus {
        return ItemEnhancementStatus(
            hasAnalysis: suggestedCategory != nil || suggestedProperties != nil,
            isAnalyzing: isAnalyzingItem,
            suggestedCategoryName: suggestedCategory?.displayName,
            confidenceScore: calculateConfidenceScore()
        )
    }
    
    private func calculateConfidenceScore() -> Double {
        var score = 0.5 // Base score
        
        if suggestedCategory != nil {
            score += 0.3
        }
        
        if let properties = suggestedProperties, !properties.tags.isEmpty {
            score += 0.2
        }
        
        return min(1.0, score)
    }
}

// MARK: - Supporting Types

struct ItemProperties {
    let isFragile: Bool
    let estimatedValue: Double
    let tags: [String]
}

struct VoiceInventoryStatus {
    let isRecording: Bool
    let isProcessing: Bool
    let hasRecognizedText: Bool
    let extractedItemsCount: Int
    let recordingLevel: Float
    let pendingCommands: Int
    
    var statusText: String {
        if isRecording {
            return "Aufnahme läuft..."
        } else if isProcessing {
            return "Verarbeitung..."
        } else if hasRecognizedText {
            return "Text erkannt"
        } else if extractedItemsCount > 0 {
            return "\(extractedItemsCount) Items erkannt"
        } else {
            return "Bereit für Aufnahme"
        }
    }
    
    var formattedLevel: String {
        return String(format: "%.0f%%", recordingLevel * 100)
    }
}

struct ItemEnhancementStatus {
    let hasAnalysis: Bool
    let isAnalyzing: Bool
    let suggestedCategoryName: String?
    let confidenceScore: Double
    
    var statusText: String {
        if isAnalyzing {
            return "Analysiere Item..."
        } else if hasAnalysis {
            return "Verbesserungen verfügbar"
        } else {
            return "Keine Analyse verfügbar"
        }
    }
    
    var formattedConfidence: String {
        return String(format: "%.0f%% Konfidenz", confidenceScore * 100)
    }
}
