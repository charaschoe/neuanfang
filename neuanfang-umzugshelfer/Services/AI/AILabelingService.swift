//
//  AILabelingService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData

/// Service für intelligente Box-Beschriftung basierend auf Inhalten
@MainActor
final class AILabelingService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isGenerating = false
    @Published var suggestedLabels: [BoxLabel] = []
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let foundationService: FoundationModelsService
    
    // MARK: - Initialization
    
    init(foundationService: FoundationModelsService = .shared) {
        self.foundationService = foundationService
    }
    
    // MARK: - Public Methods
    
    /// Generiert intelligente Beschriftungen für eine Box basierend auf Inhalten
    func generateSmartLabel(for box: Box) async throws -> BoxLabel {
        isGenerating = true
        defer { isGenerating = false }
        
        let items = box.itemsArray
        guard !items.isEmpty else {
            throw LabelingError.noItems
        }
        
        let context = LabelingContext(
            roomType: box.room?.roomType ?? "unknown",
            roomName: box.room?.displayName ?? "Unbekannt",
            items: items,
            boxName: box.displayName,
            priority: box.priorityLevel
        )
        
        let label = try await createSmartLabel(for: context)
        
        return label
    }
    
    /// Generiert mehrere Beschriftungsoptionen zur Auswahl
    func generateLabelOptions(for box: Box, count: Int = 3) async throws -> [BoxLabel] {
        isGenerating = true
        defer { isGenerating = false }
        
        let items = box.itemsArray
        guard !items.isEmpty else {
            throw LabelingError.noItems
        }
        
        var labels: [BoxLabel] = []
        
        // Generiere verschiedene Beschriftungsstile
        let styles: [LabelingStyle] = [.descriptive, .categorical, .priority]
        
        for style in styles.prefix(count) {
            let context = LabelingContext(
                roomType: box.room?.roomType ?? "unknown",
                roomName: box.room?.displayName ?? "Unbekannt",
                items: items,
                boxName: box.displayName,
                priority: box.priorityLevel
            )
            
            let label = try await createLabelWithStyle(for: context, style: style)
            labels.append(label)
        }
        
        suggestedLabels = labels
        return labels
    }
    
    /// Analysiert Box-Inhalte und schlägt Verbesserungen vor
    func analyzeLabelingStrategy(for boxes: [Box]) async throws -> LabelingStrategy {
        let prompt = buildLabelingStrategyPrompt(boxes: boxes)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 300)
        
        return parseLabelingStrategy(response)
    }
    
    /// Generiert QR-Code Inhalte mit AI-optimierten Informationen
    func generateQRCodeContent(for box: Box) async throws -> QRCodeContent {
        let items = box.itemsArray
        let essentialItems = selectEssentialItems(from: items)
        
        let prompt = """
        Erstelle einen kompakten QR-Code Inhalt für eine Umzugskiste:
        
        Kiste: \(box.displayName)
        Raum: \(box.room?.displayName ?? "Unbekannt")
        Wichtigste Gegenstände: \(essentialItems.map { $0.displayName }.joined(separator: ", "))
        Priorität: \(box.priorityLevel.displayName)
        
        Erstelle eine strukturierte, kompakte Beschreibung (max. 200 Zeichen):
        """
        
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 100)
        
        return QRCodeContent(
            boxId: box.qrCode ?? "",
            shortDescription: response.trimmingCharacters(in: .whitespacesAndNewlines),
            roomName: box.room?.displayName ?? "Unbekannt",
            priority: box.priorityLevel,
            itemCount: items.count,
            hasFragileItems: items.contains { $0.isFragile }
        )
    }
    
    /// Erstellt Beschriftungen für Notfälle (schneller Zugriff)
    func generateEmergencyLabels(for boxes: [Box]) async throws -> [EmergencyLabel] {
        var emergencyLabels: [EmergencyLabel] = []
        
        for box in boxes {
            let items = box.itemsArray
            let emergencyItems = items.filter { isEmergencyItem($0) }
            
            if !emergencyItems.isEmpty {
                let label = EmergencyLabel(
                    boxId: box.qrCode ?? "",
                    urgencyLevel: calculateUrgencyLevel(for: emergencyItems),
                    emergencyItems: emergencyItems.map { $0.displayName },
                    accessInstructions: generateAccessInstructions(for: box)
                )
                emergencyLabels.append(label)
            }
        }
        
        return emergencyLabels
    }
    
    // MARK: - Private Methods
    
    private func createSmartLabel(for context: LabelingContext) async throws -> BoxLabel {
        let prompt = buildSmartLabelPrompt(context: context)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 150)
        
        return parseBoxLabel(response, context: context)
    }
    
    private func createLabelWithStyle(for context: LabelingContext, style: LabelingStyle) async throws -> BoxLabel {
        let prompt = buildStyledLabelPrompt(context: context, style: style)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 120)
        
        return parseBoxLabel(response, context: context, style: style)
    }
    
    private func buildSmartLabelPrompt(context: LabelingContext) -> String {
        let itemCategories = Dictionary(grouping: context.items) { $0.categoryType }
        let categoryDescriptions = itemCategories.map { category, items in
            "\(category.displayName): \(items.count)"
        }.joined(separator: ", ")
        
        return """
        Erstelle eine präzise, informative Beschriftung für eine Umzugskiste:
        
        Raum: \(context.roomName) (\(context.roomType))
        Gegenstände nach Kategorie: \(categoryDescriptions)
        Gesamtanzahl: \(context.items.count)
        Priorität: \(context.priority.displayName)
        Zerbrechlich: \(context.items.contains { $0.isFragile } ? "Ja" : "Nein")
        
        Erstelle eine klare, prägnante Beschriftung (max. 50 Zeichen):
        """
    }
    
    private func buildStyledLabelPrompt(context: LabelingContext, style: LabelingStyle) -> String {
        let baseInfo = """
        Raum: \(context.roomName)
        Gegenstände: \(context.items.count)
        Priorität: \(context.priority.displayName)
        """
        
        switch style {
        case .descriptive:
            let topItems = context.items.prefix(3).map { $0.displayName }.joined(separator: ", ")
            return """
            \(baseInfo)
            Hauptgegenstände: \(topItems)
            
            Erstelle eine beschreibende Beschriftung, die die wichtigsten Inhalte nennt:
            """
            
        case .categorical:
            let mainCategory = Dictionary(grouping: context.items) { $0.categoryType }
                .max(by: { $0.value.count < $1.value.count })?.key
            return """
            \(baseInfo)
            Hauptkategorie: \(mainCategory?.displayName ?? "Gemischt")
            
            Erstelle eine kategoriebasierte Beschriftung:
            """
            
        case .priority:
            return """
            \(baseInfo)
            Zerbrechlich: \(context.items.contains { $0.isFragile } ? "Ja" : "Nein")
            
            Erstelle eine prioritäts- und sicherheitsfokussierte Beschriftung:
            """
            
        case .functional:
            return """
            \(baseInfo)
            
            Erstelle eine funktionale Beschriftung, die den Verwendungszweck betont:
            """
        }
    }
    
    private func buildLabelingStrategyPrompt(boxes: [Box]) -> String {
        let totalBoxes = boxes.count
        let roomDistribution = Dictionary(grouping: boxes) { $0.room?.roomType ?? "unknown" }
        let distributionText = roomDistribution.map { room, boxes in
            "\(room): \(boxes.count) Kisten"
        }.joined(separator: ", ")
        
        return """
        Analysiere die Beschriftungsstrategie für einen Umzug:
        
        Gesamtanzahl Kisten: \(totalBoxes)
        Verteilung nach Räumen: \(distributionText)
        
        Gib Empfehlungen für:
        1. Farbkodierung nach Räumen
        2. Prioritätskennzeichnung
        3. Nummerierungssystem
        4. Spezielle Markierungen (zerbrechlich, schwer, etc.)
        
        Format: [Aspekt]: [Empfehlung]
        """
    }
    
    private func parseBoxLabel(_ response: String, context: LabelingContext, style: LabelingStyle? = nil) -> BoxLabel {
        let cleanText = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extrahiere verschiedene Komponenten des Labels
        let mainText = extractMainText(from: cleanText)
        let colorCode = suggestColorCode(for: context)
        let iconSuggestion = suggestIcon(for: context)
        
        return BoxLabel(
            mainText: mainText,
            subText: context.roomName,
            colorCode: colorCode,
            iconName: iconSuggestion,
            style: style ?? .descriptive,
            priority: context.priority,
            hasSpecialHandling: context.items.contains { $0.isFragile },
            itemCount: context.items.count
        )
    }
    
    private func parseLabelingStrategy(_ response: String) -> LabelingStrategy {
        var recommendations: [String: String] = [:]
        
        let lines = response.components(separatedBy: .newlines)
        for line in lines {
            if line.contains(":") {
                let components = line.components(separatedBy: ":")
                if components.count >= 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    recommendations[key] = value
                }
            }
        }
        
        return LabelingStrategy(
            colorCoding: recommendations["Farbkodierung"] ?? "Nach Räumen färben",
            prioritySystem: recommendations["Prioritätskennzeichnung"] ?? "Sterne für Priorität verwenden",
            numberingSystem: recommendations["Nummerierungssystem"] ?? "Raum-Nummer Format",
            specialMarkings: recommendations["Spezielle Markierungen"] ?? "Aufkleber für besondere Behandlung"
        )
    }
    
    private func extractMainText(from response: String) -> String {
        // Entferne Anführungszeichen und kürze auf 50 Zeichen
        let cleaned = response.replacingOccurrences(of: "\"", with: "")
        return String(cleaned.prefix(50))
    }
    
    private func suggestColorCode(for context: LabelingContext) -> String {
        switch context.roomType.lowercased() {
        case "kitchen", "küche": return "#FF6B6B" // Rot
        case "living_room", "wohnzimmer": return "#4ECDC4" // Türkis
        case "bedroom", "schlafzimmer": return "#45B7D1" // Blau
        case "bathroom", "badezimmer": return "#96CEB4" // Grün
        case "office", "büro": return "#FECA57" // Gelb
        case "storage", "abstellraum": return "#95A5A6" // Grau
        default: return "#BB8FCE" // Lila
        }
    }
    
    private func suggestIcon(for context: LabelingContext) -> String {
        if context.items.contains(where: { $0.isFragile }) {
            return "exclamationmark.triangle.fill"
        }
        
        let mainCategory = Dictionary(grouping: context.items) { $0.categoryType }
            .max(by: { $0.value.count < $1.value.count })?.key
        
        return mainCategory?.iconName ?? "shippingbox.fill"
    }
    
    private func selectEssentialItems(from items: [Item]) -> [Item] {
        // Priorisiere wertvolle und zerbrechliche Gegenstände
        return items.sorted { item1, item2 in
            if item1.isFragile && !item2.isFragile { return true }
            if !item1.isFragile && item2.isFragile { return false }
            return item1.estimatedValue > item2.estimatedValue
        }.prefix(5).map { $0 }
    }
    
    private func isEmergencyItem(_ item: Item) -> Bool {
        let emergencyKeywords = ["medikament", "medizin", "erste hilfe", "schlüssel", "dokument", "ausweis", "pass"]
        let itemName = item.displayName.lowercased()
        let itemDescription = item.itemDescription?.lowercased() ?? ""
        
        return emergencyKeywords.contains { keyword in
            itemName.contains(keyword) || itemDescription.contains(keyword)
        }
    }
    
    private func calculateUrgencyLevel(for items: [Item]) -> EmergencyLabel.UrgencyLevel {
        let hasDocuments = items.contains { item in
            let name = item.displayName.lowercased()
            return name.contains("dokument") || name.contains("ausweis") || name.contains("pass")
        }
        
        let hasMedicine = items.contains { item in
            let name = item.displayName.lowercased()
            return name.contains("medikament") || name.contains("medizin")
        }
        
        if hasDocuments || hasMedicine {
            return .critical
        } else {
            return .medium
        }
    }
    
    private func generateAccessInstructions(for box: Box) -> String {
        if box.priorityLevel == .high {
            return "Sofortiger Zugriff erforderlich - an leicht erreichbarer Stelle lagern"
        } else if box.itemsArray.contains(where: { $0.isFragile }) {
            return "Vorsichtig handhaben - zerbrechliche Gegenstände"
        } else {
            return "Normale Behandlung"
        }
    }
}

// MARK: - Supporting Types

struct BoxLabel {
    let mainText: String
    let subText: String
    let colorCode: String
    let iconName: String
    let style: LabelingStyle
    let priority: BoxPriority
    let hasSpecialHandling: Bool
    let itemCount: Int
    
    var displayText: String {
        return "\(mainText) (\(itemCount) Gegenstände)"
    }
    
    var needsSpecialAttention: Bool {
        return hasSpecialHandling || priority == .high
    }
}

enum LabelingStyle {
    case descriptive
    case categorical
    case priority
    case functional
    
    var displayName: String {
        switch self {
        case .descriptive: return "Beschreibend"
        case .categorical: return "Kategoriebasiert"
        case .priority: return "Prioritätsbasiert"
        case .functional: return "Funktional"
        }
    }
    
    var description: String {
        switch self {
        case .descriptive: return "Beschreibt die wichtigsten Inhalte"
        case .categorical: return "Gruppiert nach Gegenstandskategorien"
        case .priority: return "Fokus auf Priorität und Sicherheit"
        case .functional: return "Betont den Verwendungszweck"
        }
    }
}

struct LabelingContext {
    let roomType: String
    let roomName: String
    let items: [Item]
    let boxName: String
    let priority: BoxPriority
}

struct LabelingStrategy {
    let colorCoding: String
    let prioritySystem: String
    let numberingSystem: String
    let specialMarkings: String
    
    var recommendations: [String] {
        return [colorCoding, prioritySystem, numberingSystem, specialMarkings]
    }
}

struct QRCodeContent {
    let boxId: String
    let shortDescription: String
    let roomName: String
    let priority: BoxPriority
    let itemCount: Int
    let hasFragileItems: Bool
    
    var formattedContent: String {
        var content = "\(boxId): \(shortDescription)"
        if hasFragileItems {
            content += " ⚠️"
        }
        if priority == .high {
            content += " 🔴"
        }
        return content
    }
}

struct EmergencyLabel {
    let boxId: String
    let urgencyLevel: UrgencyLevel
    let emergencyItems: [String]
    let accessInstructions: String
    
    enum UrgencyLevel {
        case low, medium, critical
        
        var displayName: String {
            switch self {
            case .low: return "Niedrige Dringlichkeit"
            case .medium: return "Mittlere Dringlichkeit"
            case .critical: return "Kritisch"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .critical: return "red"
            }
        }
        
        var iconName: String {
            switch self {
            case .low: return "info.circle"
            case .medium: return "exclamationmark.triangle"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
}

// MARK: - BoxPriority Extension

extension BoxPriority {
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        }
    }
}

// MARK: - BoxPriority enum (falls nicht bereits definiert)

enum BoxPriority: Int16, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    
    var iconName: String {
        switch self {
        case .low: return "1.circle"
        case .medium: return "2.circle"
        case .high: return "3.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Error Types

enum LabelingError: LocalizedError {
    case noItems
    case invalidContext
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .noItems:
            return "Keine Gegenstände zum Beschriften vorhanden"
        case .invalidContext:
            return "Ungültiger Kontext für Beschriftung"
        case .generationFailed:
            return "Beschriftung konnte nicht generiert werden"
        }
    }
}