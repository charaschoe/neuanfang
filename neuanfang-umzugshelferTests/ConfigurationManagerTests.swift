//
//  ConfigurationManagerTests.swift
//  neuanfang-umzugshelferTests
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import XCTest
@testable import neuanfang_umzugshelfer

final class ConfigurationManagerTests: XCTestCase {
    
    var configurationManager: ConfigurationManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        configurationManager = ConfigurationManager.shared
    }
    
    override func tearDownWithError() throws {
        configurationManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - CloudKit Configuration Tests
    
    func testCloudKitContainerIdentifier() throws {
        // Given
        let expectedContainerID = "iCloud.com.neuanfang.umzugshelfer"
        
        // When
        let actualContainerID = configurationManager.cloudKitContainerIdentifier
        
        // Then
        XCTAssertEqual(actualContainerID, expectedContainerID, "CloudKit Container ID sollte korrekt geladen werden")
        XCTAssertTrue(actualContainerID.hasPrefix("iCloud."), "Container ID sollte mit 'iCloud.' beginnen")
        XCTAssertFalse(actualContainerID.isEmpty, "Container ID sollte nicht leer sein")
    }
    
    func testCloudKitEnvironment() throws {
        // Given
        let expectedEnvironment = "production"
        
        // When
        let actualEnvironment = configurationManager.cloudKitEnvironment
        
        // Then
        XCTAssertEqual(actualEnvironment, expectedEnvironment, "CloudKit Environment sollte 'production' sein")
        XCTAssertTrue(["production", "development"].contains(actualEnvironment), "Environment sollte gültig sein")
    }
    
    func testCloudKitBatchSize() throws {
        // Given
        let expectedBatchSize = 50
        
        // When
        let actualBatchSize = configurationManager.cloudKitBatchSize
        
        // Then
        XCTAssertEqual(actualBatchSize, expectedBatchSize, "CloudKit Batch Size sollte 50 sein")
        XCTAssertGreaterThan(actualBatchSize, 0, "Batch Size sollte größer als 0 sein")
        XCTAssertLessThanOrEqual(actualBatchSize, 1000, "Batch Size sollte angemessen sein")
    }
    
    func testCloudKitSyncTimeout() throws {
        // Given
        let expectedTimeout = 30
        
        // When
        let actualTimeout = configurationManager.cloudKitSyncTimeout
        
        // Then
        XCTAssertEqual(actualTimeout, expectedTimeout, "CloudKit Sync Timeout sollte 30 Sekunden sein")
        XCTAssertGreaterThan(actualTimeout, 0, "Timeout sollte größer als 0 sein")
    }
    
    // MARK: - App Configuration Tests
    
    func testAppVersion() throws {
        // Given
        let expectedVersion = "1.0.0"
        
        // When
        let actualVersion = configurationManager.appVersion
        
        // Then
        XCTAssertEqual(actualVersion, expectedVersion, "App Version sollte korrekt geladen werden")
        XCTAssertFalse(actualVersion.isEmpty, "App Version sollte nicht leer sein")
        
        // Validiere Semantic Versioning Format
        let versionPattern = #"^\d+\.\d+\.\d+$"#
        let regex = try NSRegularExpression(pattern: versionPattern)
        let range = NSRange(location: 0, length: actualVersion.utf16.count)
        XCTAssertNotNil(regex.firstMatch(in: actualVersion, range: range), "Version sollte SemVer Format folgen")
    }
    
    func testAppBuild() throws {
        // Given
        let expectedBuild = "1"
        
        // When
        let actualBuild = configurationManager.appBuild
        
        // Then
        XCTAssertEqual(actualBuild, expectedBuild, "App Build sollte korrekt geladen werden")
        XCTAssertFalse(actualBuild.isEmpty, "App Build sollte nicht leer sein")
    }
    
    func testMinimumIOSVersion() throws {
        // Given
        let expectedMinVersion = "15.0"
        
        // When
        let actualMinVersion = configurationManager.minimumIOSVersion
        
        // Then
        XCTAssertEqual(actualMinVersion, expectedMinVersion, "Minimum iOS Version sollte korrekt geladen werden")
        XCTAssertFalse(actualMinVersion.isEmpty, "Minimum iOS Version sollte nicht leer sein")
    }
    
    // MARK: - Security Configuration Tests
    
    func testEncryptionEnabled() throws {
        // When
        let isEncryptionEnabled = configurationManager.isEncryptionEnabled
        
        // Then
        XCTAssertTrue(isEncryptionEnabled, "Verschlüsselung sollte standardmäßig aktiviert sein")
    }
    
    func testFileProtectionLevel() throws {
        // Given
        let expectedProtectionLevel = "complete"
        
        // When
        let actualProtectionLevel = configurationManager.fileProtectionLevel
        
        // Then
        XCTAssertEqual(actualProtectionLevel, expectedProtectionLevel, "File Protection Level sollte 'complete' sein")
        XCTAssertTrue(["complete", "completeUnlessOpen", "completeUntilFirstUserAuthentication", "none"].contains(actualProtectionLevel), "Protection Level sollte gültig sein")
    }
    
    func testCloudKitEncryptionEnabled() throws {
        // When
        let isCloudKitEncryptionEnabled = configurationManager.isCloudKitEncryptionEnabled
        
        // Then
        XCTAssertTrue(isCloudKitEncryptionEnabled, "CloudKit Verschlüsselung sollte standardmäßig aktiviert sein")
    }
    
    // MARK: - Development Configuration Tests
    
    func testDebugLoggingEnabled() throws {
        // When
        let isDebugLoggingEnabled = configurationManager.isDebugLoggingEnabled
        
        // Then
        // In Production sollte Debug Logging deaktiviert sein
        XCTAssertFalse(isDebugLoggingEnabled, "Debug Logging sollte in Production deaktiviert sein")
    }
    
    func testTestModeEnabled() throws {
        // When
        let isTestModeEnabled = configurationManager.isTestModeEnabled
        
        // Then
        // Test Mode sollte standardmäßig deaktiviert sein
        XCTAssertFalse(isTestModeEnabled, "Test Mode sollte standardmäßig deaktiviert sein")
    }
    
    // MARK: - Configuration Summary Tests
    
    func testConfigurationSummary() throws {
        // When
        let summary = configurationManager.getConfigurationSummary()
        
        // Then
        XCTAssertNotNil(summary["CloudKit"], "CloudKit Konfiguration sollte in Summary enthalten sein")
        XCTAssertNotNil(summary["App"], "App Konfiguration sollte in Summary enthalten sein")
        XCTAssertNotNil(summary["Security"], "Security Konfiguration sollte in Summary enthalten sein")
        XCTAssertNotNil(summary["Development"], "Development Konfiguration sollte in Summary enthalten sein")
        
        // Validiere CloudKit Section
        if let cloudKitConfig = summary["CloudKit"] as? [String: Any] {
            XCTAssertNotNil(cloudKitConfig["ContainerIdentifier"], "CloudKit Container ID sollte in Summary enthalten sein")
            XCTAssertNotNil(cloudKitConfig["Environment"], "CloudKit Environment sollte in Summary enthalten sein")
            XCTAssertNotNil(cloudKitConfig["BatchSize"], "CloudKit Batch Size sollte in Summary enthalten sein")
            XCTAssertNotNil(cloudKitConfig["SyncTimeout"], "CloudKit Sync Timeout sollte in Summary enthalten sein")
        } else {
            XCTFail("CloudKit Konfiguration sollte Dictionary sein")
        }
    }
    
    // MARK: - Configuration Update Tests (Development/Testing)
    
    func testConfigurationUpdateInTestMode() throws {
        // Given
        let testUpdates: [String: Any] = [
            "Development": [
                "TestMode": true,
                "DebugLogging": true
            ]
        ]
        
        // Aktiviere Test Mode
        configurationManager.updateConfiguration([
            "Development": [
                "TestMode": true,
                "DebugLogging": false
            ]
        ])
        
        // When
        configurationManager.updateConfiguration(testUpdates)
        
        // Then
        XCTAssertTrue(configurationManager.isTestModeEnabled, "Test Mode sollte nach Update aktiviert sein")
        XCTAssertTrue(configurationManager.isDebugLoggingEnabled, "Debug Logging sollte nach Update aktiviert sein")
    }
    
    func testConfigurationReload() throws {
        // Given
        let originalContainerID = configurationManager.cloudKitContainerIdentifier
        
        // When
        configurationManager.reloadConfiguration()
        
        // Then
        let reloadedContainerID = configurationManager.cloudKitContainerIdentifier
        XCTAssertEqual(originalContainerID, reloadedContainerID, "Container ID sollte nach Reload gleich bleiben")
    }
    
    // MARK: - Error Handling Tests
    
    func testSingletonPattern() throws {
        // Given
        let instance1 = ConfigurationManager.shared
        let instance2 = ConfigurationManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "ConfigurationManager sollte Singleton Pattern verwenden")
    }
    
    // MARK: - Performance Tests
    
    func testConfigurationPerformance() throws {
        // Given
        let iterations = 1000
        
        // When & Then
        measure {
            for _ in 0..<iterations {
                _ = configurationManager.cloudKitContainerIdentifier
                _ = configurationManager.cloudKitEnvironment
                _ = configurationManager.isEncryptionEnabled
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCloudKitServiceIntegration() throws {
        // Given
        let cloudKitService = CloudKitService.shared
        
        // When
        // CloudKitService sollte ConfigurationManager verwenden
        // Dieser Test validiert die Integration indirekt
        
        // Then
        XCTAssertNotNil(cloudKitService, "CloudKitService sollte initialisiert werden können")
        
        // Validiere, dass keine hardcoded Container-ID mehr verwendet wird
        let containerIdentifier = configurationManager.cloudKitContainerIdentifier
        XCTAssertEqual(containerIdentifier, "iCloud.com.neuanfang.umzugshelfer", "Container ID sollte aus Konfiguration stammen")
    }
    
    func testPersistenceControllerIntegration() throws {
        // Given
        let persistenceController = PersistenceController.shared
        
        // When
        // PersistenceController sollte ConfigurationManager verwenden
        
        // Then
        XCTAssertNotNil(persistenceController, "PersistenceController sollte initialisiert werden können")
        XCTAssertNotNil(persistenceController.container, "CoreData Container sollte verfügbar sein")
    }
}

// MARK: - Test Extensions

extension ConfigurationManagerTests {
    
    /// Testet Konfigurationswerte gegen erwartete Standards
    func validateConfigurationStandards() {
        // CloudKit Standards
        XCTAssertTrue(configurationManager.cloudKitContainerIdentifier.hasPrefix("iCloud."))
        XCTAssertTrue(["production", "development"].contains(configurationManager.cloudKitEnvironment))
        XCTAssertGreaterThan(configurationManager.cloudKitBatchSize, 0)
        XCTAssertGreaterThan(configurationManager.cloudKitSyncTimeout, 0)
        
        // Security Standards
        XCTAssertTrue(configurationManager.isEncryptionEnabled)
        XCTAssertTrue(configurationManager.isCloudKitEncryptionEnabled)
        XCTAssertTrue(["complete", "completeUnlessOpen"].contains(configurationManager.fileProtectionLevel))
        
        // Production Standards
        XCTAssertFalse(configurationManager.isDebugLoggingEnabled)
        XCTAssertFalse(configurationManager.isTestModeEnabled)
    }
}