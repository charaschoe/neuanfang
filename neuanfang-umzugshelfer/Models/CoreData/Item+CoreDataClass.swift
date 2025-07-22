//
//  Item+CoreDataClass.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI
import UIKit

@objc(Item)
public class Item: NSManagedObject, Identifiable {
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return name ?? "Unbekannter Gegenstand"
    }
    
    var displayDescription: String {
        return itemDescription ?? ""
    }
    
    var categoryType: ItemCategory {
        return ItemCategory(rawValue: category ?? "other") ?? .other
    }
    
    var categoryDisplayName: String {
        return categoryType.displayName
    }
    
    var categoryIcon: String {
        return categoryType.iconName
    }
    
    var categoryColor: Color {
        return categoryType.color
    }
    
    var statusIcon: String {
        if isFragile {
            return "exclamationmark.triangle.fill"
        } else if estimatedValue > 100 {
            return "dollarsign.circle.fill"
        } else {
            return categoryIcon
        }
    }
    
    var statusColor: Color {
        if isFragile {
            return .orange
        } else if estimatedValue > 100 {
            return .green
        } else {
            return categoryColor
        }
    }
    
    var hasPhoto: Bool {
        return photoData != nil && !photoData!.isEmpty
    }
    
    var photo: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }
    
    var boxName: String {
        return box?.displayName ?? "Keine Kiste"
    }
    
    var roomName: String {
        return box?.roomName ?? "Kein Raum"
    }
    
    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: estimatedValue)) ?? "€0,00"
    }
    
    var riskLevel: RiskLevel {
        if isFragile && estimatedValue > 200 {
            return .high
        } else if isFragile || estimatedValue > 100 {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Core Data Lifecycle
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        createdDate = Date()
        isFragile = false
        estimatedValue = 0.0
        
        // Set default category
        if category == nil {
            category = ItemCategory.other.rawValue
        }
    }
    
    // MARK: - Photo Management
    
    func setPhoto(_ image: UIImage) {
        // Compress image for storage
        let compressedData = compressImage(image)
        photoData = compressedData
    }
    
    func removePhoto() {
        photoData = nil
    }
    
    private func compressImage(_ image: UIImage) -> Data? {
        // Resize image to maximum dimensions while maintaining aspect ratio
        let maxDimension: CGFloat = 1024
        let scaledImage = image.scaledToFit(maxDimension: maxDimension)
        
        // Compress JPEG with quality setting
        return scaledImage.jpegData(compressionQuality: 0.8)
    }
    
    // MARK: - Category Management
    
    func setCategory(_ category: ItemCategory) {
        self.category = category.rawValue
        
        // Auto-suggest fragile status for certain categories
        if category.suggestedFragile && !isFragile {
            isFragile = true
        }
    }
    
    // MARK: - Value Management
    
    func setEstimatedValue(_ value: Double) {
        estimatedValue = max(0, value) // Ensure non-negative value
    }
    
    func setValueFromString(_ valueString: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "de_DE")
        
        if let number = formatter.number(from: valueString) {
            setEstimatedValue(number.doubleValue)
        }
    }
    
    // MARK: - Search and Filtering
    
    func matchesSearchTerm(_ searchTerm: String) -> Bool {
        let lowercaseSearch = searchTerm.lowercased()
        
        // Search in name
        if displayName.lowercased().contains(lowercaseSearch) {
            return true
        }
        
        // Search in description
        if displayDescription.lowercased().contains(lowercaseSearch) {
            return true
        }
        
        // Search in category
        if categoryDisplayName.lowercased().contains(lowercaseSearch) {
            return true
        }
        
        // Search in box name
        if boxName.lowercased().contains(lowercaseSearch) {
            return true
        }
        
        // Search in room name
        if roomName.lowercased().contains(lowercaseSearch) {
            return true
        }
        
        return false
    }
    
    // MARK: - Export and Sharing
    
    func generateShareableData() -> ItemShareData {
        return ItemShareData(
            name: displayName,
            category: categoryType,
            isFragile: isFragile,
            estimatedValue: estimatedValue
        )
    }
    
    func exportData() -> ItemExportData {
        return ItemExportData(
            name: displayName,
            description: displayDescription,
            category: categoryType.displayName,
            isFragile: isFragile,
            estimatedValue: estimatedValue,
            boxName: boxName,
            roomName: roomName,
            hasPhoto: hasPhoto,
            createdDate: createdDate ?? Date()
        )
    }
}

// MARK: - Item Category Extension

extension ItemCategory {
    var color: Color {
        switch self {
        case .electronics: return .blue
        case .books: return .brown
        case .clothing: return .purple
        case .kitchenware: return .red
        case .furniture: return .orange
        case .documents: return .gray
        case .decorations: return .pink
        case .toys: return .yellow
        case .tools: return .black
        case .artwork: return .indigo
        case .plants: return .green
        case .other: return .secondary
        }
    }
    
    var estimatedValueRange: ClosedRange<Double> {
        switch self {
        case .electronics: return 50...1000
        case .books: return 5...50
        case .clothing: return 10...200
        case .kitchenware: return 20...300
        case .furniture: return 100...2000
        case .documents: return 0...10
        case .decorations: return 10...200
        case .toys: return 5...100
        case .tools: return 20...500
        case .artwork: return 50...5000
        case .plants: return 10...100
        case .other: return 0...100
        }
    }
    
    var defaultEstimatedValue: Double {
        return estimatedValueRange.lowerBound + (estimatedValueRange.upperBound - estimatedValueRange.lowerBound) / 4
    }
}

// MARK: - Risk Level

enum RiskLevel: Int {
    case low = 1
    case medium = 2
    case high = 3
    
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "xmark.shield.fill"
        }
    }
    
    var packingRecommendation: String {
        switch self {
        case .low: return "Normal verpacken"
        case .medium: return "Vorsichtig verpacken"
        case .high: return "Extra sicher verpacken und kennzeichnen"
        }
    }
}

// MARK: - Export Data Structure

struct ItemExportData: Codable {
    let name: String
    let description: String
    let category: String
    let isFragile: Bool
    let estimatedValue: Double
    let boxName: String
    let roomName: String
    let hasPhoto: Bool
    let createdDate: Date
    
    var csvRow: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        
        return "\"\(name)\",\"\(description)\",\"\(category)\",\(isFragile ? "Ja" : "Nein"),\(estimatedValue),\"\(boxName)\",\"\(roomName)\",\(hasPhoto ? "Ja" : "Nein"),\(formatter.string(from: createdDate))"
    }
    
    static var csvHeader: String {
        return "Name,Beschreibung,Kategorie,Zerbrechlich,Geschätzter Wert,Kiste,Raum,Hat Foto,Erstellt am"
    }
}

// MARK: - UIImage Extension for Scaling

extension UIImage {
    func scaledToFit(maxDimension: CGFloat) -> UIImage {
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        
        // If image is already smaller, return original
        if scale >= 1.0 {
            return self
        }
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage ?? self
    }
}

// MARK: - Color Extensions

extension Color {
    static let brown = Color(red: 0.6, green: 0.4, blue: 0.2)
    static let darkGray = Color(red: 0.3, green: 0.3, blue: 0.3)
}