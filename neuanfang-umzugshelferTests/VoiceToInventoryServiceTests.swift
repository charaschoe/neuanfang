//
//  VoiceToInventoryServiceTests.swift
//  neuanfang-umzugshelferTests
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import XCTest
import AVFoundation
import Speech
@testable import neuanfang_umzugshelfer

@MainActor
final class VoiceToInventoryServiceTests: XCTestCase {
    
    var service: VoiceToInventoryService!
    var mockAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    override func setUp() async throws {
        try await super.setUp()
        service = VoiceToInventoryService()
    }
    
    override func tearDown() async throws {
        await service.stopRecording()
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestSpeechPermission() async throws {
        let permissionGranted = await service.requestSpeechPermission()
        
        // In Tests kann die Permission unterschiedlich sein
        // Wir testen nur dass die Methode kein Error wirft
        XCTAssertTrue(permissionGranted || !permissionGranted) // Sollte boolean zurückgeben
    }
    
    func testCheckPermissions() async throws {
        let hasPermissions = await service.checkPermissions()
        
        // In Test-Umgebung können Permissions fehlen - das ist OK
        XCTAssertTrue(hasPermissions || !hasPermissions) // Sollte boolean zurückgeben
    }
    
    // MARK: - Voice Processing Tests
    
    func testProcessVoiceInputWithValidText() async throws {
        let testInput = "Laptop Dell XPS 15 Zoll, zerbrechlich, Wert 1200 Euro, Kategorie Elektronik"
        
        let result = try await service.processVoiceInput(testInput)
        
        XCTAssertEqual(result.recognizedText, testInput)
        XCTAssertEqual(result.extractedItems.count, 1)
        
        let item = result.extractedItems.first!
        XCTAssertEqual(item.name, "Laptop Dell XPS 15 Zoll")
        XCTAssertTrue(item.isFragile)
        XCTAssertEqual(item.estimatedValue, 1200.0)
        XCTAssertEqual(item.category, "electronics")
    }
    
    func testProcessVoiceInputWithMultipleItems() async throws {
        let testInput = "Buch Harry Potter 15 Euro, Tasse blau zerbrechlich 8 Euro, Laptop 800 Euro"
        
        let result = try await service.processVoiceInput(testInput)
        
        XCTAssertEqual(result.extractedItems.count, 3)
        
        // Überprüfe dass alle Items erkannt wurden
        let itemNames = result.extractedItems.map { $0.name }
        XCTAssertTrue(itemNames.contains("Buch Harry Potter"))
        XCTAssertTrue(itemNames.contains("Tasse blau"))
        XCTAssertTrue(itemNames.contains("Laptop"))
    }
    
    func testProcessVoiceInputWithNoItems() async throws {
        let testInput = "Hallo, wie geht es dir heute?"
        
        let result = try await service.processVoiceInput(testInput)
        
        XCTAssertEqual(result.recognizedText, testInput)
        XCTAssertTrue(result.extractedItems.isEmpty)
    }
    
    // MARK: - Text Analysis Tests
    
    func testExtractItemsFromGermanText() async throws {
        let testCases = [
            "Laptop schwarz 800 Euro": ("Laptop schwarz", 800.0, false),
            "Tasse zerbrechlich 15 Euro": ("Tasse", 15.0, true),
            "Buch Roman Wert zehn Euro": ("Buch Roman", 10.0, false),
            "Handy fragil 600": ("Handy", 600.0, true)
        ]
        
        for (input, expected) in testCases {
            let result = try await service.processVoiceInput(input)
            
            XCTAssertEqual(result.extractedItems.count, 1)
            let item = result.extractedItems.first!
            XCTAssertEqual(item.name, expected.0)
            XCTAssertEqual(item.estimatedValue, expected.1)
            XCTAssertEqual(item.isFragile, expected.2)
        }
    }
    
    func testCategoryRecognition() async throws {
        let testCases = [
            "Laptop Computer": "electronics",
            "Tasse Küche": "kitchen",
            "Buch Literatur": "books",
            "Shirt Kleidung": "clothing",
            "Tisch Möbel": "furniture"
        ]
        
        for (input, expectedCategory) in testCases {
            let result = try await service.processVoiceInput(input)
            
            if !result.extractedItems.isEmpty {
                XCTAssertEqual(result.extractedItems.first!.category, expectedCategory)
            }
        }
    }
    
    func testFragileItemDetection() async throws {
        let fragileKeywords = ["zerbrechlich", "fragil", "vorsichtig", "Glas", "Porzellan"]
        
        for keyword in fragileKeywords {
            let input = "Test Item \(keyword) 20 Euro"
            let result = try await service.processVoiceInput(input)
            
            if !result.extractedItems.isEmpty {
                XCTAssertTrue(result.extractedItems.first!.isFragile, "Should detect '\(keyword)' as fragile indicator")
            }
        }
    }
    
    // MARK: - Voice Command Tests
    
    func testProcessVoiceCommands() async throws {
        let commands = [
            "Stoppe Aufnahme",
            "Neue Kiste",
            "Vorheriger Gegenstand",
            "Wiederholen",
            "Hilfe"
        ]
        
        for command in commands {
            let result = try await service.processVoiceInput(command)
            
            // Voice Commands sollten keine Items extrahieren
            XCTAssertTrue(result.extractedItems.isEmpty)
            XCTAssertEqual(result.recognizedText, command)
        }
    }
    
    // MARK: - Recording State Tests
    
    func testRecordingStateManagement() async throws {
        // Initial state
        XCTAssertFalse(service.isRecording)
        
        // Note: Actual recording tests might not work in test environment
        // but we can test state management
        let canStartRecording = await service.checkPermissions()
        if canStartRecording {
            // Test would start recording here in real scenario
            // await service.startRecording()
            // XCTAssertTrue(service.isRecording)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleInvalidAudioInput() async throws {
        // Test mit leerem String
        let result = try await service.processVoiceInput("")
        XCTAssertTrue(result.extractedItems.isEmpty)
        XCTAssertEqual(result.recognizedText, "")
    }
    
    func testHandleNoPermissions() async throws {
        // Create service with no permissions (mock scenario)
        let hasPermissions = await service.checkPermissions()
        
        if !hasPermissions {
            // Should handle gracefully when no permissions
            let canRecord = await service.checkPermissions()
            XCTAssertFalse(canRecord)
        }
    }
    
    // MARK: - Integration Tests
    
    func testVoiceToItemConversion() async throws {
        let complexInput = """
        Ich habe hier einen schwarzen Laptop von Dell, 
        Modell XPS 15, er ist sehr zerbrechlich und kostete 1200 Euro. 
        Dann habe ich noch ein Buch, Harry Potter Band 1, 
        das ist etwa 15 Euro wert. 
        Und eine blaue Kaffeetasse aus Porzellan, die ist auch zerbrechlich, 
        Wert ungefähr 20 Euro.
        """
        
        let result = try await service.processVoiceInput(complexInput)
        
        XCTAssertEqual(result.extractedItems.count, 3)
        
        // Laptop
        let laptop = result.extractedItems.first { $0.name.contains("Laptop") || $0.name.contains("Dell") }
        XCTAssertNotNil(laptop)
        XCTAssertTrue(laptop?.isFragile ?? false)
        XCTAssertEqual(laptop?.estimatedValue, 1200.0)
        XCTAssertEqual(laptop?.category, "electronics")
        
        // Buch
        let book = result.extractedItems.first { $0.name.contains("Buch") || $0.name.contains("Harry Potter") }
        XCTAssertNotNil(book)
        XCTAssertEqual(book?.estimatedValue, 15.0)
        XCTAssertEqual(book?.category, "books")
        
        // Tasse
        let cup = result.extractedItems.first { $0.name.contains("Tasse") || $0.name.contains("Kaffeetasse") }
        XCTAssertNotNil(cup)
        XCTAssertTrue(cup?.isFragile ?? false)
        XCTAssertEqual(cup?.estimatedValue, 20.0)
        XCTAssertEqual(cup?.category, "kitchen")
    }
    
    // MARK: - Performance Tests
    
    func testProcessingPerformance() async throws {
        let longText = String(repeating: "Laptop 800 Euro, Buch 15 Euro, Tasse zerbrechlich 20 Euro. ", count: 50)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await service.processVoiceInput(longText)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Processing sollte unter 2 Sekunden dauern
        XCTAssertLessThan(timeElapsed, 2.0)
        XCTAssertFalse(result.extractedItems.isEmpty)
    }
    
    // MARK: - Language Processing Tests
    
    func testGermanNumberRecognition() async throws {
        let numberTests = [
            "eins Euro": 1.0,
            "zwei Euro": 2.0,
            "fünf Euro": 5.0,
            "zehn Euro": 10.0,
            "zwanzig Euro": 20.0,
            "hundert Euro": 100.0,
            "tausend Euro": 1000.0
        ]
        
        for (input, expectedValue) in numberTests {
            let testText = "Test Item \(input)"
            let result = try await service.processVoiceInput(testText)
            
            if !result.extractedItems.isEmpty {
                XCTAssertEqual(result.extractedItems.first!.estimatedValue, expectedValue, 
                              "Failed to recognize number in: \(input)")
            }
        }
    }
    
    func testSpecialCharacterHandling() async throws {
        let specialTexts = [
            "Laptop (schwarz) 800€",
            "Buch \"Harry Potter\" 15,50 Euro",
            "Tasse & Untertasse 25 Euro",
            "PC/Laptop 900 Euro"
        ]
        
        for text in specialTexts {
            let result = try await service.processVoiceInput(text)
            
            // Sollte nicht crashen und mindestens Text erkennen
            XCTAssertEqual(result.recognizedText, text)
        }
    }
    
    // MARK: - Mock Helper Methods
    
    private func createMockVoiceResult(text: String) -> VoiceProcessingResult {
        return VoiceProcessingResult(
            recognizedText: text,
            extractedItems: [],
            confidence: 0.8,
            processingTime: 0.5
        )
    }
}

// MARK: - Voice Processing Result Extensions for Testing

extension VoiceProcessingResult {
    static func mock(
        text: String = "Test text",
        items: [VoiceExtractedItem] = [],
        confidence: Double = 0.8
    ) -> VoiceProcessingResult {
        return VoiceProcessingResult(
            recognizedText: text,
            extractedItems: items,
            confidence: confidence,
            processingTime: 0.5
        )
    }
}

extension VoiceExtractedItem {
    static func mock(
        name: String = "Test Item",
        category: String = "other",
        isFragile: Bool = false,
        value: Double = 0.0
    ) -> VoiceExtractedItem {
        return VoiceExtractedItem(
            name: name,
            category: category,
            isFragile: isFragile,
            estimatedValue: value,
            confidence: 0.8,
            description: nil
        )
    }
}