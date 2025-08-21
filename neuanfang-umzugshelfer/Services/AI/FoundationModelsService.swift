//
//  FoundationModelsService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import Intelligence

/// Basis-Service für AI-Funktionalitäten mit dem Foundation Models Framework
@MainActor
final class FoundationModelsService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = FoundationModelsService()
    
    // MARK: - Published Properties
    
    @Published var isAvailable = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var intelligenceService: IntelligenceService?
    
    // MARK: - Initialization
    
    private init() {
        setupIntelligenceService()
    }
    
    // MARK: - Setup
    
    private func setupIntelligenceService() {
        do {
            intelligenceService = try IntelligenceService()
            isAvailable = true
        } catch {
            errorMessage = "Foundation Models nicht verfügbar: \(error.localizedDescription)"
            isAvailable = false
        }
    }
    
    // MARK: - Core AI Methods
    
    /// Generiert Text basierend auf einem Prompt
    func generateText(prompt: String, maxTokens: Int = 150) async throws -> String {
        guard let service = intelligenceService else {
            throw AIError.serviceUnavailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let request = TextGenerationRequest(
                prompt: prompt,
                maxTokens: maxTokens,
                temperature: 0.7
            )
            
            let response = try await service.generateText(request)
            return response.text
        } catch {
            throw AIError.generationFailed(error.localizedDescription)
        }
    }
    
    /// Analysiert Text und extrahiert Informationen
    func analyzeText(_ text: String) async throws -> TextAnalysisResult {
        guard let service = intelligenceService else {
            throw AIError.serviceUnavailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let request = TextAnalysisRequest(text: text)
            let response = try await service.analyzeText(request)
            
            return TextAnalysisResult(
                sentiment: response.sentiment,
                keywords: response.keywords,
                categories: response.categories,
                entities: response.entities
            )
        } catch {
            throw AIError.analysisFailed(error.localizedDescription)
        }
    }
    
    /// Führt Spracherkennung durch
    func recognizeSpeech(audioData: Data) async throws -> String {
        guard let service = intelligenceService else {
            throw AIError.serviceUnavailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let request = SpeechRecognitionRequest(audioData: audioData)
            let response = try await service.recognizeSpeech(request)
            return response.text
        } catch {
            throw AIError.speechRecognitionFailed(error.localizedDescription)
        }
    }
    
    /// Führt semantische Suche durch
    func performSemanticSearch(query: String, in documents: [String]) async throws -> [SemanticSearchResult] {
        guard let service = intelligenceService else {
            throw AIError.serviceUnavailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let request = SemanticSearchRequest(
                query: query,
                documents: documents,
                maxResults: 10
            )
            
            let response = try await service.performSemanticSearch(request)
            return response.results.map { result in
                SemanticSearchResult(
                    document: result.document,
                    score: result.score,
                    relevantSnippet: result.snippet
                )
            }
        } catch {
            throw AIError.searchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Umzug-spezifische AI-Methoden
    
    /// Generiert Umzug-spezifische Vorschläge
    func generateMovingAdvice(context: MovingContext) async throws -> String {
        let prompt = buildMovingAdvicePrompt(context: context)
        return try await generateText(prompt: prompt, maxTokens: 200)
    }
    
    /// Analysiert Item-Beschreibungen für Kategorisierung
    func categorizeItem(description: String) async throws -> ItemCategory {
        let prompt = """
        Analysiere die folgende Gegenstandsbeschreibung und bestimme die passende Kategorie:
        
        Beschreibung: "\(description)"
        
        Verfügbare Kategorien: electronics, clothing, books, kitchen, furniture, decoration, documents, tools, toys, sports, other
        
        Antworte nur mit der Kategorie (ein Wort):
        """
        
        let response = try await generateText(prompt: prompt, maxTokens: 20)
        return ItemCategory.fromString(response.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    // MARK: - Helper Methods
    
    private func buildMovingAdvicePrompt(context: MovingContext) -> String {
        return """
        Du bist ein Experte für Umzüge. Gib hilfreiche, praktische Tipps basierend auf dem folgenden Kontext:
        
        Raumtyp: \(context.roomType)
        Anzahl Gegenstände: \(context.itemCount)
        Zerbrechliche Gegenstände: \(context.hasFragileItems ? "Ja" : "Nein")
        Geschätzter Wert: €\(context.totalValue)
        Umzugstermin: \(context.movingDate.formatted())
        
        Gib konkrete, umsetzbare Tipps auf Deutsch:
        """
    }
    
    /// Prüft ob das Foundation Models Framework verfügbar ist
    static func checkAvailability() -> Bool {
        return IntelligenceService.isAvailable
    }
}

// MARK: - Error Types

enum AIError: LocalizedError {
    case serviceUnavailable
    case generationFailed(String)
    case analysisFailed(String)
    case speechRecognitionFailed(String)
    case searchFailed(String)
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI-Service ist nicht verfügbar"
        case .generationFailed(let message):
            return "Textgenerierung fehlgeschlagen: \(message)"
        case .analysisFailed(let message):
            return "Textanalyse fehlgeschlagen: \(message)"
        case .speechRecognitionFailed(let message):
            return "Spracherkennung fehlgeschlagen: \(message)"
        case .searchFailed(let message):
            return "Suche fehlgeschlagen: \(message)"
        case .invalidInput:
            return "Ungültige Eingabe"
        }
    }
}

// MARK: - Supporting Types

struct TextAnalysisResult {
    let sentiment: Sentiment
    let keywords: [String]
    let categories: [String]
    let entities: [String]
}

enum Sentiment {
    case positive
    case neutral
    case negative
}

struct SemanticSearchResult {
    let document: String
    let score: Double
    let relevantSnippet: String?
}

struct MovingContext {
    let roomType: String
    let itemCount: Int
    let hasFragileItems: Bool
    let totalValue: Double
    let movingDate: Date
}

// MARK: - Request/Response Types (Mock für Foundation Models)

struct TextGenerationRequest {
    let prompt: String
    let maxTokens: Int
    let temperature: Double
}

struct TextAnalysisRequest {
    let text: String
}

struct SpeechRecognitionRequest {
    let audioData: Data
}

struct SemanticSearchRequest {
    let query: String
    let documents: [String]
    let maxResults: Int
}

// MARK: - ItemCategory Extension

extension ItemCategory {
    static func fromString(_ string: String) -> ItemCategory {
        switch string.lowercased() {
        case "electronics": return .electronics
        case "clothing": return .clothing
        case "books": return .books
        case "kitchen": return .kitchen
        case "furniture": return .furniture
        case "decoration": return .decoration
        case "documents": return .documents
        case "tools": return .tools
        case "toys": return .toys
        case "sports": return .sports
        default: return .other
        }
    }
}

// MARK: - Mock Intelligence Service (da Foundation Models noch nicht vollständig verfügbar)

class IntelligenceService {
    static var isAvailable: Bool {
        // In einer echten Implementierung würde hier die Verfügbarkeit des Foundation Models Framework geprüft
        return true // Mock: immer verfügbar
    }
    
    init() throws {
        // Mock Initialisierung
    }
    
    func generateText(_ request: TextGenerationRequest) async throws -> (text: String) {
        // Mock Implementierung - in Realität würde hier das Foundation Models Framework verwendet
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 Sekunde simulierte Verarbeitung
        
        // Simulierte intelligente Antworten basierend auf dem Prompt
        if request.prompt.contains("Packvorschlag") {
            return (text: "Packen Sie zerbrechliche Gegenstände zuerst in Luftpolsterfolie ein. Verwenden Sie kleine Kisten für schwere Gegenstände.")
        } else if request.prompt.contains("Timeline") {
            return (text: "Beginnen Sie 8 Wochen vor dem Umzug mit der Planung. Kündigen Sie Verträge 4 Wochen vorher.")
        } else {
            return (text: "Hier ist ein hilfreicher Tipp für Ihren Umzug basierend auf dem bereitgestellten Kontext.")
        }
    }
    
    func analyzeText(_ request: TextAnalysisRequest) async throws -> (sentiment: Sentiment, keywords: [String], categories: [String], entities: [String]) {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 Sekunden
        
        return (
            sentiment: .neutral,
            keywords: request.text.components(separatedBy: " ").prefix(3).map { String($0) },
            categories: ["moving", "household"],
            entities: []
        )
    }
    
    func recognizeSpeech(_ request: SpeechRecognitionRequest) async throws -> (text: String) {
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 Sekunden
        return (text: "Buch, Roman, zerbrechlich") // Mock erkannter Text
    }
    
    func performSemanticSearch(_ request: SemanticSearchRequest) async throws -> (results: [(document: String, score: Double, snippet: String)]) {
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 Sekunden
        
        // Mock semantische Suche
        let results = request.documents.enumerated().map { index, document in
            (
                document: document,
                score: Double.random(in: 0.3...0.9),
                snippet: String(document.prefix(100))
            )
        }.sorted { $0.score > $1.score }
        
        return (results: Array(results.prefix(request.maxResults)))
    }
}

// MARK: - ItemCategory Definition (wenn nicht bereits vorhanden)

enum ItemCategory: String, CaseIterable {
    case electronics = "electronics"
    case clothing = "clothing"
    case books = "books"
    case kitchen = "kitchen"
    case furniture = "furniture"
    case decoration = "decoration"
    case documents = "documents"
    case tools = "tools"
    case toys = "toys"
    case sports = "sports"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .electronics: return "Elektronik"
        case .clothing: return "Kleidung"
        case .books: return "Bücher"
        case .kitchen: return "Küche"
        case .furniture: return "Möbel"
        case .decoration: return "Dekoration"
        case .documents: return "Dokumente"
        case .tools: return "Werkzeuge"
        case .toys: return "Spielzeug"
        case .sports: return "Sport"
        case .other: return "Sonstiges"
        }
    }
    
    var iconName: String {
        switch self {
        case .electronics: return "tv"
        case .clothing: return "tshirt"
        case .books: return "book"
        case .kitchen: return "fork.knife"
        case .furniture: return "bed.double"
        case .decoration: return "photo"
        case .documents: return "doc"
        case .tools: return "wrench"
        case .toys: return "gamecontroller"
        case .sports: return "sportscourt"
        case .other: return "cube.box"
        }
    }
}