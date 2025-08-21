//
//  RoomListViewModel.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
final class RoomListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var rooms: [Room] = []
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .name
    @Published var filterCriteria: FilterCriteria = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddRoom = false
    @Published var selectedRoom: Room?
    
    // AI Search Properties
    @Published var smartSearchResults: [SearchResult] = []
    @Published var isSmartSearching = false
    @Published var smartSearchSuggestions: [String] = []
    @Published var isSmartSearchEnabled = true
    
    // MARK: - Dependencies
    
    private let viewContext: NSManagedObjectContext
    private let cloudKitService: CloudKitService
    private let smartSearchService: SmartSearchService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredRooms: [Room] {
        let filtered = rooms.filter { room in
            // Search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                return room.displayName.lowercased().contains(searchLower) ||
                       room.roomType?.lowercased().contains(searchLower) == true
            }
            
            // Status filter
            switch filterCriteria {
            case .all:
                return true
            case .completed:
                return room.isCompleted
            case .inProgress:
                return room.completionStatus == .inProgress
            case .notStarted:
                return room.completionStatus == .notStarted
            case .hasBoxes:
                return room.totalBoxes > 0
            }
        }
        
        // Apply sorting
        return filtered.sorted { room1, room2 in
            switch sortOrder {
            case .name:
                return room1.displayName < room2.displayName
            case .progress:
                return room1.packingProgress > room2.packingProgress
            case .dateCreated:
                return (room1.createdDate ?? Date.distantPast) > (room2.createdDate ?? Date.distantPast)
            case .totalBoxes:
                return room1.totalBoxes > room2.totalBoxes
            case .roomType:
                return (room1.roomType ?? "") < (room2.roomType ?? "")
            }
        }
    }
    
    var overallProgress: Float {
        guard !rooms.isEmpty else { return 0 }
        let totalProgress = rooms.reduce(0) { $0 + $1.packingProgress }
        return totalProgress / Float(rooms.count)
    }
    
    var completedRoomsCount: Int {
        rooms.filter { $0.isCompleted }.count
    }
    
    var totalRoomsCount: Int {
        rooms.count
    }
    
    var totalBoxesCount: Int {
        rooms.reduce(0) { $0 + $1.totalBoxes }
    }
    
    var packedBoxesCount: Int {
        rooms.reduce(0) { $0 + $1.packedBoxes }
    }
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
         cloudKitService: CloudKitService = CloudKitService.shared,
         smartSearchService: SmartSearchService = SmartSearchService()) {
        self.viewContext = viewContext
        self.cloudKitService = cloudKitService
        self.smartSearchService = smartSearchService
        
        setupBindings()
        loadRooms()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen for search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Listen for CloudKit sync status
        cloudKitService.$syncStatus
            .sink { [weak self] status in
                if case .success = status {
                    self?.loadRooms()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadRooms() {
        isLoading = true
        errorMessage = nil
        
        let request: NSFetchRequest<Room> = Room.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Room.createdDate, ascending: false)
        ]
        
        do {
            rooms = try viewContext.fetch(request)
            isLoading = false
        } catch {
            errorMessage = "Fehler beim Laden der Räume: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Public Methods
    
    func addRoom(name: String, type: RoomType, color: String? = nil) {
        let room = Room(context: viewContext)
        room.name = name
        room.roomType = type.rawValue
        room.colorHex = color ?? type.suggestedColor
        room.createdDate = Date()
        room.isCompleted = false
        room.packingProgress = 0.0
        
        saveContext()
        loadRooms()
    }
    
    func deleteRoom(_ room: Room) {
        viewContext.delete(room)
        saveContext()
        loadRooms()
    }
    
    func updateRoom(_ room: Room) {
        room.updatePackingProgress()
        saveContext()
        loadRooms()
    }
    
    func toggleRoomCompletion(_ room: Room) {
        room.isCompleted.toggle()
        saveContext()
        loadRooms()
    }
    
    func refreshData() async {
        await cloudKitService.syncData()
        loadRooms()
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func setSortOrder(_ order: SortOrder) {
        sortOrder = order
    }
    
    func setFilterCriteria(_ criteria: FilterCriteria) {
        filterCriteria = criteria
    }
    
    // MARK: - Smart Search Methods
    
    /// Führt eine intelligente Suche durch alle Räume, Kisten und Gegenstände durch
    func performSmartSearch(query: String) async {
        guard isSmartSearchEnabled && !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            smartSearchResults = []
            return
        }
        
        isSmartSearching = true
        
        do {
            let results = try await smartSearchService.performSmartSearch(query: query)
            await MainActor.run {
                self.smartSearchResults = results
                self.isSmartSearching = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Smart Search Fehler: \(error.localizedDescription)"
                self.smartSearchResults = []
                self.isSmartSearching = false
            }
        }
    }
    
    /// Generiert intelligente Suchvorschläge
    func generateSearchSuggestions(for partialQuery: String) async {
        guard isSmartSearchEnabled && partialQuery.count >= 2 else {
            smartSearchSuggestions = []
            return
        }
        
        do {
            let suggestions = try await smartSearchService.generateSearchSuggestions(for: partialQuery)
            await MainActor.run {
                self.smartSearchSuggestions = suggestions
            }
        } catch {
            await MainActor.run {
                self.smartSearchSuggestions = []
            }
        }
    }
    
    /// Führt eine gefilterte Suche durch
    func performFilteredSmartSearch(query: String, filters: SearchFilters) async {
        guard isSmartSearchEnabled else {
            smartSearchResults = []
            return
        }
        
        isSmartSearching = true
        
        do {
            let results = try await smartSearchService.performFilteredSearch(query: query, filters: filters)
            await MainActor.run {
                self.smartSearchResults = results
                self.isSmartSearching = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Gefilterte Suche Fehler: \(error.localizedDescription)"
                self.smartSearchResults = []
                self.isSmartSearching = false
            }
        }
    }
    
    /// Führt eine natürlichsprachige Suche durch
    func performNaturalLanguageSearch(query: String) async {
        guard isSmartSearchEnabled && !query.isEmpty else {
            smartSearchResults = []
            return
        }
        
        isSmartSearching = true
        
        do {
            let results = try await smartSearchService.performNaturalLanguageSearch(query: query)
            await MainActor.run {
                self.smartSearchResults = results
                self.isSmartSearching = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Natural Language Search Fehler: \(error.localizedDescription)"
                self.smartSearchResults = []
                self.isSmartSearching = false
            }
        }
    }
    
    /// Leert die Smart Search Ergebnisse
    func clearSmartSearchResults() {
        smartSearchResults = []
        smartSearchSuggestions = []
    }
    
    /// Schaltet Smart Search ein/aus
    func toggleSmartSearch() {
        isSmartSearchEnabled.toggle()
        if !isSmartSearchEnabled {
            clearSmartSearchResults()
        }
    }
    
    /// Navigiert zu einem Suchergebnis
    func navigateToSearchResult(_ result: SearchResult) {
        switch result.entity {
        case .room(let room):
            selectedRoom = room
        case .box(let box):
            selectedRoom = box.room
        case .item(let item):
            selectedRoom = item.box?.room
        }
    }
    
    /// Gibt erweiterte Suchstatistiken zurück
    func getSearchStatistics() -> SearchStatistics {
        let totalItems = rooms.reduce(0) { $0 + $1.totalItems }
        let totalBoxes = rooms.reduce(0) { $0 + $1.totalBoxes }
        
        return SearchStatistics(
            totalRooms: rooms.count,
            totalBoxes: totalBoxes,
            totalItems: totalItems,
            searchableContent: "\(rooms.count) Räume, \(totalBoxes) Kisten, \(totalItems) Gegenstände"
        )
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Room Statistics
    
    func getStatistics() -> RoomStatistics {
        let totalRooms = rooms.count
        let completedRooms = completedRoomsCount
        let totalBoxes = totalBoxesCount
        let packedBoxes = packedBoxesCount
        let totalItems = rooms.reduce(0) { $0 + $1.totalItems }
        
        return RoomStatistics(
            totalRooms: totalRooms,
            completedRooms: completedRooms,
            totalBoxes: totalBoxes,
            packedBoxes: packedBoxes,
            totalItems: totalItems,
            overallProgress: overallProgress
        )
    }
    
    // MARK: - Export Functionality
    
    func exportData() -> [RoomExportData] {
        return rooms.map { room in
            RoomExportData(
                name: room.displayName,
                type: room.roomType ?? "unknown",
                isCompleted: room.isCompleted,
                progress: room.packingProgress,
                totalBoxes: room.totalBoxes,
                packedBoxes: room.packedBoxes,
                totalItems: room.totalItems,
                createdDate: room.createdDate ?? Date()
            )
        }
    }
}

// MARK: - Enums and Data Structures

extension RoomListViewModel {
    enum SortOrder: String, CaseIterable {
        case name = "name"
        case progress = "progress"
        case dateCreated = "dateCreated"
        case totalBoxes = "totalBoxes"
        case roomType = "roomType"
        
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .progress: return "Fortschritt"
            case .dateCreated: return "Erstellungsdatum"
            case .totalBoxes: return "Anzahl Kisten"
            case .roomType: return "Raumtyp"
            }
        }
        
        var iconName: String {
            switch self {
            case .name: return "textformat.abc"
            case .progress: return "chart.bar.fill"
            case .dateCreated: return "calendar"
            case .totalBoxes: return "shippingbox.fill"
            case .roomType: return "house.fill"
            }
        }
    }
    
    enum FilterCriteria: String, CaseIterable {
        case all = "all"
        case completed = "completed"
        case inProgress = "inProgress"
        case notStarted = "notStarted"
        case hasBoxes = "hasBoxes"
        
        var displayName: String {
            switch self {
            case .all: return "Alle"
            case .completed: return "Abgeschlossen"
            case .inProgress: return "In Arbeit"
            case .notStarted: return "Nicht begonnen"
            case .hasBoxes: return "Mit Kisten"
            }
        }
        
        var iconName: String {
            switch self {
            case .all: return "list.bullet"
            case .completed: return "checkmark.circle.fill"
            case .inProgress: return "clock.fill"
            case .notStarted: return "circle"
            case .hasBoxes: return "shippingbox.fill"
            }
        }
    }
}

// MARK: - Statistics Data Structure

struct RoomStatistics {
    let totalRooms: Int
    let completedRooms: Int
    let totalBoxes: Int
    let packedBoxes: Int
    let totalItems: Int
    let overallProgress: Float
    
    var completionPercentage: Int {
        guard totalRooms > 0 else { return 0 }
        return Int((Float(completedRooms) / Float(totalRooms)) * 100)
    }
    
    var packingPercentage: Int {
        guard totalBoxes > 0 else { return 0 }
        return Int((Float(packedBoxes) / Float(totalBoxes)) * 100)
    }
    
    var averageItemsPerRoom: Float {
        guard totalRooms > 0 else { return 0 }
        return Float(totalItems) / Float(totalRooms)
    }
    
    var averageBoxesPerRoom: Float {
        guard totalRooms > 0 else { return 0 }
        return Float(totalBoxes) / Float(totalRooms)
    }
}

// MARK: - Export Data Structure

struct RoomExportData: Codable {
    let name: String
    let type: String
    let isCompleted: Bool
    let progress: Float
    let totalBoxes: Int
    let packedBoxes: Int
    let totalItems: Int
    let createdDate: Date
    
    var csvRow: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        
        return "\"\(name)\",\"\(type)\",\(isCompleted ? "Ja" : "Nein"),\(Int(progress * 100))%,\(totalBoxes),\(packedBoxes),\(totalItems),\(formatter.string(from: createdDate))"
    }
    
    static var csvHeader: String {
        return "Name,Typ,Abgeschlossen,Fortschritt,Gesamt Kisten,Gepackte Kisten,Gesamt Gegenstände,Erstellt am"
    }
}

// MARK: - Search Statistics

struct SearchStatistics {
    let totalRooms: Int
    let totalBoxes: Int
    let totalItems: Int
    let searchableContent: String
    
    var formattedStatistics: String {
        return "Durchsuchbar: \(searchableContent)"
    }
}