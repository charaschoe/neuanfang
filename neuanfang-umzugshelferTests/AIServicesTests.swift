//
//  AIServicesTests.swift
//  neuanfang-umzugshelferTests
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import XCTest
import CoreData
@testable import neuanfang_umzugshelfer

@MainActor
final class AIServicesTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    var testRoom: Room!
    var testBox: Box!
    var testItems: [Item]!
    
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
        item1.name = "Laptop"
        item1.category = "electronics"
        item1.isFragile = true
        item1.estimatedValue = 800.0
        item1.box = testBox
        testItems.append(item1)
        
        let item2 = Item(context: testContext)
        item2.name = "Buch"
        item2.category = "books"
        item2.isFragile = false
        item2.estimatedValue = 15.0
        item2.box = testBox
        testItems.append(item2)
        
        let item3 = Item(context: testContext)
        item3.name = "Tasse"
        item3.category = "kitchen"
        item3.isFragile = true
        item3.estimatedValue = 10.0
        item3.box = testBox
        testItems.append(item3)
        
        try? testContext.save()
    }
}

// MARK: - FoundationModelsService Tests

extension AIServicesTests {
    
    func testFoundationModelsServiceInitialization() async throws {
        let service = FoundationModelsService.shared
        XCTAssertNotNil(service)
    }
    
    func testCategorizeItem() async throws {
        let service = FoundationModelsService.shared
        
        // Test elektronisches Gerät
        let laptopCategory = try await service.categorizeItem(description: "Gaming Laptop 15 Zoll")
        XCTAssertEqual(laptopCategory, .electronics)
        
        // Test Küchengegenstand
        let cupCategory = try await service.categorizeItem(description: "Kaffeetasse aus Porzellan")
        XCTAssertEqual(cupCategory, .kitchen)
    }
    
    func testGenerateMovingAdvice() async throws {
        let service = FoundationModelsService.shared
        let context = MovingContext(
            roomType: "living_room",
            itemCount: 15,
            hasFragileItems: true,
            totalValue: 2500.0,
            movingDate: Date().addingTimeInterval(7 * 24 * 3600)
        )
        
        let advice = try await service.generateMovingAdvice(context: context)
        XCTAssertFalse(advice.isEmpty)
        XCTAssertTrue(advice.count > 10) // Sollte substantiellen Rat geben
    }
}

// MARK: - AIPackingSuggestionService Tests

extension AIServicesTests {
    
    func testPackingSuggestionsGeneration() async throws {
        let service = AIPackingSuggestionService()
        
        let suggestions = try await service.generatePackingSuggestions(for: testBox)
        
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.contains { $0.type == .protection }) // Sollte Schutzmaßnahmen enthalten
    }
    
    func testPackingIssuesAnalysis() async throws {
        let service = AIPackingSuggestionService()
        
        let issues = try await service.analyzePackingIssues(for: testBox)
        
        // Mit zerbrechlichen Gegenständen sollten Issues erkannt werden
        XCTAssertFalse(issues.isEmpty)
    }
    
    func testOptimalBoxSizeSuggestion() async throws {
        let service = AIPackingSuggestionService()
        
        let recommendation = try await service.suggestOptimalBoxSize(for: testItems)
        
        XCTAssertNotNil(recommendation)
        XCTAssertFalse(recommendation.reasoning.isEmpty)
    }
    
    func testOptimalPackingStrategy() async throws {
        let service = AIPackingSuggestionService()
        
        let strategy = try await service.generateOptimalPackingStrategy(for: testItems, targetBoxCount: 2)
        
        XCTAssertEqual(strategy.totalBoxes, 2)
        XCTAssertFalse(strategy.recommendations.isEmpty)
        XCTAssertGreaterThan(strategy.estimatedTime, 0)
    }
}

// MARK: - AILabelingService Tests

extension AIServicesTests {
    
    func testSmartLabelGeneration() async throws {
        let service = AILabelingService()
        
        let label = try await service.generateSmartLabel(for: testBox)
        
        XCTAssertFalse(label.mainText.isEmpty)
        XCTAssertEqual(label.itemCount, testItems.count)
        XCTAssertTrue(label.hasSpecialHandling) // Wegen zerbrechlicher Items
    }
    
    func testLabelOptionsGeneration() async throws {
        let service = AILabelingService()
        
        let labels = try await service.generateLabelOptions(for: testBox, count: 3)
        
        XCTAssertEqual(labels.count, 3)
        XCTAssertTrue(labels.allSatisfy { !$0.mainText.isEmpty })
    }
    
    func testQRCodeContentGeneration() async throws {
        let service = AILabelingService()
        
        let qrContent = try await service.generateQRCodeContent(for: testBox)
        
        XCTAssertEqual(qrContent.boxId, testBox.qrCode)
        XCTAssertFalse(qrContent.shortDescription.isEmpty)
        XCTAssertEqual(qrContent.itemCount, testItems.count)
        XCTAssertTrue(qrContent.hasFragileItems) // Wegen zerbrechlicher Items
    }
    
    func testEmergencyLabelsGeneration() async throws {
        let service = AILabelingService()
        
        // Erstelle ein Item mit Notfall-Eigenschaften
        let emergencyItem = Item(context: testContext)
        emergencyItem.name = "Erste Hilfe Koffer"
        emergencyItem.itemDescription = "Medikamente und Verbandsmaterial"
        emergencyItem.box = testBox
        
        let emergencyLabels = try await service.generateEmergencyLabels(for: [testBox])
        
        // Sollte Emergency Label für First Aid Kit erstellen
        XCTAssertFalse(emergencyLabels.isEmpty)
    }
}

// MARK: - SmartSearchService Tests

extension AIServicesTests {
    
    func testSmartSearchBasicFunctionality() async throws {
        let service = SmartSearchService(viewContext: testContext)
        
        let results = try await service.performSmartSearch(query: "Laptop")
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { result in
            if case .item(let item) = result.entity {
                return item.name?.contains("Laptop") == true
            }
            return false
        })
    }
    
    func testSearchSuggestions() async throws {
        let service = SmartSearchService(viewContext: testContext)
        
        let suggestions = try await service.generateSearchSuggestions(for: "La")
        
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.count <= 5) // Maximal 5 Vorschläge
    }
    
    func testFilteredSearch() async throws {
        let service = SmartSearchService(viewContext: testContext)
        
        let filters = SearchFilters(
            category: .electronics,
            isFragile: true,
            minValue: 500.0,
            maxValue: 1000.0,
            roomType: nil
        )
        
        let results = try await service.performFilteredSearch(query: "", filters: filters)
        
        // Sollte nur das Laptop finden (electronics, fragile, 800€)
        XCTAssertEqual(results.count, 1)
        if case .item(let item) = results.first?.entity {
            XCTAssertEqual(item.name, "Laptop")
        }
    }
    
    func testNaturalLanguageSearch() async throws {
        let service = SmartSearchService(viewContext: testContext)
        
        let results = try await service.performNaturalLanguageSearch(query: "Zeige mir alle zerbrechlichen Gegenstände")
        
        // Sollte Laptop und Tasse finden (beide zerbrechlich)
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { result in
            if case .item(let item) = result.entity {
                return item.isFragile
            }
            return false
        })
    }
}

// MARK: - AITimelineService Tests

extension AIServicesTests {
    
    func testTimelineGeneration() async throws {
        let service = AITimelineService(viewContext: testContext)
        
        let preferences = TimelinePreferences(
            startTime: 9,
            endTime: 17,
            workDaysOnly: true,
            intensity: .normal,
            helpersAvailable: 2
        )
        
        let timeline = try await service.generatePersonalizedTimeline(
            movingDate: Date().addingTimeInterval(14 * 24 * 3600), // 2 Wochen
            rooms: [testRoom],
            preferences: preferences
        )
        
        XCTAssertFalse(timeline.milestones.isEmpty)
        XCTAssertEqual(timeline.preferences.startTime, 9)
        XCTAssertEqual(timeline.preferences.endTime, 17)
    }
    
    func testTimeEstimation() async throws {
        let service = AITimelineService(viewContext: testContext)
        
        let estimate = try await service.estimateTimeRequirements(for: [testRoom])
        
        XCTAssertGreaterThan(estimate.total, 0)
        XCTAssertGreaterThan(estimate.packing, 0)
        XCTAssertGreaterThan(estimate.transport, 0)
    }
    
    func testEmergencyTimeline() async throws {
        let service = AITimelineService(viewContext: testContext)
        
        let timeline = try await service.generateEmergencyTimeline(
            movingDate: Date().addingTimeInterval(24 * 3600), // Morgen
            rooms: [testRoom],
            daysAvailable: 1
        )
        
        XCTAssertFalse(timeline.milestones.isEmpty)
        XCTAssertTrue(timeline.milestones.contains { $0.title.contains("Notfall") || $0.title.contains("Express") })
    }
}

// MARK: - MovingNotesAssistant Tests

extension AIServicesTests {
    
    func testContextualTipsGeneration() async throws {
        let assistant = MovingNotesAssistant(viewContext: testContext)
        
        let tips = try await assistant.generateContextualTips()
        
        XCTAssertFalse(tips.isEmpty)
        XCTAssertTrue(tips.allSatisfy { !$0.content.isEmpty })
    }
    
    func testPersonalizedReminders() async throws {
        let assistant = MovingNotesAssistant(viewContext: testContext)
        
        let reminders = try await assistant.generatePersonalizedReminders(for: .today)
        
        XCTAssertFalse(reminders.isEmpty)
        XCTAssertTrue(reminders.allSatisfy { $0.timeframe == .today })
    }
    
    func testDailyAdvice() async throws {
        let assistant = MovingNotesAssistant(viewContext: testContext)
        
        let advice = try await assistant.generateDailyAdvice()
        
        XCTAssertFalse(advice.isEmpty)
        XCTAssertTrue(advice.count > 20) // Sollte substantieller Rat sein
    }
    
    func testProgressAnalysis() async throws {
        let assistant = MovingNotesAssistant(viewContext: testContext)
        
        let analysis = try await assistant.analyzeProgressAndSuggest()
        
        XCTAssertFalse(analysis.overallStatus.isEmpty)
        XCTAssertGreaterThanOrEqual(analysis.completionPercentage, 0.0)
        XCTAssertLessThanOrEqual(analysis.completionPercentage, 1.0)
    }
    
    func testEmergencyAssistance() async throws {
        let assistant = MovingNotesAssistant(viewContext: testContext)
        
        let assistance = try await assistant.generateEmergencyAssistance(problem: .packingDelay)
        
        XCTAssertEqual(assistance.problem, .packingDelay)
        XCTAssertFalse(assistance.solutions.isEmpty)
        XCTAssertFalse(assistance.resources.isEmpty)
        XCTAssertGreaterThan(assistance.timeEstimate, 0)
    }
    
    func testSituationalChecklist() async throws {
        let assistant = MovingNotesAssistant(viewContext: testContext)
        
        let checklist = try await assistant.generateSituationalChecklist(situation: .firstTimeMove)
        
        XCTAssertEqual(checklist.situation, .firstTimeMove)
        XCTAssertFalse(checklist.items.isEmpty)
        XCTAssertGreaterThan(checklist.estimatedTotalTime, 0)
    }
    
    func testWeatherBasedAdvice() async throws {
        let assistant = MovingNotesAssistant(viewContext: testContext)
        
        let tips = try await assistant.generateWeatherBasedAdvice(
            weatherCondition: .rainy,
            movingDate: Date()
        )
        
        XCTAssertFalse(tips.isEmpty)
        XCTAssertTrue(tips.allSatisfy { $0.weatherCondition == .rainy })
    }
}

// MARK: - Integration Tests

extension AIServicesTests {
    
    func testAIServicesIntegration() async throws {
        // Test dass alle Services zusammenarbeiten können
        let packingService = AIPackingSuggestionService()
        let labelingService = AILabelingService()
        let searchService = SmartSearchService(viewContext: testContext)
        
        // Generiere Packvorschläge
        let suggestions = try await packingService.generatePackingSuggestions(for: testBox)
        XCTAssertFalse(suggestions.isEmpty)
        
        // Generiere Labels
        let label = try await labelingService.generateSmartLabel(for: testBox)
        XCTAssertFalse(label.mainText.isEmpty)
        
        // Führe Suche durch
        let searchResults = try await searchService.performSmartSearch(query: "Laptop")
        XCTAssertFalse(searchResults.isEmpty)
        
        // Alle Services sollten ohne Konflikte funktionieren
    }
    
    func testPerformanceWithLargeDataset() async throws {
        // Erstelle größeren Datensatz
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 1...50 {
            let item = Item(context: testContext)
            item.name = "Test Item \(i)"
            item.category = ItemCategory.allCases.randomElement()?.rawValue ?? "other"
            item.box = testBox
        }
        
        let searchService = SmartSearchService(viewContext: testContext)
        let results = try await searchService.performSmartSearch(query: "Test")
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Suche sollte unter 2 Sekunden dauern
        XCTAssertLessThan(timeElapsed, 2.0)
        XCTAssertGreaterThanOrEqual(results.count, 50)
    }
}

// MARK: - Error Handling Tests

extension AIServicesTests {
    
    func testErrorHandlingForInvalidInput() async throws {
        let packingService = AIPackingSuggestionService()
        
        // Test mit leerer Box
        let emptyBox = Box(context: testContext)
        emptyBox.name = "Empty Box"
        
        do {
            _ = try await packingService.generatePackingSuggestions(for: emptyBox)
            XCTFail("Should throw error for empty box")
        } catch {
            XCTAssertTrue(error is PackingError)
        }
    }
    
    func testSearchWithEmptyQuery() async throws {
        let searchService = SmartSearchService(viewContext: testContext)
        
        let results = try await searchService.performSmartSearch(query: "")
        XCTAssertTrue(results.isEmpty)
    }
    
    func testLabelingWithInvalidData() async throws {
        let labelingService = AILabelingService()
        
        let emptyBox = Box(context: testContext)
        emptyBox.name = "Empty Box"
        
        do {
            _ = try await labelingService.generateSmartLabel(for: emptyBox)
            XCTFail("Should throw error for empty box")
        } catch {
            XCTAssertTrue(error is LabelingError)
        }
    }
}