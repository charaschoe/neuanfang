//
//  CameraService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import AVFoundation
import Photos
import Vision
import CoreImage

@MainActor
final class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthorized = false
    @Published var isProcessing = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    @Published var detectedObjects: [DetectedObject] = []
    @Published var cameraStatus: CameraStatus = .unknown
    
    // MARK: - Private Properties
    
    private let photoLibrary = PHPhotoLibrary.shared()
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var completion: ((Result<UIImage, CameraError>) -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkCameraAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            isAuthorized = true
            cameraStatus = .authorized
            return true
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            cameraStatus = granted ? .authorized : .denied
            return granted
            
        case .denied, .restricted:
            isAuthorized = false
            cameraStatus = .denied
            errorMessage = "Kamera-Zugriff verweigert. Bitte in den Einstellungen aktivieren."
            return false
            
        @unknown default:
            isAuthorized = false
            cameraStatus = .unknown
            return false
        }
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            return true
            
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
            
        case .denied, .restricted:
            errorMessage = "Fotobibliothek-Zugriff verweigert. Bitte in den Einstellungen aktivieren."
            return false
            
        @unknown default:
            return false
        }
    }
    
    private func checkCameraAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            isAuthorized = true
            cameraStatus = .authorized
        case .denied, .restricted:
            isAuthorized = false
            cameraStatus = .denied
        case .notDetermined:
            cameraStatus = .notDetermined
        @unknown default:
            cameraStatus = .unknown
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto(completion: @escaping (Result<UIImage, CameraError>) -> Void) {
        self.completion = completion
        
        guard isAuthorized else {
            completion(.failure(.notAuthorized))
            return
        }
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            completion(.failure(.cameraNotAvailable))
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        picker.cameraFlashMode = .auto
        
        // Enhanced camera settings
        if #available(iOS 13.0, *) {
            picker.cameraDevice = .rear
        }
        
        // Present camera
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(picker, animated: true)
        } else {
            completion(.failure(.presentationFailed))
            isProcessing = false
        }
    }
    
    func selectFromPhotoLibrary(completion: @escaping (Result<UIImage, CameraError>) -> Void) {
        self.completion = completion
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            completion(.failure(.photoLibraryNotAvailable))
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        
        // Present photo library
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(picker, animated: true)
        } else {
            completion(.failure(.presentationFailed))
            isProcessing = false
        }
    }
    
    // MARK: - Image Processing
    
    func processImage(_ image: UIImage) async -> ProcessedImage {
        isProcessing = true
        
        // Enhance image quality
        let enhancedImage = enhanceImageQuality(image)
        
        // Detect objects
        let objects = await detectObjects(in: enhancedImage)
        
        // Extract metadata
        let metadata = extractImageMetadata(enhancedImage)
        
        isProcessing = false
        
        return ProcessedImage(
            originalImage: image,
            enhancedImage: enhancedImage,
            detectedObjects: objects,
            metadata: metadata,
            suggestedCategory: suggestCategory(from: objects),
            isFragilePrediction: predictFragility(from: objects)
        )
    }
    
    private func enhanceImageQuality(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        
        // Apply filters for better quality
        var outputImage = ciImage
        
        // Auto-enhance
        if let autoFilter = CIFilter(name: "CIColorControls") {
            autoFilter.setValue(outputImage, forKey: kCIInputImageKey)
            autoFilter.setValue(1.1, forKey: kCIInputSaturationKey) // Slight saturation boost
            autoFilter.setValue(1.05, forKey: kCIInputContrastKey) // Slight contrast boost
            
            if let result = autoFilter.outputImage {
                outputImage = result
            }
        }
        
        // Sharpen
        if let sharpenFilter = CIFilter(name: "CIUnsharpMask") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.5, forKey: kCIInputIntensityKey)
            sharpenFilter.setValue(2.5, forKey: kCIInputRadiusKey)
            
            if let result = sharpenFilter.outputImage {
                outputImage = result
            }
        }
        
        // Convert back to UIImage
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
    
    private func detectObjects(in image: UIImage) async -> [DetectedObject] {
        guard let cgImage = image.cgImage else { return [] }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeObjectsRequest { request, error in
                if let error = error {
                    print("Object detection error: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let objects = observations.compactMap { observation -> DetectedObject? in
                    guard let topLabel = observation.labels.first else { return nil }
                    
                    return DetectedObject(
                        label: topLabel.identifier,
                        confidence: topLabel.confidence,
                        boundingBox: observation.boundingBox,
                        suggestedCategory: self.mapToItemCategory(topLabel.identifier)
                    )
                }
                
                continuation.resume(returning: objects)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform object detection: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    private func mapToItemCategory(_ label: String) -> ItemCategory {
        let lowercaseLabel = label.lowercased()
        
        // Electronics
        if lowercaseLabel.contains("television") || lowercaseLabel.contains("computer") || 
           lowercaseLabel.contains("phone") || lowercaseLabel.contains("tablet") ||
           lowercaseLabel.contains("camera") || lowercaseLabel.contains("speaker") {
            return .electronics
        }
        
        // Books
        if lowercaseLabel.contains("book") || lowercaseLabel.contains("magazine") {
            return .books
        }
        
        // Clothing
        if lowercaseLabel.contains("shirt") || lowercaseLabel.contains("shoe") || 
           lowercaseLabel.contains("clothing") || lowercaseLabel.contains("jacket") {
            return .clothing
        }
        
        // Kitchenware
        if lowercaseLabel.contains("pot") || lowercaseLabel.contains("pan") || 
           lowercaseLabel.contains("plate") || lowercaseLabel.contains("cup") ||
           lowercaseLabel.contains("utensil") || lowercaseLabel.contains("appliance") {
            return .kitchenware
        }
        
        // Furniture
        if lowercaseLabel.contains("chair") || lowercaseLabel.contains("table") || 
           lowercaseLabel.contains("lamp") || lowercaseLabel.contains("furniture") {
            return .furniture
        }
        
        // Toys
        if lowercaseLabel.contains("toy") || lowercaseLabel.contains("doll") || 
           lowercaseLabel.contains("game") {
            return .toys
        }
        
        // Tools
        if lowercaseLabel.contains("tool") || lowercaseLabel.contains("hammer") || 
           lowercaseLabel.contains("screwdriver") {
            return .tools
        }
        
        // Plants
        if lowercaseLabel.contains("plant") || lowercaseLabel.contains("flower") || 
           lowercaseLabel.contains("tree") {
            return .plants
        }
        
        return .other
    }
    
    private func suggestCategory(from objects: [DetectedObject]) -> ItemCategory {
        guard !objects.isEmpty else { return .other }
        
        // Find the object with highest confidence
        let bestObject = objects.max(by: { $0.confidence < $1.confidence })
        return bestObject?.suggestedCategory ?? .other
    }
    
    private func predictFragility(from objects: [DetectedObject]) -> Bool {
        let fragileKeywords = ["glass", "ceramic", "vase", "mirror", "screen", "electronics"]
        
        return objects.contains { object in
            fragileKeywords.contains { keyword in
                object.label.lowercased().contains(keyword)
            }
        }
    }
    
    private func extractImageMetadata(_ image: UIImage) -> ImageMetadata {
        return ImageMetadata(
            size: image.size,
            scale: image.scale,
            orientation: image.imageOrientation,
            hasAlpha: image.cgImage?.alphaInfo != .none,
            colorSpace: image.cgImage?.colorSpace?.name,
            dateTaken: Date() // Would extract from EXIF data in real implementation
        )
    }
    
    // MARK: - Utility Methods
    
    func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    func generateThumbnail(from image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage {
        return resizeImage(image, to: size)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension CameraService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true) {
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            
            if let image = image {
                self.capturedImage = image
                self.completion?(.success(image))
                
                Task {
                    let processed = await self.processImage(image)
                    self.detectedObjects = processed.detectedObjects
                }
            } else {
                self.completion?(.failure(.imageProcessingFailed))
            }
            
            self.isProcessing = false
            self.completion = nil
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.completion?(.failure(.userCancelled))
            self.isProcessing = false
            self.completion = nil
        }
    }
}

// MARK: - Supporting Types

enum CameraStatus {
    case unknown
    case notDetermined
    case authorized
    case denied
    case restricted
    
    var description: String {
        switch self {
        case .unknown: return "Unbekannt"
        case .notDetermined: return "Nicht bestimmt"
        case .authorized: return "Berechtigt"
        case .denied: return "Verweigert"
        case .restricted: return "Eingeschränkt"
        }
    }
    
    var iconName: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .notDetermined: return "camera.circle"
        case .authorized: return "camera.circle.fill"
        case .denied, .restricted: return "camera.circle.slash"
        }
    }
    
    var color: Color {
        switch self {
        case .unknown, .notDetermined: return .gray
        case .authorized: return .green
        case .denied, .restricted: return .red
        }
    }
}

enum CameraError: LocalizedError {
    case notAuthorized
    case cameraNotAvailable
    case photoLibraryNotAvailable
    case presentationFailed
    case imageProcessingFailed
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Kamera-Zugriff nicht berechtigt"
        case .cameraNotAvailable:
            return "Kamera nicht verfügbar"
        case .photoLibraryNotAvailable:
            return "Fotobibliothek nicht verfügbar"
        case .presentationFailed:
            return "Kamera konnte nicht geöffnet werden"
        case .imageProcessingFailed:
            return "Bildverarbeitung fehlgeschlagen"
        case .userCancelled:
            return "Vom Benutzer abgebrochen"
        }
    }
}

struct DetectedObject {
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    let suggestedCategory: ItemCategory
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
    
    var isHighConfidence: Bool {
        confidence > 0.7
    }
}

struct ProcessedImage {
    let originalImage: UIImage
    let enhancedImage: UIImage
    let detectedObjects: [DetectedObject]
    let metadata: ImageMetadata
    let suggestedCategory: ItemCategory
    let isFragilePrediction: Bool
}

struct ImageMetadata {
    let size: CGSize
    let scale: CGFloat
    let orientation: UIImage.Orientation
    let hasAlpha: Bool
    let colorSpace: CFString?
    let dateTaken: Date
    
    var fileSizeEstimate: Int {
        Int(size.width * size.height * scale * 4) // Rough estimate for RGBA
    }
    
    var aspectRatio: CGFloat {
        size.width / size.height
    }
}

// MARK: - SwiftUI Integration

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var cameraService: CameraService
    let completion: (Result<UIImage, CameraError>) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            
            if let image = image {
                parent.completion(.success(image))
            } else {
                parent.completion(.failure(.imageProcessingFailed))
            }
            
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(.failure(.userCancelled))
            picker.dismiss(animated: true)
        }
    }
}

#Preview("Camera Service Status") {
    VStack(spacing: 20) {
        let cameraService = CameraService()
        
        HStack {
            Image(systemName: cameraService.cameraStatus.iconName)
                .foregroundColor(cameraService.cameraStatus.color)
            Text(cameraService.cameraStatus.description)
        }
        .liquidGlass(.floating)
        .padding()
        
        Button("Test Camera") {
            cameraService.capturePhoto { result in
                switch result {
                case .success(let image):
                    print("Captured image: \(image.size)")
                case .failure(let error):
                    print("Camera error: \(error)")
                }
            }
        }
        .liquidGlass(.dynamic)
        .padding()
    }
    .padding()
}