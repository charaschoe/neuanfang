//
//  SmartSearchService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData

/// Service für natürlichsprachige Suche über alle Items
@MainActor
final class SmartSearchService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []
    @Published var searchSuggestions: [String] = []
    @Published var errorMessage: String?
    @Published var lastQuery = ""
    
    // MARK: - Dependencies
    
    private let foundationService: FoundationModelsService
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Search Configuration
    
    private let maxResults = 50
    private let similarityThreshold = 0.3
    
    // MARK: - Initialization
    
    init(foundationService: FoundationModelsService = .shared,
         viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.foundationService = foundationService
        self.viewContext = viewContext
        
        loadSearchSuggestions()
    }
    
    // MARK: - Public Methods
    
    /// Führt eine intelligente Suche durch
    func performSmartSearch(query: String) async throws -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        isSearching = true
        defer { isSearching = false }
        
        lastQuery = query
        
        // Lade alle relevanten Daten
        let allItems = try fetchAllItems()
        let allBoxes = try fetchAllBoxes()
        let allRooms = try fetchAllRooms()
        
        // Führe verschiedene Suchstrategien aus
        var results: [SearchResult] = []
        
        // 1. Direkte Textsuche
        results += performDirectTextSearch(query: query, items: allItems, boxes: allBoxes, rooms: allRooms)
        
        // 2. Semantische Suche mit AI
        let semanticResults = try await performSemanticSearch(query: query, items: allItems)
        results += semanticResults
        
        // 3. Kategoriebasierte Suche
        results += performCategorySearch(query: query, items: allItems)
        
        // 4. Eigenschaften-basierte Suche
        results += performAttributeSearch(query: query, items: allItems)
        
        // Entferne Duplikate und sortiere nach Relevanz
        let uniqueResults = removeDuplicates(from: results)
        let sortedResults = sortByRelevance(uniqueResults, query: query)
        
        searchResults = Array(sortedResults.prefix(maxResults))
        
        // Aktualisiere Suchvorschläge
        updateSearchSuggestions(based: query)
        
        return searchResults
    }
    
    /// Generiert intelligente Suchvorschläge
    func generateSearchSuggestions(for partialQuery: String) async throws -> [String] {
        guard partialQuery.count >= 2 else {
            return getPopularSearchTerms()
        }
        
        let prompt = buildSuggestionPrompt(partialQuery: partialQuery)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 100)
        
        let suggestions = parseSuggestions(from: response)
        searchSuggestions = suggestions
        
        return suggestions
    }
    
    /// Führt eine Filtersuche basierend auf Kriterien durch
    func performFilteredSearch(
        query: String,
        filters: SearchFilters
    ) async throws -> [SearchResult] {
        isSearching = true
        defer { isSearching = false }
        
        let allItems = try fetchAllItems()
        let filteredItems = applyFilters(to: allItems, filters: filters)
        
        if query.isEmpty {
            // Nur Filter anwenden
            return filteredItems.map { item in
                SearchResult(
                    type: .item,
                    entity: .item(item),
                    title: item.displayName,
                    subtitle: item.box?.displayName ?? "Unbekannte Kiste",
                    description: item.itemDescription,
                    relevanceScore: 1.0,
                    location: SearchLocation(
                        room: item.box?.room?.displayName,
                        box: item.box?.displayName
                    )
                )
            }
        } else {
            // Filter + Suche kombinieren
            var results: [SearchResult] = []
            
            for item in filteredItems {
                let score = calculateRelevanceScore(item: item, query: query)
                if score > similarityThreshold {
                    results.append(SearchResult(
                        type: .item,
                        entity: .item(item),
                        title: item.displayName,
                        subtitle: item.box?.displayName ?? "Unbekannte Kiste",
                        description: item.itemDescription,
                        relevanceScore: score,
                        location: SearchLocation(
                            room: item.box?.room?.displayName,
                            box: item.box?.displayName
                        )
                    ))
                }
            }
            
            searchResults = results.sorted { $0.relevanceScore > $1.relevanceScore }
            return searchResults
        }
    }
    
    /// Führt eine erweiterte Suche mit natürlichen Sprachbefehlen durch
    func performNaturalLanguageSearch(query: String) async throws -> [SearchResult] {
        let interpretedQuery = try await interpretNaturalLanguageQuery(query)
        
        switch interpretedQuery.intent {
        case .findItems:
            return try await performSmartSearch(query: interpretedQuery.extractedTerms.joined(separator: " "))
            
        case .findByLocation:
            return try await searchByLocation(location: interpretedQuery.location)
            
        case .findByCategory:
            return try await searchByCategory(category: interpretedQuery.category)
            
        case .findByProperty:
            return try await searchByProperties(properties: interpretedQuery.properties)
            
        case .findFragile:
            return try await searchFragileItems()
            
        case .findValuable:
            return try await searchValuableItems(threshold: interpretedQuery.valueThreshold)
        }
    }
    
    // MARK: - Private Search Methods
    
    private func performDirectTextSearch(
        query: String,
        items: [Item],
        boxes: [Box],
        rooms: [Room]
    ) -> [SearchResult] {
        var results: [SearchResult] = []
        let queryLower = query.lowercased()
        
        // Suche in Items
        for item in items {
            let score = calculateTextMatchScore(text: item.displayName, query: queryLower) +
                       calculateTextMatchScore(text: item.itemDescription ?? "", query: queryLower) * 0.5
            
            if score > 0 {
                results.append(SearchResult(
                    type: .item,
                    entity: .item(item),
                    title: item.displayName,
                    subtitle: item.box?.displayName ?? "Unbekannte Kiste",
                    description: item.itemDescription,
                    relevanceScore: score,
                    location: SearchLocation(
                        room: item.box?.room?.displayName,
                        box: item.box?.displayName
                    )
                ))
            }
        }
        
        // Suche in Boxes
        for box in boxes {
            let score = calculateTextMatchScore(text: box.displayName, query: queryLower)
            
            if score > 0 {
                results.append(SearchResult(
                    type: .box,
                    entity: .box(box),
                    title: box.displayName,
                    subtitle: box.room?.displayName ?? "Unbekannter Raum",
                    description: "Kiste mit \(box.itemsArray.count) Gegenständen",
                    relevanceScore: score,
                    location: SearchLocation(
                        room: box.room?.displayName,
                        box: box.displayName
                    )
                ))
            }
        }
        
        // Suche in Rooms
        for room in rooms {
            let score = calculateTextMatchScore(text: room.displayName, query: queryLower)
            
            if score > 0 {
                results.append(SearchResult(
                    type: .room,
                    entity: .room(room),
                    title: room.displayName,
                    subtitle: "\(room.totalBoxes) Kisten, \(room.totalItems) Gegenstände",
                    description: "Raum: \(room.roomType ?? "Unbekannt")",
                    relevanceScore: score,
                    location: SearchLocation(room: room.displayName)
                ))
            }
        }
        
        return results
    }
    
    private func performSemanticSearch(query: String, items: [Item]) async throws -> [SearchResult] {
        // Erstelle Dokumente für semantische Suche
        let documents = items.map { item in
            "\(item.displayName) \(item.itemDescription ?? "") \(item.categoryDisplayName)"
        }
        
        let semanticResults = try await foundationService.performSemanticSearch(
            query: query,
            in: documents
        )
        
        var results: [SearchResult] = []
        
        for (index, semanticResult) in semanticResults.enumerated() {
            if semanticResult.score > similarityThreshold && index < items.count {
                let item = items[index]
                results.append(SearchResult(
                    type: .item,
                    entity: .item(item),
                    title: item.displayName,
                    subtitle: item.box?.displayName ?? "Unbekannte Kiste",
                    description: item.itemDescription,
                    relevanceScore: semanticResult.score,
                    location: SearchLocation(
                        room: item.box?.room?.displayName,
                        box: item.box?.displayName
                    )
                ))
            }
        }
        
        return results
    }
    
    private func performCategorySearch(query: String, items: [Item]) -> [SearchResult] {
        let queryLower = query.lowercased()
        var results: [SearchResult] = []
        
        // Suche nach Kategorienamen
        for category in ItemCategory.allCases {
            if category.displayName.lowercased().contains(queryLower) {
                let categoryItems = items.filter { $0.categoryType == category }
                
                for item in categoryItems {
                    results.append(SearchResult(
                        type: .item,
                        entity: .item(item),
                        title: item.displayName,
                        subtitle: "Kategorie: \(category.displayName)",
                        description: item.itemDescription,
                        relevanceScore: 0.8,
                        location: SearchLocation(
                            room: item.box?.room?.displayName,
                            box: item.box?.displayName
                        )
                    ))
                }
            }
        }
        
        return results
    }
    
    private func performAttributeSearch(query: String, items: [Item]) -> [SearchResult] {
        let queryLower = query.lowercased()
        var results: [SearchResult] = []
        
        // Suche nach Eigenschaften
        if queryLower.contains("zerbrechlich") || queryLower.contains("fragile") {
            let fragileItems = items.filter { $0.isFragile }
            results += fragileItems.map { item in
                SearchResult(
                    type: .item,
                    entity: .item(item),
                    title: item.displayName,
                    subtitle: "Zerbrechlicher Gegenstand",
                    description: item.itemDescription,
                    relevanceScore: 0.9,
                    location: SearchLocation(
                        room: item.box?.room?.displayName,
                        box: item.box?.displayName
                    )
                )
            }
        }
        
        if queryLower.contains("wertvoll") || queryLower.contains("teuer") {
            let valuableItems = items.filter { $0.estimatedValue > 100 }
            results += valuableItems.map { item in
                SearchResult(
                    type: .item,
                    entity: .item(item),
                    title: item.displayName,
                    subtitle: "Wertvoller Gegenstand (€\(String(format: "%.2f", item.estimatedValue)))",
                    description: item.itemDescription,
                    relevanceScore: 0.8,
                    location: SearchLocation(
                        room: item.box?.room?.displayName,
                        box: item.box?.displayName
                    )
                )
            }
        }
        
        return results
    }
    
    // MARK: - Natural Language Processing
    
    private func interpretNaturalLanguageQuery(_ query: String) async throws -> InterpretedQuery {
        let prompt = """
        Interpretiere die folgende natürlichsprachige Suchanfrage für eine Umzugs-App:
        
        Anfrage: "\(query)"
        
        Bestimme:
        1. Suchintention (findItems, findByLocation, findByCategory, findByProperty, findFragile, findValuable)
        2. Extrahierte Begriffe
        3. Ort (falls erwähnt)
        4. Kategorie (falls erwähnt)
        5. Eigenschaften (falls erwähnt)
        6. Wertschwelle (falls erwähnt)
        
        Format:
        Intent: [Intention]
        Terms: [Begriff1, Begriff2, ...]
        Location: [Ort oder leer]
        Category: [Kategorie oder leer]
        Properties: [Eigenschaft1, Eigenschaft2, ...]
        ValueThreshold: [Zahl oder 0]
        """
        
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 200)
        return parseInterpretedQuery(response)
    }
    
    private func parseInterpretedQuery(_ response: String) -> InterpretedQuery {
        var intent = SearchIntent.findItems
        var extractedTerms: [String] = []
        var location: String?
        var category: ItemCategory?
        var properties: [String] = []
        var valueThreshold = 0.0
        
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.lowercased().hasPrefix("intent:") {
                let intentString = extractValue(from: trimmedLine).lowercased()
                intent = SearchIntent.fromString(intentString)
            } else if trimmedLine.lowercased().hasPrefix("terms:") {
                let termsString = extractValue(from: trimmedLine)
                extractedTerms = termsString.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            } else if trimmedLine.lowercased().hasPrefix("location:") {
                let locationString = extractValue(from: trimmedLine)
                location = locationString.isEmpty ? nil : locationString
            } else if trimmedLine.lowercased().hasPrefix("category:") {
                let categoryString = extractValue(from: trimmedLine)
                category = ItemCategory.fromString(categoryString)
            } else if trimmedLine.lowercased().hasPrefix("properties:") {
                let propertiesString = extractValue(from: trimmedLine)
                properties = propertiesString.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            } else if trimmedLine.lowercased().hasPrefix("valuethreshold:") {
                let valueString = extractValue(from: trimmedLine)
                valueThreshold = Double(valueString) ?? 0.0
            }
        }
        
        return InterpretedQuery(
            intent: intent,
            extractedTerms: extractedTerms,
            location: location,
            category: category,
            properties: properties,
            valueThreshold: valueThreshold
        )
    }
    
    // MARK: - Helper Methods
    
    private func fetchAllItems() throws -> [Item] {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        return try viewContext.fetch(request)
    }
    
    private func fetchAllBoxes() throws -> [Box] {
        let request: NSFetchRequest<Box> = Box.fetchRequest()
        return try viewContext.fetch(request)
    }
    
    private func fetchAllRooms() throws -> [Room] {
        let request: NSFetchRequest<Room> = Room.fetchRequest()
        return try viewContext.fetch(request)
    }
    
    private func calculateTextMatchScore(text: String, query: String) -> Double {
        let textLower = text.lowercased()
        let queryLower = query.lowercased()
        
        if textLower == queryLower {
            return 1.0
        } else if textLower.contains(queryLower) {
            return 0.8
        } else if queryLower.contains(textLower) {
            return 0.6
        } else {
            // Fuzzy matching - prüfe Wort-Übereinstimmungen
            let textWords = textLower.components(separatedBy: .whitespacesAndNewlines)
            let queryWords = queryLower.components(separatedBy: .whitespacesAndNewlines)
            
            let matchingWords = textWords.filter { textWord in
                queryWords.contains { queryWord in
                    textWord.contains(queryWord) || queryWord.contains(textWord)
                }
            }
            
            if !matchingWords.isEmpty {
                return Double(matchingWords.count) / Double(max(textWords.count, queryWords.count))
            }
        }
        
        return 0.0
    }
    
    private func calculateRelevanceScore(item: Item, query: String) -> Double {
        let nameScore = calculateTextMatchScore(text: item.displayName, query: query)
        let descriptionScore = calculateTextMatchScore(text: item.itemDescription ?? "", query: query) * 0.5
        let categoryScore = calculateTextMatchScore(text: item.categoryDisplayName, query: query) * 0.3
        
        return nameScore + descriptionScore + categoryScore
    }
    
    private func removeDuplicates(from results: [SearchResult]) -> [SearchResult] {
        var uniqueResults: [SearchResult] = []
        var seenEntities: Set<String> = []
        
        for result in results {
            let identifier = result.entity.identifier
            if !seenEntities.contains(identifier) {
                seenEntities.insert(identifier)
                uniqueResults.append(result)
            }
        }
        
        return uniqueResults
    }
    
    private func sortByRelevance(_ results: [SearchResult], query: String) -> [SearchResult] {
        return results.sorted { result1, result2 in
            // Sortiere nach Relevanz-Score, dann nach Typ-Priorität
            if result1.relevanceScore != result2.relevanceScore {
                return result1.relevanceScore > result2.relevanceScore
            }
            
            return result1.type.priority < result2.type.priority
        }
    }
    
    private func applyFilters(to items: [Item], filters: SearchFilters) -> [Item] {
        return items.filter { item in
            if let category = filters.category, item.categoryType != category {
                return false
            }
            
            if let isFragile = filters.isFragile, item.isFragile != isFragile {
                return false
            }
            
            if let minValue = filters.minValue, item.estimatedValue < minValue {
                return false
            }
            
            if let maxValue = filters.maxValue, item.estimatedValue > maxValue {
                return false
            }
            
            if let roomType = filters.roomType, item.box?.room?.roomType != roomType {
                return false
            }
            
            return true
        }
    }
    
    private func buildSuggestionPrompt(partialQuery: String) -> String {
        return """
        Basierend auf der teilweisen Suchanfrage "\(partialQuery)" für eine Umzugs-App, 
        generiere 5 sinnvolle Vervollständigungen:
        
        Beispiele für Umzugsgegenstände: Bücher, Kleidung, Küchenzubehör, Elektronik, Möbel
        Beispiele für Eigenschaften: zerbrechlich, wertvoll, schwer
        Beispiele für Orte: Küche, Schlafzimmer, Wohnzimmer
        
        Gib nur die Vervollständigungen zurück, eine pro Zeile:
        """
    }
    
    private func parseSuggestions(from response: String) -> [String] {
        return response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count <= 50 }
            .prefix(5)
            .map { String($0) }
    }
    
    private func extractValue(from line: String) -> String {
        let components = line.components(separatedBy: ":")
        if components.count > 1 {
            return components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
    
    private func getPopularSearchTerms() -> [String] {
        return [
            "Bücher",
            "Kleidung", 
            "Küchenzubehör",
            "Elektronik",
            "Zerbrechliche Gegenstände",
            "Wertvolle Gegenstände",
            "Dokumente"
        ]
    }
    
    private func loadSearchSuggestions() {
        searchSuggestions = getPopularSearchTerms()
    }
    
    private func updateSearchSuggestions(based query: String) {
        // Füge erfolgreiche Suchanfragen zu Vorschlägen hinzu
        if !query.isEmpty && !searchSuggestions.contains(query) {
            searchSuggestions.insert(query, at: 0)
            searchSuggestions = Array(searchSuggestions.prefix(10))
        }
    }
    
    // MARK: - Specialized Search Methods
    
    private func searchByLocation(location: String?) async throws -> [SearchResult] {
        guard let location = location else { return [] }
        
        let rooms = try fetchAllRooms().filter { room in
            room.displayName.lowercased().contains(location.lowercased())
        }
        
        var results: [SearchResult] = []
        
        for room in rooms {
            for box in room.boxesArray {
                for item in box.itemsArray {
                    results.append(SearchResult(
                        type: .item,
                        entity: .item(item),
                        title: item.displayName,
                        subtitle: "In \(location)",
                        description: item.itemDescription,
                        relevanceScore: 0.9,
                        location: SearchLocation(
                            room: room.displayName,
                            box: box.displayName
                        )
                    ))
                }
            }
        }
        
        return results
    }
    
    private func searchByCategory(category: ItemCategory?) async throws -> [SearchResult] {
        guard let category = category else { return [] }
        
        let items = try fetchAllItems().filter { $0.categoryType == category }
        
        return items.map { item in
            SearchResult(
                type: .item,
                entity: .item(item),
                title: item.displayName,
                subtitle: "Kategorie: \(category.displayName)",
                description: item.itemDescription,
                relevanceScore: 1.0,
                location: SearchLocation(
                    room: item.box?.room?.displayName,
                    box: item.box?.displayName
                )
            )
        }
    }
    
    private func searchByProperties(properties: [String]) async throws -> [SearchResult] {
        let items = try fetchAllItems()
        var results: [SearchResult] = []
        
        for property in properties {
            let propertyLower = property.lowercased()
            
            if propertyLower.contains("zerbrechlich") {
                let fragileItems = items.filter { $0.isFragile }
                results += fragileItems.map { item in
                    SearchResult(
                        type: .item,
                        entity: .item(item),
                        title: item.displayName,
                        subtitle: "Zerbrechlich",
                        description: item.itemDescription,
                        relevanceScore: 0.9,
                        location: SearchLocation(
                            room: item.box?.room?.displayName,
                            box: item.box?.displayName
                        )
                    )
                }
            }
        }
        
        return results
    }
    
    private func searchFragileItems() async throws -> [SearchResult] {
        let items = try fetchAllItems().filter { $0.isFragile }
        
        return items.map { item in
            SearchResult(
                type: .item,
                entity: .item(item),
                title: item.displayName,
                subtitle: "Zerbrechlicher Gegenstand",
                description: item.itemDescription,
                relevanceScore: 1.0,
                location: SearchLocation(
                    room: item.box?.room?.displayName,
                    box: item.box?.displayName
                )
            )
        }
    }
    
    private func searchValuableItems(threshold: Double) async throws -> [SearchResult] {
        let minThreshold = threshold > 0 ? threshold : 100.0
        let items = try fetchAllItems().filter { $0.estimatedValue >= minThreshold }
        
        return items.map { item in
            SearchResult(
                type: .item,
                entity: .item(item),
                title: item.displayName,
                subtitle: "Wertvoll (€\(String(format: "%.2f", item.estimatedValue)))",
                description: item.itemDescription,
                relevanceScore: 1.0,
                location: SearchLocation(
                    room: item.box?.room?.displayName,
                    box: item.box?.displayName
                )
            )
        }
    }
}

// MARK: - Supporting Types

struct SearchResult: Identifiable {
    let id = UUID()
    let type: SearchResultType
    let entity: SearchEntity
    let title: String
    let subtitle: String
    let description: String?
    let relevanceScore: Double
    let location: SearchLocation?
    
    var formattedScore: String {
        return String(format: "%.1f%%", relevanceScore * 100)
    }
}

enum SearchResultType {
    case item
    case box
    case room
    
    var displayName: String {
        switch self {
        case .item: return "Gegenstand"
        case .box: return "Kiste"
        case .room: return "Raum"
        }
    }
    
    var iconName: String {
        switch self {
        case .item: return "cube"
        case .box: return "shippingbox"
        case .room: return "house"
        }
    }
    
    var priority: Int {
        switch self {
        case .item: return 1
        case .box: return 2
        case .room: return 3
        }
    }
}

enum SearchEntity {
    case item(Item)
    case box(Box)
    case room(Room)
    
    var identifier: String {
        switch self {
        case .item(let item):
            return "item_\(item.objectID)"
        case .box(let box):
            return "box_\(box.objectID)"
        case .room(let room):
            return "room_\(room.objectID)"
        }
    }
}

struct SearchLocation {
    let room: String?
    let box: String?
    
    var formattedLocation: String {
        if let room = room, let box = box {
            return "\(room) > \(box)"
        } else if let room = room {
            return room
        } else if let box = box {
            return box
        } else {
            return "Unbekannt"
        }
    }
}

struct SearchFilters {
    let category: ItemCategory?
    let isFragile: Bool?
    let minValue: Double?
    let maxValue: Double?
    let roomType: String?
    
    static let empty = SearchFilters(
        category: nil,
        isFragile: nil,
        minValue: nil,
        maxValue: nil,
        roomType: nil
    )
}

enum SearchIntent {
    case findItems
    case findByLocation
    case findByCategory
    case findByProperty
    case findFragile
    case findValuable
    
    static func fromString(_ string: String) -> SearchIntent {
        switch string.lowercased() {
        case "findbylocation": return .findByLocation
        case "findbycategory": return .findByCategory
        case "findbyproperty": return .findByProperty
        case "findfragile": return .findFragile
        case "findvaluable": return .findValuable
        default: return .findItems
        }
    }
}

struct InterpretedQuery {
    let intent: SearchIntent
    let extractedTerms: [String]
    let location: String?
    let category: ItemCategory?
    let properties: [String]
    let valueThreshold: Double
}

// MARK: - Error Types

enum SearchError: LocalizedError {
    case noQuery
    case searchFailed
    case invalidFilters
    
    var errorDescription: String? {
        switch self {
        case .noQuery:
            return "Keine Suchanfrage eingegeben"
        case .searchFailed:
            return "Suche fehlgeschlagen"
        case .invalidFilters:
            return "Ungültige Suchfilter"
        }
    }
}