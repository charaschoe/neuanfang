//
//  Room+CoreDataClass.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI

@objc(Room)
public class Room: NSManagedObject, Identifiable {
    
    // MARK: - Computed Properties
    
    var iconName: String {
        switch roomType {
        case "living_room": return "sofa.fill"
        case "bedroom": return "bed.double.fill"
        case "kitchen": return "refrigerator.fill"
        case "bathroom": return "bathtub.fill"
        case "office": return "desktopcomputer"
        case "storage": return "archivebox.fill"
        case "garage": return "car.fill"
        case "garden": return "leaf.fill"
        case "basement": return "stairs"
        case "attic": return "house.lodge.fill"
        default: return "house.fill"
        }
    }
    
    var displayName: String {
        return name ?? "Unbekannter Raum"
    }
    
    var color: Color {
        Color(hex: colorHex ?? "#3B82F6")
    }
    
    var boxesArray: [Box] {
        let set = boxes as? Set<Box> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    var totalItems: Int {
        boxesArray.reduce(0) { total, box in
            total + (box.items?.count ?? 0)
        }
    }
    
    var packedBoxes: Int {
        boxesArray.filter { $0.isPacked }.count
    }
    
    var totalBoxes: Int {
        boxesArray.count
    }
    
    var progressPercentage: Float {
        guard totalBoxes > 0 else { return 0 }
        return Float(packedBoxes) / Float(totalBoxes)
    }
    
    var completionStatus: CompletionStatus {
        if totalBoxes == 0 {
            return .empty
        } else if packedBoxes == totalBoxes {
            return .completed
        } else if packedBoxes > 0 {
            return .inProgress
        } else {
            return .notStarted
        }
    }
    
    enum CompletionStatus {
        case empty
        case notStarted
        case inProgress
        case completed
        
        var description: String {
            switch self {
            case .empty: return "Leer"
            case .notStarted: return "Nicht begonnen"
            case .inProgress: return "In Arbeit"
            case .completed: return "Abgeschlossen"
            }
        }
        
        var color: Color {
            switch self {
            case .empty: return .gray
            case .notStarted: return .red
            case .inProgress: return .orange
            case .completed: return .green
            }
        }
    }
    
    // MARK: - Core Data Lifecycle
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        createdDate = Date()
        isCompleted = false
        packingProgress = 0.0
        
        if colorHex == nil {
            colorHex = RoomType.randomColor()
        }
    }
    
    // MARK: - Convenience Methods
    
    func updatePackingProgress() {
        packingProgress = progressPercentage
        
        // Auto-complete room if all boxes are packed
        isCompleted = (completionStatus == .completed)
    }
    
    func addBox(named name: String) -> Box {
        let box = Box(context: managedObjectContext!)
        box.name = name
        box.room = self
        box.qrCode = "QR_" + UUID().uuidString
        box.createdDate = Date()
        
        updatePackingProgress()
        
        return box
    }
    
    func removeBox(_ box: Box) {
        removeFromBoxes(box)
        managedObjectContext?.delete(box)
        updatePackingProgress()
    }
    
    // MARK: - Validation
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateRoomData()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateRoomData()
    }
    
    private func validateRoomData() throws {
        // Validate name
        guard let roomName = name else {
            throw ValidationError.missingName
        }
        
        let nameValidation = InputValidator.shared.validateName(roomName)
        guard nameValidation.isValid else {
            throw ValidationError.invalidName(nameValidation.errorMessage ?? "Invalid name")
        }
        
        // Sanitize and set validated name
        self.name = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    enum ValidationError: Error, LocalizedError {
        case missingName
        case invalidName(String)
        
        var errorDescription: String? {
            switch self {
            case .missingName:
                return NSLocalizedString("validation.room.missingName", comment: "Room name is required")
            case .invalidName(let message):
                return message
            }
        }
    }
}

// MARK: - Room Types

enum RoomType: String, CaseIterable {
    case livingRoom = "living_room"
    case bedroom = "bedroom"
    case kitchen = "kitchen"
    case bathroom = "bathroom"
    case office = "office"
    case storage = "storage"
    case garage = "garage"
    case garden = "garden"
    case basement = "basement"
    case attic = "attic"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .livingRoom: return "Wohnzimmer"
        case .bedroom: return "Schlafzimmer"
        case .kitchen: return "Küche"
        case .bathroom: return "Badezimmer"
        case .office: return "Büro"
        case .storage: return "Abstellraum"
        case .garage: return "Garage"
        case .garden: return "Garten"
        case .basement: return "Keller"
        case .attic: return "Dachboden"
        case .other: return "Sonstiges"
        }
    }
    
    var iconName: String {
        switch self {
        case .livingRoom: return "sofa.fill"
        case .bedroom: return "bed.double.fill"
        case .kitchen: return "refrigerator.fill"
        case .bathroom: return "bathtub.fill"
        case .office: return "desktopcomputer"
        case .storage: return "archivebox.fill"
        case .garage: return "car.fill"
        case .garden: return "leaf.fill"
        case .basement: return "stairs"
        case .attic: return "house.lodge.fill"
        case .other: return "house.fill"
        }
    }
    
    var suggestedColor: String {
        switch self {
        case .livingRoom: return "#3B82F6" // Blue
        case .bedroom: return "#8B5CF6" // Purple
        case .kitchen: return "#EF4444" // Red
        case .bathroom: return "#06B6D4" // Cyan
        case .office: return "#F59E0B" // Amber
        case .storage: return "#6B7280" // Gray
        case .garage: return "#374151" // Dark Gray
        case .garden: return "#10B981" // Green
        case .basement: return "#92400E" // Brown
        case .attic: return "#DC2626" // Dark Red
        case .other: return "#6366F1" // Indigo
        }
    }
    
    static func randomColor() -> String {
        let colors = [
            "#3B82F6", "#8B5CF6", "#EF4444", "#06B6D4",
            "#F59E0B", "#10B981", "#F97316", "#EC4899",
            "#6366F1", "#84CC16", "#F43F5E", "#14B8A6"
        ]
        return colors.randomElement() ?? "#3B82F6"
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}