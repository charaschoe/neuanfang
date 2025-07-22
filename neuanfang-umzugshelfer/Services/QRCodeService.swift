//
//  QRCodeService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreImage
import UIKit
import SwiftUI

class QRCodeService: ObservableObject, QRCodeServiceProtocol {
    
    // MARK: - Published Properties
    
    @Published var isGenerating = false
    @Published var lastGeneratedQR: UIImage?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let context = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()
    
    // MARK: - QR Code Generation
    
    func generateQRCode(for box: Box) -> UIImage? {
        isGenerating = true
        errorMessage = nil
        
        defer { isGenerating = false }
        
        // Create box data for QR code
        let boxData = BoxQRData(
            id: box.objectID.uriRepresentation().absoluteString,
            name: box.displayName,
            roomName: box.roomName,
            qrCode: box.qrCodeDisplayText,
            isPacked: box.isPacked,
            priority: box.priorityLevel.rawValue,
            estimatedValue: box.estimatedValue,
            totalItems: box.totalItems,
            hasFragileItems: box.hasFragileItems,
            items: box.itemsArray.map { item in
                ItemQRData(
                    name: item.displayName,
                    category: item.category ?? "other",
                    isFragile: item.isFragile,
                    estimatedValue: item.estimatedValue
                )
            },
            createdDate: box.createdDate ?? Date(),
            lastModified: Date()
        )
        
        // Convert to JSON
        guard let jsonData = try? JSONEncoder().encode(boxData),
              let qrString = String(data: jsonData, encoding: .utf8) else {
            errorMessage = "Fehler beim Erstellen der QR-Code Daten"
            return nil
        }
        
        // Generate QR code image
        let qrImage = generateQRImage(from: qrString)
        lastGeneratedQR = qrImage
        
        return qrImage
    }
    
    func generateSimpleQRCode(for box: Box) -> UIImage? {
        // Generate a simpler QR code with just essential info
        let simpleData = SimpleBoxQRData(
            id: box.objectID.uriRepresentation().absoluteString,
            name: box.displayName,
            roomName: box.roomName,
            qrCode: box.qrCodeDisplayText
        )
        
        guard let jsonData = try? JSONEncoder().encode(simpleData),
              let qrString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return generateQRImage(from: qrString)
    }
    
    private func generateQRImage(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        qrFilter.message = data
        
        // Set error correction level
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = qrFilter.outputImage else {
            errorMessage = "Fehler beim Generieren des QR-Codes"
            return nil
        }
        
        // Scale up the image for better quality
        let scaleX = 300 / outputImage.extent.size.width
        let scaleY = 300 / outputImage.extent.size.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            errorMessage = "Fehler beim Konvertieren des QR-Codes"
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - QR Code with Logo
    
    func generateQRCodeWithLogo(for box: Box, logo: UIImage? = nil) -> UIImage? {
        guard let qrImage = generateQRCode(for: box) else { return nil }
        
        let logoImage = logo ?? createDefaultLogo()
        return addLogo(logoImage, to: qrImage)
    }
    
    private func createDefaultLogo() -> UIImage {
        let size = CGSize(width: 60, height: 60)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw app logo or default icon
            let rect = CGRect(origin: .zero, size: size)
            
            // Background circle
            context.cgContext.setFillColor(UIColor.systemBlue.cgColor)
            context.cgContext.fillEllipse(in: rect)
            
            // House icon
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(3)
            
            let houseRect = rect.insetBy(dx: 15, dy: 15)
            let path = UIBezierPath()
            
            // House shape
            path.move(to: CGPoint(x: houseRect.midX, y: houseRect.minY))
            path.addLine(to: CGPoint(x: houseRect.maxX, y: houseRect.midY))
            path.addLine(to: CGPoint(x: houseRect.maxX, y: houseRect.maxY))
            path.addLine(to: CGPoint(x: houseRect.minX, y: houseRect.maxY))
            path.addLine(to: CGPoint(x: houseRect.minX, y: houseRect.midY))
            path.close()
            
            context.cgContext.addPath(path.cgPath)
            context.cgContext.strokePath()
        }
    }
    
    private func addLogo(_ logo: UIImage, to qrImage: UIImage) -> UIImage {
        let qrSize = qrImage.size
        let logoSize = CGSize(width: qrSize.width * 0.2, height: qrSize.height * 0.2)
        
        UIGraphicsBeginImageContextWithOptions(qrSize, false, 0)
        
        // Draw QR code
        qrImage.draw(in: CGRect(origin: .zero, size: qrSize))
        
        // Draw logo in center with white background
        let logoRect = CGRect(
            x: (qrSize.width - logoSize.width) / 2,
            y: (qrSize.height - logoSize.height) / 2,
            width: logoSize.width,
            height: logoSize.height
        )
        
        // White background for logo
        let backgroundRect = logoRect.insetBy(dx: -5, dy: -5)
        UIColor.white.setFill()
        UIBezierPath(roundedRect: backgroundRect, cornerRadius: 5).fill()
        
        // Draw logo
        logo.draw(in: logoRect)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage ?? qrImage
    }
    
    // MARK: - QR Code Reading
    
    func readQRCode(from image: UIImage) -> BoxQRData? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]
        
        guard let qrFeature = features?.first,
              let messageString = qrFeature.messageString,
              let data = messageString.data(using: .utf8) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(BoxQRData.self, from: data)
        } catch {
            // Try to decode as simple QR data
            do {
                let simpleData = try JSONDecoder().decode(SimpleBoxQRData.self, from: data)
                return BoxQRData(from: simpleData)
            } catch {
                errorMessage = "QR-Code konnte nicht gelesen werden: \(error.localizedDescription)"
                return nil
            }
        }
    }
    
    // MARK: - QR Code Validation
    
    func validateQRCode(_ qrData: BoxQRData) -> QRValidationResult {
        var issues: [QRValidationIssue] = []
        
        // Check data completeness
        if qrData.name.isEmpty {
            issues.append(.missingName)
        }
        
        if qrData.roomName.isEmpty {
            issues.append(.missingRoom)
        }
        
        if qrData.items.isEmpty {
            issues.append(.noItems)
        }
        
        // Check data consistency
        if qrData.totalItems != qrData.items.count {
            issues.append(.inconsistentItemCount)
        }
        
        let calculatedValue = qrData.items.reduce(0) { $0 + $1.estimatedValue }
        if abs(qrData.estimatedValue - calculatedValue) > 1.0 {
            issues.append(.inconsistentValue)
        }
        
        let actualFragileItems = qrData.items.filter { $0.isFragile }.count > 0
        if qrData.hasFragileItems != actualFragileItems {
            issues.append(.inconsistentFragileStatus)
        }
        
        // Check if QR code is recent
        let daysSinceCreated = Calendar.current.dateComponents([.day], from: qrData.createdDate, to: Date()).day ?? 0
        if daysSinceCreated > 30 {
            issues.append(.outdated)
        }
        
        return QRValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            confidence: calculateConfidence(for: qrData, issues: issues)
        )
    }
    
    private func calculateConfidence(for qrData: BoxQRData, issues: [QRValidationIssue]) -> Double {
        let baseConfidence = 1.0
        let penaltyPerIssue = 0.1
        
        let penalty = Double(issues.count) * penaltyPerIssue
        return max(0.0, baseConfidence - penalty)
    }
    
    // MARK: - Batch Operations
    
    func generateQRCodesForBoxes(_ boxes: [Box]) async -> [Box: UIImage] {
        var results: [Box: UIImage] = [:]
        
        for box in boxes {
            if let qrImage = generateQRCode(for: box) {
                results[box] = qrImage
            }
            
            // Add small delay to prevent UI blocking
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return results
    }
    
    // MARK: - Export and Sharing
    
    func exportQRCodeAsPDF(for box: Box) -> Data? {
        guard let qrImage = generateQRCodeWithLogo(for: box) else { return nil }
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // Letter size
        
        return pdfRenderer.pdfData { context in
            context.beginPage()
            
            let pageRect = context.pdfContextBounds
            let margin: CGFloat = 50
            let contentRect = pageRect.insetBy(dx: margin, dy: margin)
            
            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleText = "QR-Code: \(box.displayName)"
            let titleSize = titleText.size(withAttributes: [.font: titleFont])
            let titleRect = CGRect(
                x: contentRect.minX,
                y: contentRect.minY,
                width: contentRect.width,
                height: titleSize.height
            )
            
            titleText.draw(in: titleRect, withAttributes: [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ])
            
            // QR Code
            let qrSize: CGFloat = 300
            let qrRect = CGRect(
                x: (pageRect.width - qrSize) / 2,
                y: titleRect.maxY + 30,
                width: qrSize,
                height: qrSize
            )
            
            qrImage.draw(in: qrRect)
            
            // Box information
            let infoFont = UIFont.systemFont(ofSize: 14)
            let infoY = qrRect.maxY + 30
            
            let infoText = """
            Raum: \(box.roomName)
            Status: \(box.isPacked ? "Gepackt" : "Nicht gepackt")
            Priorität: \(box.priorityLevel.displayName)
            Gegenstände: \(box.totalItems)
            Geschätzter Wert: €\(String(format: "%.2f", box.estimatedValue))
            """
            
            let infoRect = CGRect(
                x: contentRect.minX,
                y: infoY,
                width: contentRect.width,
                height: contentRect.maxY - infoY
            )
            
            infoText.draw(in: infoRect, withAttributes: [
                .font: infoFont,
                .foregroundColor: UIColor.black
            ])
        }
    }
}

// MARK: - Data Structures

struct BoxQRData: Codable {
    let id: String
    let name: String
    let roomName: String
    let qrCode: String
    let isPacked: Bool
    let priority: Int
    let estimatedValue: Double
    let totalItems: Int
    let hasFragileItems: Bool
    let items: [ItemQRData]
    let createdDate: Date
    let lastModified: Date
    
    init(from simpleData: SimpleBoxQRData) {
        self.id = simpleData.id
        self.name = simpleData.name
        self.roomName = simpleData.roomName
        self.qrCode = simpleData.qrCode
        self.isPacked = false
        self.priority = 2
        self.estimatedValue = 0
        self.totalItems = 0
        self.hasFragileItems = false
        self.items = []
        self.createdDate = Date()
        self.lastModified = Date()
    }
}

struct SimpleBoxQRData: Codable {
    let id: String
    let name: String
    let roomName: String
    let qrCode: String
}

struct ItemQRData: Codable {
    let name: String
    let category: String
    let isFragile: Bool
    let estimatedValue: Double
}

// MARK: - Validation

struct QRValidationResult {
    let isValid: Bool
    let issues: [QRValidationIssue]
    let confidence: Double
    
    var severityLevel: QRSeverityLevel {
        if issues.contains(where: { $0.isCritical }) {
            return .critical
        } else if !issues.isEmpty {
            return .warning
        } else {
            return .valid
        }
    }
}

enum QRValidationIssue {
    case missingName
    case missingRoom
    case noItems
    case inconsistentItemCount
    case inconsistentValue
    case inconsistentFragileStatus
    case outdated
    
    var isCritical: Bool {
        switch self {
        case .missingName, .missingRoom:
            return true
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .missingName: return "Kein Kistenname vorhanden"
        case .missingRoom: return "Kein Raum zugeordnet"
        case .noItems: return "Keine Gegenstände in der Kiste"
        case .inconsistentItemCount: return "Anzahl Gegenstände stimmt nicht überein"
        case .inconsistentValue: return "Geschätzter Wert stimmt nicht überein"
        case .inconsistentFragileStatus: return "Zerbrechlich-Status stimmt nicht überein"
        case .outdated: return "QR-Code ist veraltet"
        }
    }
}

enum QRSeverityLevel {
    case valid
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .valid: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .valid: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
}

// MARK: - Extensions

extension String {
    func size(withAttributes attributes: [NSAttributedString.Key: Any]) -> CGSize {
        let attributedString = NSAttributedString(string: self, attributes: attributes)
        return attributedString.size()
    }
}