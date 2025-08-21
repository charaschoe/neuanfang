//
//  AIPackingSuggestionService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData

/// Service für intelligente Packvorschläge basierend auf Item-Eigenschaften
@MainActor
final class AIPackingSuggestionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isGenerating = false
    @Published var lastSuggestions: [PackingSuggestion] = []
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let foundationService: FoundationModelsService
    
    // MARK: - Initialization
    
    init(foundationService: FoundationModelsService = .shared) {
        self.foundationService = foundationService
    }
    
    // MARK: - Public Methods
    
    /// Generiert Packvorschläge für eine Box basierend auf den enthaltenen Items
    func generatePackingSuggestions(for box: Box) async throws -> [PackingSuggestion] {
        isGenerating = true
        defer { isGenerating = false }
        
        let items = box.itemsArray
        guard !items.isEmpty else {
            throw PackingError.noItems
        }
        
        let context = PackingContext(
            roomType: box.room?.roomType ?? "unknown",
            items: items,
            boxSize: estimateBoxSize(for: items),
            totalValue: items.reduce(0) { $0 + $1.estimatedValue },
            hasFragileItems: items.contains { $0.isFragile }
        )
        
        let suggestions = try await generateSuggestions(for: context)
        lastSuggestions = suggestions
        
        return suggestions
    }
    
    /// Generiert optimale Packstrategien für mehrere Boxes
    func generateOptimalPackingStrategy(for items: [Item], targetBoxCount: Int) async throws -> PackingStrategy {
        isGenerating = true
        defer { isGenerating = false }
        
        guard !items.isEmpty else {
            throw PackingError.noItems
        }
        
        // Analysiere Items und kategorisiere sie
        let categorizedItems = categorizeItems(items)
        
        // Generiere Packstrategie
        let strategy = try await createPackingStrategy(
            categorizedItems: categorizedItems,
            targetBoxCount: targetBoxCount
        )
        
        return strategy
    }
    
    /// Analysiert potentielle Packprobleme
    func analyzePackingIssues(for box: Box) async throws -> [PackingIssue] {
        let items = box.itemsArray
        var issues: [PackingIssue] = []
        
        // Prüfe auf Kompatibilitätsprobleme
        let compatibilityIssues = try await checkItemCompatibility(items)
        issues.append(contentsOf: compatibilityIssues)
        
        // Prüfe auf Gewichtsprobleme
        if let weightIssue = checkWeightDistribution(items) {
            issues.append(weightIssue)
        }
        
        // Prüfe auf Wertsicherheit
        if let securityIssue = checkValueSecurity(items) {
            issues.append(securityIssue)
        }
        
        return issues
    }
    
    /// Schlägt optimale Box-Größe vor
    func suggestOptimalBoxSize(for items: [Item]) async throws -> BoxSizeRecommendation {
        let totalVolume = estimateTotalVolume(items)
        let hasFragileItems = items.contains { $0.isFragile }
        let heavyItemsCount = items.filter { estimateWeight($0) > 5.0 }.count
        
        let prompt = """
        Analysiere die folgenden Gegenstände und empfehle die optimale Kistengrössenbei einem geschätzten Gesamtvolumen von \(totalVolume) Liter:
        
        Anzahl Gegenstände: \(items.count)
        Zerbrechliche Gegenstände: \(hasFragileItems ? "Ja" : "Nein")
        Schwere Gegenstände (>5kg): \(heavyItemsCount)
        
        Antwortformat: {größe: "klein/mittel/groß", begründung: "..."}
        """
        
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 100)
        
        return parseBoxSizeRecommendation(response)
    }
    
    // MARK: - Private Methods
    
    private func generateSuggestions(for context: PackingContext) async throws -> [PackingSuggestion] {
        let prompt = buildPackingSuggestionPrompt(context: context)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 300)
        
        return parsePackingSuggestions(response, context: context)
    }
    
    private func buildPackingSuggestionPrompt(context: PackingContext) -> String {
        let itemDescriptions = context.items.map { item in
            "\(item.displayName) (Kategorie: \(item.categoryDisplayName), Zerbrechlich: \(item.isFragile ? "Ja" : "Nein"), Wert: €\(item.estimatedValue))"
        }.joined(separator: ", ")
        
        return """
        Du bist ein Experte für Umzugspackung. Erstelle detaillierte Packvorschläge für eine Kiste mit folgenden Eigenschaften:
        
        Raumtyp: \(context.roomType)
        Kistengrößne: \(context.boxSize.displayName)
        Gegenstände: \(itemDescriptions)
        Gesamtwert: €\(context.totalValue)
        Zerbrechliche Gegenstände: \(context.hasFragileItems ? "Ja" : "Nein")
        
        Gib konkrete, umsetzbare Packvorschläge auf Deutsch mit folgenden Kategorien:
        1. Packreihenfolge
        2. Schutzmaßnahmen
        3. Positionierung
        4. Zusätzliche Tipps
        
        Format: [Kategorie]: [Konkrete Anweisung]
        """
    }
    
    private func parsePackingSuggestions(_ response: String, context: PackingContext) -> [PackingSuggestion] {
        var suggestions: [PackingSuggestion] = []
        
        let lines = response.components(separatedBy: .newlines)
        var currentType: PackingSuggestionType = .general
        var currentText = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.lowercased().contains("packreihenfolge") {
                if !currentText.isEmpty {
                    suggestions.append(PackingSuggestion(type: currentType, text: currentText, priority: .medium))
                }
                currentType = .packingOrder
                currentText = ""
            } else if trimmedLine.lowercased().contains("schutzmaßnahmen") {
                if !currentText.isEmpty {
                    suggestions.append(PackingSuggestion(type: currentType, text: currentText, priority: .medium))
                }
                currentType = .protection
                currentText = ""
            } else if trimmedLine.lowercased().contains("positionierung") {
                if !currentText.isEmpty {
                    suggestions.append(PackingSuggestion(type: currentType, text: currentText, priority: .medium))
                }
                currentType = .positioning
                currentText = ""
            } else if trimmedLine.lowercased().contains("zusätzliche") {
                if !currentText.isEmpty {
                    suggestions.append(PackingSuggestion(type: currentType, text: currentText, priority: .medium))
                }
                currentType = .additionalTips
                currentText = ""
            } else if !trimmedLine.isEmpty {
                currentText += (currentText.isEmpty ? "" : " ") + trimmedLine
            }
        }
        
        // Füge die letzte Suggestion hinzu
        if !currentText.isEmpty {
            suggestions.append(PackingSuggestion(type: currentType, text: currentText, priority: .medium))
        }
        
        // Fallback für leere Antworten
        if suggestions.isEmpty {
            suggestions = createFallbackSuggestions(for: context)
        }
        
        return suggestions
    }
    
    private func createFallbackSuggestions(for context: PackingContext) -> [PackingSuggestion] {
        var suggestions: [PackingSuggestion] = []
        
        if context.hasFragileItems {
            suggestions.append(PackingSuggestion(
                type: .protection,
                text: "Zerbrechliche Gegenstände zuerst in Luftpolsterfolie oder Zeitungspapier einwickeln.",
                priority: .high
            ))
        }
        
        suggestions.append(PackingSuggestion(
            type: .packingOrder,
            text: "Schwere Gegenstände nach unten, leichte nach oben packen.",
            priority: .medium
        ))
        
        suggestions.append(PackingSuggestion(
            type: .positioning,
            text: "Hohlräume mit weichen Materialien ausfüllen, um Bewegung zu vermeiden.",
            priority: .medium
        ))
        
        return suggestions
    }
    
    private func categorizeItems(_ items: [Item]) -> [ItemCategory: [Item]] {
        var categorized: [ItemCategory: [Item]] = [:]
        
        for item in items {
            let category = item.categoryType
            categorized[category, default: []].append(item)
        }
        
        return categorized
    }
    
    private func createPackingStrategy(categorizedItems: [ItemCategory: [Item]], targetBoxCount: Int) async throws -> PackingStrategy {
        let prompt = """
        Erstelle eine optimale Packstrategie für \(targetBoxCount) Kisten mit folgenden Kategorien:
        
        \(categorizedItems.map { category, items in
            "\(category.displayName): \(items.count) Gegenstände"
        }.joined(separator: "\n"))
        
        Gib eine strukturierte Empfehlung für die Verteilung auf die Kisten.
        """
        
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 200)
        
        return PackingStrategy(
            totalBoxes: targetBoxCount,
            recommendations: parseStrategyRecommendations(response),
            estimatedTime: estimatePackingTime(categorizedItems)
        )
    }
    
    private func checkItemCompatibility(_ items: [Item]) async throws -> [PackingIssue] {
        var issues: [PackingIssue] = []
        
        let electronics = items.filter { $0.categoryType == .electronics }
        let liquids = items.filter { $0.itemDescription?.lowercased().contains("flüssig") == true }
        
        if !electronics.isEmpty && !liquids.isEmpty {
            issues.append(PackingIssue(
                type: .incompatibleItems,
                description: "Elektronik und Flüssigkeiten sollten nicht in derselben Kiste verpackt werden.",
                severity: .high,
                affectedItems: electronics + liquids
            ))
        }
        
        return issues
    }
    
    private func checkWeightDistribution(_ items: [Item]) -> PackingIssue? {
        let estimatedWeight = items.reduce(0.0) { total, item in
            total + estimateWeight(item)
        }
        
        if estimatedWeight > 20.0 {
            return PackingIssue(
                type: .overweight,
                description: "Die Kiste könnte zu schwer werden (geschätzt: \(String(format: "%.1f", estimatedWeight))kg). Verteilen Sie schwere Gegenstände auf mehrere Kisten.",
                severity: .medium,
                affectedItems: items.filter { estimateWeight($0) > 5.0 }
            )
        }
        
        return nil
    }
    
    private func checkValueSecurity(_ items: [Item]) -> PackingIssue? {
        let totalValue = items.reduce(0) { $0 + $1.estimatedValue }
        
        if totalValue > 1000 {
            return PackingIssue(
                type: .highValue,
                description: "Diese Kiste enthält wertvolle Gegenstände (€\(String(format: "%.2f", totalValue))). Verwenden Sie zusätzliche Sicherheitsmaßnahmen.",
                severity: .medium,
                affectedItems: items.filter { $0.estimatedValue > 100 }
            )
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func estimateBoxSize(for items: [Item]) -> BoxSize {
        let itemCount = items.count
        
        if itemCount <= 5 {
            return .small
        } else if itemCount <= 15 {
            return .medium
        } else {
            return .large
        }
    }
    
    private func estimateTotalVolume(_ items: [Item]) -> Double {
        // Vereinfachte Volumenberechnung basierend auf Kategorie
        return items.reduce(0.0) { total, item in
            total + estimateItemVolume(item)
        }
    }
    
    private func estimateItemVolume(_ item: Item) -> Double {
        switch item.categoryType {
        case .furniture: return 50.0
        case .electronics: return 10.0
        case .books: return 2.0
        case .clothing: return 5.0
        case .kitchen: return 8.0
        default: return 3.0
        }
    }
    
    private func estimateWeight(_ item: Item) -> Double {
        switch item.categoryType {
        case .furniture: return 15.0
        case .electronics: return 5.0
        case .books: return 1.0
        case .kitchen: return 3.0
        case .tools: return 2.0
        default: return 1.0
        }
    }
    
    private func parseBoxSizeRecommendation(_ response: String) -> BoxSizeRecommendation {
        // Vereinfachte Parsing-Logik
        if response.lowercased().contains("klein") {
            return BoxSizeRecommendation(size: .small, reasoning: "Empfohlen für wenige oder kleine Gegenstände")
        } else if response.lowercased().contains("groß") {
            return BoxSizeRecommendation(size: .large, reasoning: "Empfohlen für viele oder große Gegenstände")
        } else {
            return BoxSizeRecommendation(size: .medium, reasoning: "Optimale Größe für diese Gegenstandsmenge")
        }
    }
    
    private func parseStrategyRecommendations(_ response: String) -> [String] {
        return response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func estimatePackingTime(_ categorizedItems: [ItemCategory: [Item]]) -> TimeInterval {
        var totalMinutes = 0.0
        
        for (category, items) in categorizedItems {
            let timePerItem = getPackingTimePerItem(for: category)
            totalMinutes += Double(items.count) * timePerItem
        }
        
        return totalMinutes * 60 // Konvertiere zu Sekunden
    }
    
    private func getPackingTimePerItem(for category: ItemCategory) -> Double {
        switch category {
        case .electronics: return 5.0 // 5 Minuten pro elektronisches Gerät
        case .furniture: return 15.0
        case .books: return 1.0
        case .clothing: return 2.0
        case .kitchen: return 3.0
        default: return 2.0
        }
    }
}

// MARK: - Supporting Types

struct PackingSuggestion {
    let type: PackingSuggestionType
    let text: String
    let priority: Priority
    
    enum Priority {
        case low, medium, high
        
        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
}

enum PackingSuggestionType {
    case packingOrder
    case protection
    case positioning
    case additionalTips
    case general
    
    var displayName: String {
        switch self {
        case .packingOrder: return "Packreihenfolge"
        case .protection: return "Schutzmaßnahmen"
        case .positioning: return "Positionierung"
        case .additionalTips: return "Zusätzliche Tipps"
        case .general: return "Allgemein"
        }
    }
    
    var iconName: String {
        switch self {
        case .packingOrder: return "list.number"
        case .protection: return "shield.fill"
        case .positioning: return "move.3d"
        case .additionalTips: return "lightbulb.fill"
        case .general: return "info.circle.fill"
        }
    }
}

struct PackingContext {
    let roomType: String
    let items: [Item]
    let boxSize: BoxSize
    let totalValue: Double
    let hasFragileItems: Bool
}

enum BoxSize {
    case small, medium, large
    
    var displayName: String {
        switch self {
        case .small: return "Klein"
        case .medium: return "Mittel"
        case .large: return "Groß"
        }
    }
    
    var dimensions: String {
        switch self {
        case .small: return "30x20x20 cm"
        case .medium: return "40x30x30 cm"
        case .large: return "60x40x40 cm"
        }
    }
}

struct BoxSizeRecommendation {
    let size: BoxSize
    let reasoning: String
}

struct PackingStrategy {
    let totalBoxes: Int
    let recommendations: [String]
    let estimatedTime: TimeInterval
    
    var formattedTime: String {
        let hours = Int(estimatedTime) / 3600
        let minutes = (Int(estimatedTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

struct PackingIssue {
    let type: IssueType
    let description: String
    let severity: Severity
    let affectedItems: [Item]
    
    enum IssueType {
        case incompatibleItems
        case overweight
        case highValue
        case fragileRisk
        
        var iconName: String {
            switch self {
            case .incompatibleItems: return "exclamationmark.triangle.fill"
            case .overweight: return "scalemass.fill"
            case .highValue: return "dollarsign.circle.fill"
            case .fragileRisk: return "exclamationmark.shield.fill"
            }
        }
    }
    
    enum Severity {
        case low, medium, high
        
        var color: String {
            switch self {
            case .low: return "yellow"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
}

// MARK: - Error Types

enum PackingError: LocalizedError {
    case noItems
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .noItems:
            return "Keine Gegenstände zum Verpacken vorhanden"
        case .invalidConfiguration:
            return "Ungültige Konfiguration für Packvorschläge"
        }
    }
}