//
//  Box+CoreDataClass.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI

@objc(Box)
public class Box: NSManagedObject, Identifiable {
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return name ?? "Unbekannte Kiste"
    }
    
    var itemsArray: [Item] {
        let set = items as? Set<Item> ?? []
        return set.sorted { item1, item2 in
            // Sort by creation date, newest first
            (item1.createdDate ?? Date.distantPast) > (item2.createdDate ?? Date.distantPast)
        }
    }
    
    var totalItems: Int {
        itemsArray.count
    }
    
    var totalValue: Double {
        itemsArray.reduce(0) { total, item in
            total + item.estimatedValue
        }
    }
    
    var fragileItems: [Item] {
        itemsArray.filter { $0.isFragile }
    }
    
    var hasFragileItems: Bool {
        !fragileItems.isEmpty
    }
    
    var priorityLevel: BoxPriority {
        BoxPriority(rawValue: Int(priority)) ?? .medium
    }
    
    var statusIcon: String {
        if isPacked {
            return "checkmark.circle.fill"
        } else if hasFragileItems {
            return "exclamationmark.triangle.fill"
        } else {
            return "circle"
        }
    }
    
    var statusColor: Color {
        if isPacked {
            return .green
        } else if hasFragileItems {
            return .orange
        } else {
            return .gray
        }
    }
    
    var roomColor: Color {
        return room?.color ?? Color.blue
    }
    
    var roomName: String {
        return room?.displayName ?? "Kein Raum"
    }
    
    var qrCodeDisplayText: String {
        return qrCode ?? "Kein QR-Code"
    }
    
    var nfcTagDisplayText: String {
        return nfcTag ?? "Kein NFC-Tag"
    }
    
    var hasNFCTag: Bool {
        return nfcTag != nil && !nfcTag!.isEmpty
    }
    
    // MARK: - Core Data Lifecycle
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        createdDate = Date()
        isPacked = false
        priority = BoxPriority.medium.rawValue
        estimatedValue = 0.0
        
        // Generate unique QR code
        if qrCode == nil {
            qrCode = generateQRCode()
        }
    }
    
    // MARK: - Convenience Methods
    
    private func generateQRCode() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "BOX_\(timestamp)_\(random)"
    }
    
    func addItem(named name: String, category: ItemCategory = .other) -> Item {
        let item = Item(context: managedObjectContext!)
        item.name = name
        item.category = category.rawValue
        item.box = self
        item.createdDate = Date()
        
        // Update room progress if needed
        room?.updatePackingProgress()
        
        return item
    }
    
    func removeItem(_ item: Item) {
        removeFromItems(item)
        managedObjectContext?.delete(item)
        
        // Update room progress if needed
        room?.updatePackingProgress()
    }
    
    func togglePackedStatus() {
        isPacked.toggle()
        
        // Update room progress
        room?.updatePackingProgress()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func setPriority(_ priority: BoxPriority) {
        self.priority = Int16(priority.rawValue)
    }
    
    func assignNFCTag(_ tagIdentifier: String) {
        nfcTag = tagIdentifier
    }
    
    func removeNFCTag() {
        nfcTag = nil
    }
    
    func generateShareableData() -> BoxShareData {
        return BoxShareData(
            id: objectID.uriRepresentation().absoluteString,
            name: displayName,
            roomName: roomName,
            qrCode: qrCodeDisplayText,
            isPacked: isPacked,
            priority: priorityLevel,
            estimatedValue: estimatedValue,
            totalItems: totalItems,
            hasFragileItems: hasFragileItems,
            items: itemsArray.map { item in
                ItemShareData(
                    name: item.displayName,
                    category: item.categoryType,
                    isFragile: item.isFragile,
                    estimatedValue: item.estimatedValue
                )
            }
        )
    }
    
    // MARK: - Validation
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateBoxData()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateBoxData()
    }
    
    private func validateBoxData() throws {
        // Validate name
        guard let boxName = name else {
            throw ValidationError.missingName
        }
        
        let nameValidation = InputValidator.shared.validateName(boxName)
        guard nameValidation.isValid else {
            throw ValidationError.invalidName(nameValidation.errorMessage ?? "Invalid name")
        }
        
        // Validate estimated value if set
        if estimatedValue > 0 {
            let valueValidation = InputValidator.shared.validateValue(String(estimatedValue))
            guard valueValidation.isValid else {
                throw ValidationError.invalidValue(valueValidation.errorMessage ?? "Invalid value")
            }
        }
        
        // Sanitize and set validated name
        self.name = boxName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    enum ValidationError: Error, LocalizedError {
        case missingName
        case invalidName(String)
        case invalidValue(String)
        
        var errorDescription: String? {
            switch self {
            case .missingName:
                return NSLocalizedString("validation.box.missingName", comment: "Box name is required")
            case .invalidName(let message):
                return message
            case .invalidValue(let message):
                return message
            }
        }
    }
}

// MARK: - Box Priority

enum BoxPriority: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
    
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Normal"
        case .high: return "Hoch"
        case .urgent: return "Dringend"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .urgent: return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Shareable Data Structures

struct BoxShareData: Codable {
    let id: String
    let name: String
    let roomName: String
    let qrCode: String
    let isPacked: Bool
    let priority: BoxPriority
    let estimatedValue: Double
    let totalItems: Int
    let hasFragileItems: Bool
    let items: [ItemShareData]
    
    enum CodingKeys: String, CodingKey {
        case id, name, roomName, qrCode, isPacked, priority
        case estimatedValue, totalItems, hasFragileItems, items
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(roomName, forKey: .roomName)
        try container.encode(qrCode, forKey: .qrCode)
        try container.encode(isPacked, forKey: .isPacked)
        try container.encode(priority.rawValue, forKey: .priority)
        try container.encode(estimatedValue, forKey: .estimatedValue)
        try container.encode(totalItems, forKey: .totalItems)
        try container.encode(hasFragileItems, forKey: .hasFragileItems)
        try container.encode(items, forKey: .items)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        roomName = try container.decode(String.self, forKey: .roomName)
        qrCode = try container.decode(String.self, forKey: .qrCode)
        isPacked = try container.decode(Bool.self, forKey: .isPacked)
        let priorityValue = try container.decode(Int.self, forKey: .priority)
        priority = BoxPriority(rawValue: priorityValue) ?? .medium
        estimatedValue = try container.decode(Double.self, forKey: .estimatedValue)
        totalItems = try container.decode(Int.self, forKey: .totalItems)
        hasFragileItems = try container.decode(Bool.self, forKey: .hasFragileItems)
        items = try container.decode([ItemShareData].self, forKey: .items)
    }
    
    init(id: String, name: String, roomName: String, qrCode: String, isPacked: Bool, priority: BoxPriority, estimatedValue: Double, totalItems: Int, hasFragileItems: Bool, items: [ItemShareData]) {
        self.id = id
        self.name = name
        self.roomName = roomName
        self.qrCode = qrCode
        self.isPacked = isPacked
        self.priority = priority
        self.estimatedValue = estimatedValue
        self.totalItems = totalItems
        self.hasFragileItems = hasFragileItems
        self.items = items
    }
}

struct ItemShareData: Codable {
    let name: String
    let category: ItemCategory
    let isFragile: Bool
    let estimatedValue: Double
    
    enum CodingKeys: String, CodingKey {
        case name, category, isFragile, estimatedValue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(isFragile, forKey: .isFragile)
        try container.encode(estimatedValue, forKey: .estimatedValue)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let categoryValue = try container.decode(String.self, forKey: .category)
        category = ItemCategory(rawValue: categoryValue) ?? .other
        isFragile = try container.decode(Bool.self, forKey: .isFragile)
        estimatedValue = try container.decode(Double.self, forKey: .estimatedValue)
    }
    
    init(name: String, category: ItemCategory, isFragile: Bool, estimatedValue: Double) {
        self.name = name
        self.category = category
        self.isFragile = isFragile
        self.estimatedValue = estimatedValue
    }
}

// MARK: - Item Categories (Preview for Item class)

enum ItemCategory: String, CaseIterable {
    case electronics = "electronics"
    case books = "books"
    case clothing = "clothing"
    case kitchenware = "kitchenware"
    case furniture = "furniture"
    case documents = "documents"
    case decorations = "decorations"
    case toys = "toys"
    case tools = "tools"
    case artwork = "artwork"
    case plants = "plants"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .electronics: return "Elektronik"
        case .books: return "Bücher"
        case .clothing: return "Kleidung"
        case .kitchenware: return "Küchenware"
        case .furniture: return "Möbel"
        case .documents: return "Dokumente"
        case .decorations: return "Dekoration"
        case .toys: return "Spielzeug"
        case .tools: return "Werkzeug"
        case .artwork: return "Kunstwerke"
        case .plants: return "Pflanzen"
        case .other: return "Sonstiges"
        }
    }
    
    var iconName: String {
        switch self {
        case .electronics: return "tv.fill"
        case .books: return "book.fill"
        case .clothing: return "tshirt.fill"
        case .kitchenware: return "fork.knife"
        case .furniture: return "chair.fill"
        case .documents: return "doc.fill"
        case .decorations: return "sparkles"
        case .toys: return "gamecontroller.fill"
        case .tools: return "hammer.fill"
        case .artwork: return "paintbrush.fill"
        case .plants: return "leaf.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var suggestedFragile: Bool {
        switch self {
        case .electronics, .kitchenware, .decorations, .artwork:
            return true
        default:
            return false
        }
    }
}

// MARK: - UIKit Import for Haptics

import UIKit