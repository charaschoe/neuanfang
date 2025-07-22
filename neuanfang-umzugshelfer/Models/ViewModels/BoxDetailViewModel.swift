//
//  BoxDetailViewModel.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI
import Combine
import UIKit

@MainActor
final class BoxDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var items: [Item] = []
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .dateCreated
    @Published var filterCriteria: FilterCriteria = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddItem = false
    @Published var showingQRCode = false
    @Published var showingNFCWriter = false
    @Published var showingEditBox = false
    @Published var selectedItem: Item?
    
    // Box editing properties
    @Published var boxName = ""
    @Published var boxPriority: BoxPriority = .medium
    @Published var boxEstimatedValue: Double = 0.0
    @Published var boxNotes = ""
    
    // MARK: - Dependencies
    
    private let viewContext: NSManagedObjectContext
    private let qrCodeService: QRCodeService
    private let nfcService: NFCService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Properties
    
    var box: Box? {
        didSet {
            if let box = box {
                loadBoxData(box)
                loadItems(for: box)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var filteredItems: [Item] {
        let filtered = items.filter { item in
            // Search filter
            if !searchText.isEmpty {
                return item.matchesSearchTerm(searchText)
            }
            
            // Category filter
            switch filterCriteria {
            case .all:
                return true
            case .fragile:
                return item.isFragile
            case .valuable:
                return item.estimatedValue > 100
            case .category(let category):
                return item.categoryType == category
            }
        }
        
        // Apply sorting
        return filtered.sorted { item1, item2 in
            switch sortOrder {
            case .name:
                return item1.displayName < item2.displayName
            case .dateCreated:
                return (item1.createdDate ?? Date.distantPast) > (item2.createdDate ?? Date.distantPast)
            case .value:
                return item1.estimatedValue > item2.estimatedValue
            case .category:
                return item1.categoryDisplayName < item2.categoryDisplayName
            case .riskLevel:
                return item1.riskLevel.rawValue > item2.riskLevel.rawValue
            }
        }
    }
    
    var totalValue: Double {
        items.reduce(0) { $0 + $1.estimatedValue }
    }
    
    var fragileItemsCount: Int {
        items.filter { $0.isFragile }.count
    }
    
    var highValueItemsCount: Int {
        items.filter { $0.estimatedValue > 100 }.count
    }
    
    var categoryCounts: [ItemCategory: Int] {
        var counts: [ItemCategory: Int] = [:]
        for item in items {
            counts[item.categoryType, default: 0] += 1
        }
        return counts
    }
    
    var riskLevel: RiskLevel {
        let highRiskItems = items.filter { $0.riskLevel == .high }.count
        let mediumRiskItems = items.filter { $0.riskLevel == .medium }.count
        
        if highRiskItems > 0 {
            return .high
        } else if mediumRiskItems > 0 {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
         qrCodeService: QRCodeService = QRCodeService(),
         nfcService: NFCService = NFCService()) {
        self.viewContext = viewContext
        self.qrCodeService = qrCodeService
        self.nfcService = nfcService
        
        setupBindings()
    }
    
    convenience init(box: Box,
                    viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.init(viewContext: viewContext)
        self.box = box
        loadBoxData(box)
        loadItems(for: box)
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
    }
    
    private func loadBoxData(_ box: Box) {
        boxName = box.displayName
        boxPriority = box.priorityLevel
        boxEstimatedValue = box.estimatedValue
        boxNotes = "" // Add notes field to Box model if needed
    }
    
    private func loadItems(for box: Box) {
        isLoading = true
        errorMessage = nil
        
        items = box.itemsArray
        isLoading = false
    }
    
    // MARK: - Box Management
    
    func updateBoxDetails() {
        guard let box = box else { return }
        
        box.name = boxName
        box.setPriority(boxPriority)
        box.estimatedValue = boxEstimatedValue
        
        saveContext()
    }
    
    func toggleBoxPackedStatus() {
        guard let box = box else { return }
        box.togglePackedStatus()
        saveContext()
    }
    
    func updateBoxPriority(_ priority: BoxPriority) {
        boxPriority = priority
        box?.setPriority(priority)
        saveContext()
    }
    
    // MARK: - Item Management
    
    func addItem(name: String, category: ItemCategory = .other, isFragile: Bool = false, estimatedValue: Double = 0) {
        guard let box = box else { return }
        
        let item = box.addItem(named: name, category: category)
        item.isFragile = isFragile
        item.estimatedValue = estimatedValue
        
        saveContext()
        loadItems(for: box)
    }
    
    func deleteItem(_ item: Item) {
        guard let box = box else { return }
        
        box.removeItem(item)
        saveContext()
        loadItems(for: box)
    }
    
    func updateItem(_ item: Item) {
        saveContext()
        loadItems(for: box!)
    }
    
    func setItemPhoto(_ item: Item, image: UIImage) {
        item.setPhoto(image)
        saveContext()
    }
    
    func removeItemPhoto(_ item: Item) {
        item.removePhoto()
        saveContext()
    }
    
    // MARK: - QR Code Management
    
    func generateQRCode() -> UIImage? {
        guard let box = box else { return nil }
        return qrCodeService.generateQRCode(for: box)
    }
    
    func getQRCodeData() -> BoxShareData? {
        return box?.generateShareableData()
    }
    
    // MARK: - NFC Management
    
    func writeNFCTag() {
        guard let box = box,
              let shareData = box.generateShareableData() else { return }
        
        nfcService.writeNFCTag(with: shareData)
    }
    
    func assignNFCTag(_ tagIdentifier: String) {
        box?.assignNFCTag(tagIdentifier)
        saveContext()
    }
    
    func removeNFCTag() {
        box?.removeNFCTag()
        saveContext()
    }
    
    // MARK: - Sharing and Export
    
    func shareBox() {
        guard let box = box else { return }
        
        let shareData = box.generateShareableData()
        
        // Create shareable content
        let activityViewController = UIActivityViewController(
            activityItems: [createShareText(from: shareData)],
            applicationActivities: nil
        )
        
        // Present activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
    
    private func createShareText(from shareData: BoxShareData) -> String {
        var text = """
        📦 Kiste: \(shareData.name)
        🏠 Raum: \(shareData.roomName)
        📊 Status: \(shareData.isPacked ? "Gepackt ✅" : "Nicht gepackt ⏳")
        🔢 QR-Code: \(shareData.qrCode)
        💰 Geschätzter Wert: €\(String(format: "%.2f", shareData.estimatedValue))
        📋 Gegenstände: \(shareData.totalItems)
        """
        
        if shareData.hasFragileItems {
            text += "\n⚠️ Enthält zerbrechliche Gegenstände"
        }
        
        text += "\n\nGegenstände:\n"
        for item in shareData.items {
            text += "• \(item.name)"
            if item.isFragile {
                text += " ⚠️"
            }
            text += "\n"
        }
        
        text += "\n📱 Erstellt mit neuanfang: Umzugshelfer"
        
        return text
    }
    
    func exportItemsAsCSV() -> String {
        var csvContent = ItemExportData.csvHeader + "\n"
        
        for item in items {
            let exportData = item.exportData()
            csvContent += exportData.csvRow + "\n"
        }
        
        return csvContent
    }
    
    // MARK: - Search and Filtering
    
    func clearSearch() {
        searchText = ""
    }
    
    func setSortOrder(_ order: SortOrder) {
        sortOrder = order
    }
    
    func setFilterCriteria(_ criteria: FilterCriteria) {
        filterCriteria = criteria
    }
    
    func getItemsByCategory() -> [ItemCategory: [Item]] {
        var itemsByCategory: [ItemCategory: [Item]] = [:]
        
        for item in items {
            let category = item.categoryType
            itemsByCategory[category, default: []].append(item)
        }
        
        return itemsByCategory
    }
    
    // MARK: - Statistics
    
    func getBoxStatistics() -> BoxStatistics {
        return BoxStatistics(
            totalItems: items.count,
            fragileItems: fragileItemsCount,
            highValueItems: highValueItemsCount,
            totalValue: totalValue,
            averageItemValue: items.isEmpty ? 0 : totalValue / Double(items.count),
            riskLevel: riskLevel,
            categoryCounts: categoryCounts
        )
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
}

// MARK: - Enums and Data Structures

extension BoxDetailViewModel {
    enum SortOrder: String, CaseIterable {
        case name = "name"
        case dateCreated = "dateCreated"
        case value = "value"
        case category = "category"
        case riskLevel = "riskLevel"
        
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .dateCreated: return "Erstellungsdatum"
            case .value: return "Wert"
            case .category: return "Kategorie"
            case .riskLevel: return "Risikostufe"
            }
        }
        
        var iconName: String {
            switch self {
            case .name: return "textformat.abc"
            case .dateCreated: return "calendar"
            case .value: return "dollarsign.circle"
            case .category: return "folder"
            case .riskLevel: return "exclamationmark.triangle"
            }
        }
    }
    
    enum FilterCriteria: Equatable {
        case all
        case fragile
        case valuable
        case category(ItemCategory)
        
        var displayName: String {
            switch self {
            case .all: return "Alle"
            case .fragile: return "Zerbrechlich"
            case .valuable: return "Wertvoll"
            case .category(let category): return category.displayName
            }
        }
        
        var iconName: String {
            switch self {
            case .all: return "list.bullet"
            case .fragile: return "exclamationmark.triangle.fill"
            case .valuable: return "dollarsign.circle.fill"
            case .category(let category): return category.iconName
            }
        }
    }
}

// MARK: - Statistics Data Structure

struct BoxStatistics {
    let totalItems: Int
    let fragileItems: Int
    let highValueItems: Int
    let totalValue: Double
    let averageItemValue: Double
    let riskLevel: RiskLevel
    let categoryCounts: [ItemCategory: Int]
    
    var fragilePercentage: Int {
        guard totalItems > 0 else { return 0 }
        return Int((Double(fragileItems) / Double(totalItems)) * 100)
    }
    
    var highValuePercentage: Int {
        guard totalItems > 0 else { return 0 }
        return Int((Double(highValueItems) / Double(totalItems)) * 100)
    }
    
    var mostCommonCategory: ItemCategory? {
        return categoryCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var categoryDiversity: Int {
        return categoryCounts.count
    }
}

// MARK: - QR Code Service Protocol

protocol QRCodeServiceProtocol {
    func generateQRCode(for box: Box) -> UIImage?
}

// MARK: - NFC Service Protocol

protocol NFCServiceProtocol {
    func writeNFCTag(with data: BoxShareData)
    var isWriting: Bool { get }
    var message: String { get }
}