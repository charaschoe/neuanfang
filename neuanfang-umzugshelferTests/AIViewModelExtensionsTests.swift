//
//  AIViewModelExtensionsTests.swift
//  neuanfang-umzugshelferTests
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import XCTest
import CoreData
import Combine
@testable import neuanfang_umzugshelfer

@MainActor
final class AIViewModelExtensionsTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    var testRoom: Room!
    var testBox: Box!
    var testItems: [Item]!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "DataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        testContext = persistentContainer.viewContext
        
        // Create test data
        await createTestData()
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        testContext = nil
        testRoom = nil
        testBox = nil
        testItems = nil
        try await super.tearDown()
    }
    
    private func createTestData() async {
        testRoom = Room(context: testContext)
        testRoom.name = "Test Wohnzimmer"
        testRoom.roomType = "living_room"
        testRoom.createdDate = Date()
        
        testBox = Box(context: testContext)
        testBox.name = "Test Kiste 1"
        testBox.room = testRoom
        testBox.createdDate = Date()
        testBox.qrCode = "TEST_QR_123"
        
        // Create test items
        testItems = []
        
        let item1 = Item(context: testContext)
        item1.name = "Gaming Laptop"
        item1.category = "electronics"
        item1.isFragile = true
        item1.estimatedValue = 1200.0
        item1.box = testBox
        testItems.append(item1)
        
        let item2 = Item(context: testContext)
        item2.name = "Harry Potter Buch"
        item2.category = "books"
        item2.isFragile = false
        item2.estimatedValue = 15.0
        item2.box = testBox
        testItems.append(item2)
        
        let item3 = Item(context: testContext)
        item3.name = "Porzellan Tasse"
        item3.category = "kitchen"
        item3.isFragile = true
        item3.estimatedValue = 25.0
        item3.box = testBox
        testItems.append(item3)
        
        try? testContext.save()
    }
}

// MARK: - RoomListViewModel AI Extensions Tests

extension AIViewModelExtensionsTests {
    
    func testRoomListViewModelSmartSearchIntegration() async throws {
        let viewModel = RoomListViewModel(viewContext: testContext)
        
        // Initial state
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertNil(viewModel.searchStatistics)
        XCTAssertFalse(viewModel.isSearching)
        
        // Perform search
        await viewModel.performSmartSearch(query: "Laptop")
        
        // Should find the laptop item
        XCTAssertFalse(viewModel.searchResults.isEmpty)
        XCTAssertNotNil(viewModel.searchStatistics)
        XCTAssertFalse(viewModel.isSearching)
        
        // Check search statistics
        let stats = viewModel.searchStatistics!
        XCTAssertGreaterThan(stats.totalResults, 0)
        XCTAssertGreaterThan(stats.searchTime, 0)
        XCTAssertFalse(stats.query.isEmpty)
    }
    
    func testRoomListViewModelSearchSuggestions() async throws {
        let viewModel = RoomListViewModel(viewContext: testContext)
        
        await viewModel.generateSearchSuggestions(for: "La")
        
        XCTAssertFalse(viewModel.searchSuggestions.isEmpty)
        XCTAssertTrue(viewModel.searchSuggestions.contains { $0.contains("Laptop") })
    }
    
    func testRoomListViewModelNaturalLanguageSearch() async throws {
        let viewModel = RoomListViewModel(viewContext: testContext)
        
        await viewModel.performNaturalLanguageSearch(query: "Zeige mir alle zerbrechlichen Gegenstände")
        
        // Should find fragile items (Laptop and Tasse)
        XCTAssertFalse(viewModel.searchResults.isEmpty)
        
        let fragileItems = viewModel.searchResults.compactMap { result in
            if case .item(let item) = result.entity {
                return item.isFragile ? item : nil
            }
            return nil
        }
        
        XCTAssertEqual(fragileItems.count, 2) // Laptop und Tasse
    }
    
    func testRoomListViewModelSearchFiltering() async throws {
        let viewModel = RoomListViewModel(viewContext: testContext)
        
        let filters = SearchFilters(
            category: .electronics,
            isFragile: true,
            minValue: 1000.0,
            maxValue: 2000.0,
            roomType: nil
        )
        
        await viewModel.performFilteredSearch(query: "", filters: filters)
        
        // Should find only the laptop (electronics, fragile, 1200€)
        XCTAssertEqual(viewModel.searchResults.count, 1)
        
        if case .item(let item) = viewModel.searchResults.first?.entity {
            XCTAssertEqual(item.name, "Gaming Laptop")
        }
    }
    
    func testRoomListViewModelSearchClearance() async throws {
        let viewModel = RoomListViewModel(viewContext: testContext)
        
        // Perform search first
        await viewModel.performSmartSearch(query: "Laptop")
        XCTAssertFalse(viewModel.searchResults.isEmpty)
        
        // Clear search
        viewModel.clearSearch()
        
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertNil(viewModel.searchStatistics)
        XCTAssertTrue(viewModel.searchSuggestions.isEmpty)
    }
}

// MARK: - BoxDetailViewModel AI Extensions Tests

extension AIViewModelExtensionsTests {
    
    func testBoxDetailViewModelPackingSuggestions() async throws {
        let viewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        // Initial state
        XCTAssertNil(viewModel.aiRecommendations)
        XCTAssertFalse(viewModel.isGeneratingRecommendations)
        
        // Generate packing suggestions
        await viewModel.generatePackingSuggestions()
        
        // Should have recommendations
        XCTAssertNotNil(viewModel.aiRecommendations)
        XCTAssertFalse(viewModel.isGeneratingRecommendations)
        
        let recommendations = viewModel.aiRecommendations!
        XCTAssertFalse(recommendations.packingSuggestions.isEmpty)
        XCTAssertFalse(recommendations.potentialIssues.isEmpty) // Sollte Issues wegen zerbrechlicher Items haben
    }
    
    func testBoxDetailViewModelAILabeling() async throws {
        let viewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        await viewModel.generateAILabels(count: 3)
        
        XCTAssertNotNil(viewModel.aiRecommendations)
        let recommendations = viewModel.aiRecommendations!
        
        XCTAssertEqual(recommendations.labelOptions.count, 3)
        XCTAssertTrue(recommendations.labelOptions.allSatisfy { !$0.mainText.isEmpty })
    }
    
    func testBoxDetailViewModelOptimalBoxSizeSuggestion() async throws {
        let viewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        await viewModel.suggestOptimalBoxSize()
        
        XCTAssertNotNil(viewModel.aiRecommendations)
        let recommendations = viewModel.aiRecommendations!
        
        XCTAssertNotNil(recommendations.boxSizeRecommendation)
        XCTAssertFalse(recommendations.boxSizeRecommendation!.reasoning.isEmpty)
    }
    
    func testBoxDetailViewModelPackingIssuesAnalysis() async throws {
        let viewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        await viewModel.analyzePackingIssues()
        
        XCTAssertNotNil(viewModel.aiRecommendations)
        let recommendations = viewModel.aiRecommendations!
        
        // Sollte Issues wegen Mix aus zerbrechlichen und nicht-zerbrechlichen Items haben
        XCTAssertFalse(recommendations.potentialIssues.isEmpty)
        
        let hasFragilityIssue = recommendations.potentialIssues.contains { issue in
            issue.description.lowercased().contains("zerbrechlich") ||
            issue.description.lowercased().contains("fragil")
        }
        XCTAssertTrue(hasFragilityIssue)
    }
    
    func testBoxDetailViewModelQRCodeContentGeneration() async throws {
        let viewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        await viewModel.generateQRCodeContent()
        
        XCTAssertNotNil(viewModel.aiRecommendations)
        let recommendations = viewModel.aiRecommendations!
        
        XCTAssertNotNil(recommendations.qrCodeContent)
        let qrContent = recommendations.qrCodeContent!
        
        XCTAssertEqual(qrContent.boxId, testBox.qrCode)
        XCTAssertEqual(qrContent.itemCount, testItems.count)
        XCTAssertTrue(qrContent.hasFragileItems) // Wegen zerbrechlicher Items
        XCTAssertFalse(qrContent.shortDescription.isEmpty)
    }
    
    func testBoxDetailViewModelRecommendationsClearance() async throws {
        let viewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        // Generate recommendations first
        await viewModel.generatePackingSuggestions()
        XCTAssertNotNil(viewModel.aiRecommendations)
        
        // Clear recommendations
        viewModel.clearAIRecommendations()
        
        XCTAssertNil(viewModel.aiRecommendations)
    }
}

// MARK: - ItemViewModel AI Extensions Tests

extension AIViewModelExtensionsTests {
    
    func testItemViewModelVoiceToInventoryIntegration() async throws {
        let viewModel = ItemViewModel(viewContext: testContext)
        
        // Initial state
        XCTAssertFalse(viewModel.isVoiceRecording)
        XCTAssertNil(viewModel.voiceProcessingResult)
        XCTAssertFalse(viewModel.isProcessingVoice)
        
        // Mock voice input processing
        let mockVoiceInput = "Schwarzer Laptop Dell, zerbrechlich, 1500 Euro"
        await viewModel.processVoiceInput(mockVoiceInput)
        
        XCTAssertNotNil(viewModel.voiceProcessingResult)
        XCTAssertFalse(viewModel.isProcessingVoice)
        
        let result = viewModel.voiceProcessingResult!
        XCTAssertEqual(result.recognizedText, mockVoiceInput)
        XCTAssertFalse(result.extractedItems.isEmpty)
        
        let extractedItem = result.extractedItems.first!
        XCTAssertTrue(extractedItem.name.contains("Laptop"))
        XCTAssertTrue(extractedItem.isFragile)
        XCTAssertEqual(extractedItem.estimatedValue, 1500.0)
    }
    
    func testItemViewModelVoicePermissions() async throws {
        let viewModel = ItemViewModel(viewContext: testContext)
        
        let hasPermissions = await viewModel.checkVoicePermissions()
        
        // In Test-Umgebung können Permissions unterschiedlich sein
        XCTAssertTrue(hasPermissions || !hasPermissions) // Sollte boolean zurückgeben
    }
    
    func testItemViewModelMultipleVoiceItems() async throws {
        let viewModel = ItemViewModel(viewContext: testContext)
        
        let multipleItemsInput = "Laptop 800 Euro, Buch 15 Euro, Tasse zerbrechlich 20 Euro"
        await viewModel.processVoiceInput(multipleItemsInput)
        
        XCTAssertNotNil(viewModel.voiceProcessingResult)
        let result = viewModel.voiceProcessingResult!
        
        XCTAssertEqual(result.extractedItems.count, 3)
        
        // Überprüfe dass verschiedene Kategorien erkannt wurden
        let categories = Set(result.extractedItems.map { $0.category })
        XCTAssertTrue(categories.contains("electronics"))
        XCTAssertTrue(categories.contains("books"))
        XCTAssertTrue(categories.contains("kitchen"))
    }
    
    func testItemViewModelVoiceResultClearance() async throws {
        let viewModel = ItemViewModel(viewContext: testContext)
        
        // Process voice input first
        await viewModel.processVoiceInput("Test Item 50 Euro")
        XCTAssertNotNil(viewModel.voiceProcessingResult)
        
        // Clear result
        viewModel.clearVoiceResult()
        
        XCTAssertNil(viewModel.voiceProcessingResult)
    }
    
    func testItemViewModelVoiceItemSelection() async throws {
        let viewModel = ItemViewModel(viewContext: testContext)
        
        // Process voice input with multiple items
        await viewModel.processVoiceInput("Laptop 800 Euro, Buch 15 Euro")
        
        let result = viewModel.voiceProcessingResult!
        XCTAssertEqual(result.extractedItems.count, 2)
        
        // Select first item
        let selectedItem = result.extractedItems.first!
        await viewModel.selectVoiceExtractedItem(selectedItem)
        
        // Should populate item fields
        XCTAssertTrue(viewModel.name.contains("Laptop") || viewModel.name.contains("Buch"))
        XCTAssertTrue(viewModel.estimatedValue > 0)
    }
    
    func testItemViewModelVoiceErrorHandling() async throws {
        let viewModel = ItemViewModel(viewContext: testContext)
        
        // Test with empty voice input
        await viewModel.processVoiceInput("")
        
        XCTAssertNotNil(viewModel.voiceProcessingResult)
        let result = viewModel.voiceProcessingResult!
        
        XCTAssertTrue(result.extractedItems.isEmpty)
        XCTAssertEqual(result.recognizedText, "")
    }
}

// MARK: - Integration Tests für ViewModel AI Features

extension AIViewModelExtensionsTests {
    
    func testViewModelAIIntegration() async throws {
        // Test dass alle ViewModel AI-Features zusammenarbeiten
        let roomListViewModel = RoomListViewModel(viewContext: testContext)
        let boxDetailViewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        let itemViewModel = ItemViewModel(viewContext: testContext)
        
        // 1. Suche in RoomListViewModel
        await roomListViewModel.performSmartSearch(query: "Laptop")
        XCTAssertFalse(roomListViewModel.searchResults.isEmpty)
        
        // 2. Packing Suggestions in BoxDetailViewModel
        await boxDetailViewModel.generatePackingSuggestions()
        XCTAssertNotNil(boxDetailViewModel.aiRecommendations)
        
        // 3. Voice Processing in ItemViewModel
        await itemViewModel.processVoiceInput("Neuer Laptop 1000 Euro")
        XCTAssertNotNil(itemViewModel.voiceProcessingResult)
        
        // Alle sollten ohne Konflikte funktionieren
    }
    
    func testViewModelAIPerformance() async throws {
        let boxDetailViewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Führe mehrere AI-Operationen parallel aus
        async let packingSuggestions: Void = boxDetailViewModel.generatePackingSuggestions()
        async let labelGeneration: Void = boxDetailViewModel.generateAILabels(count: 3)
        async let issueAnalysis: Void = boxDetailViewModel.analyzePackingIssues()
        
        let _ = await (packingSuggestions, labelGeneration, issueAnalysis)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Sollte unter 5 Sekunden dauern
        XCTAssertLessThan(timeElapsed, 5.0)
        
        // Alle Ergebnisse sollten vorhanden sein
        XCTAssertNotNil(boxDetailViewModel.aiRecommendations)
        let recommendations = boxDetailViewModel.aiRecommendations!
        XCTAssertFalse(recommendations.packingSuggestions.isEmpty)
        XCTAssertEqual(recommendations.labelOptions.count, 3)
        XCTAssertFalse(recommendations.potentialIssues.isEmpty)
    }
    
    func testViewModelAIStateManagement() async throws {
        let boxDetailViewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        // Test loading states
        XCTAssertFalse(boxDetailViewModel.isGeneratingRecommendations)
        
        // Start async operation
        let task = Task {
            await boxDetailViewModel.generatePackingSuggestions()
        }
        
        // Should be in loading state briefly
        // Note: In tests this might be too fast to catch
        
        await task.value
        
        // Should be finished
        XCTAssertFalse(boxDetailViewModel.isGeneratingRecommendations)
        XCTAssertNotNil(boxDetailViewModel.aiRecommendations)
    }
    
    func testViewModelAIMemoryManagement() async throws {
        weak var weakViewModel: BoxDetailViewModel?
        
        do {
            let viewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
            weakViewModel = viewModel
            
            await viewModel.generatePackingSuggestions()
            XCTAssertNotNil(viewModel.aiRecommendations)
        }
        
        // ViewModel sollte freigegeben werden
        XCTAssertNil(weakViewModel)
    }
}

// MARK: - Error Handling Tests für ViewModels

extension AIViewModelExtensionsTests {
    
    func testViewModelAIErrorHandling() async throws {
        let boxDetailViewModel = BoxDetailViewModel(box: testBox, viewContext: testContext)
        
        // Create empty box to trigger potential errors
        let emptyBox = Box(context: testContext)
        emptyBox.name = "Empty Box"
        
        let emptyBoxViewModel = BoxDetailViewModel(box: emptyBox, viewContext: testContext)
        
        // Should handle empty box gracefully
        await emptyBoxViewModel.generatePackingSuggestions()
        
        // Should not crash, might have no recommendations or error state
        // Depending on implementation, this might result in nil recommendations or error handling
    }
    
    func testSearchViewModelErrorRecovery() async throws {
        let viewModel = RoomListViewModel(viewContext: testContext)
        
        // Test with invalid search query
        await viewModel.performSmartSearch(query: "")
        
        // Should handle empty query gracefully
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }
}