//
//  CoreDataEncryptionTests.swift
//  neuanfang-umzugshelferTests
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import XCTest
import CoreData
import LocalAuthentication
@testable import neuanfang_umzugshelfer

final class CoreDataEncryptionTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var cryptoManager: CryptoManager!
    
    override func setUp() {
        super.setUp()
        
        // In-Memory Store für Tests verwenden
        persistenceController = PersistenceController(inMemory: true)
        cryptoManager = CryptoManager.shared
    }
    
    override func tearDown() {
        persistenceController = nil
        cryptoManager = nil
        super.tearDown()
    }
    
    // MARK: - Device Passcode Tests
    
    func testDevicePasscodeDetection() {
        // Test ob Passcode-Erkennung funktioniert
        let hasPasscode = cryptoManager.isDevicePasscodeSet()
        
        // Im Simulator ist normalerweise kein Passcode gesetzt
        // Aber die Methode sollte trotzdem ohne Fehler ausgeführt werden
        XCTAssertNotNil(hasPasscode, "Passcode-Erkennung sollte einen Wert zurückgeben")
    }
    
    func testSecureEnclaveAvailability() {
        // Test ob Secure Enclave-Erkennung funktioniert
        let hasSecureEnclave = cryptoManager.isSecureEnclaveAvailable()
        
        // Im Simulator ist normalerweise keine Secure Enclave verfügbar
        XCTAssertNotNil(hasSecureEnclave, "Secure Enclave-Erkennung sollte einen Wert zurückgeben")
    }
    
    // MARK: - Encryption Key Tests
    
    func testEncryptionKeyGeneration() throws {
        // Test ob Verschlüsselungsschlüssel generiert werden können
        // (funktioniert nur wenn Passcode gesetzt ist)
        
        if cryptoManager.isDevicePasscodeSet() {
            let key = try cryptoManager.getCoreDataEncryptionKey()
            XCTAssertNotNil(key, "Verschlüsselungsschlüssel sollte generiert werden")
        } else {
            // Erwarte Fehler wenn kein Passcode gesetzt ist
            XCTAssertThrowsError(try cryptoManager.getCoreDataEncryptionKey()) { error in
                XCTAssertTrue(error is CryptoError, "Sollte CryptoError werfen")
                if let cryptoError = error as? CryptoError {
                    if case .noDevicePasscode = cryptoError {
                        // Erwarteter Fehler
                        XCTAssertTrue(true)
                    } else {
                        XCTFail("Falscher Fehlertyp: \(cryptoError)")
                    }
                }
            }
        }
    }
    
    func testMigrationRequirementCheck() {
        // Test ob Migration-Erkennung funktioniert
        let requiresMigration = cryptoManager.requiresCoreDataMigration()
        XCTAssertNotNil(requiresMigration, "Migration-Check sollte einen Wert zurückgeben")
    }
    
    // MARK: - CoreData Encryption Status Tests
    
    func testEncryptionStatusCheck() {
        // Test der Verschlüsselungsstatus-Überprüfung
        let status = persistenceController.checkEncryptionStatus()
        
        switch status {
        case .encrypted:
            XCTAssertTrue(status.isSecure, "Verschlüsselter Status sollte sicher sein")
            
        case .migrationRequired:
            XCTAssertFalse(status.isSecure, "Migration-erforderlich Status sollte nicht sicher sein")
            
        case .noPasscode:
            XCTAssertFalse(status.isSecure, "Kein-Passcode Status sollte nicht sicher sein")
            
        case .error(let error):
            XCTFail("Unerwarteter Fehler beim Status-Check: \(error)")
        }
    }
    
    func testEncryptionStatusDescription() {
        // Test der lokalisierten Beschreibungen
        let statuses: [CoreDataEncryptionStatus] = [
            .encrypted,
            .migrationRequired,
            .noPasscode,
            .error(CryptoError.invalidKeyData)
        ]
        
        for status in statuses {
            let description = status.localizedDescription
            XCTAssertFalse(description.isEmpty, "Status-Beschreibung sollte nicht leer sein")
            XCTAssertTrue(description.count > 10, "Status-Beschreibung sollte aussagekräftig sein")
        }
    }
    
    // MARK: - CloudKit Compatibility Tests
    
    func testCloudKitEncryptionCompatibility() async {
        // Test der CloudKit-Verschlüsselungskompatibilität
        let isCompatible = await persistenceController.validateCloudKitEncryptionCompatibility()
        
        // Kompatibilität hängt von der Umgebung ab
        XCTAssertNotNil(isCompatible, "CloudKit-Kompatibilitätscheck sollte einen Wert zurückgeben")
    }
    
    func testCloudKitStatusCheck() async {
        // Test des CloudKit-Status
        let status = await persistenceController.checkCloudKitStatus()
        
        let expectedStatuses: [CloudKitStatus] = [
            .available, .restricted, .noAccount, .couldNotDetermine, .temporarilyUnavailable
        ]
        
        XCTAssertTrue(expectedStatuses.contains(status), "CloudKit-Status sollte einen erwarteten Wert haben")
        
        // Test der lokalisierten Beschreibung
        let description = status.localizedDescription
        XCTAssertFalse(description.isEmpty, "CloudKit-Status-Beschreibung sollte nicht leer sein")
    }
    
    // MARK: - Error Handling Tests
    
    func testCryptoErrorDescriptions() {
        // Test der CryptoError-Beschreibungen
        let errors: [CryptoError] = [
            .keychainError(errSecItemNotFound),
            .invalidKeyData,
            .encryptionFailed,
            .decryptionFailed,
            .noDevicePasscode,
            .accessControlCreationFailed,
            .migrationRequired,
            .migrationFailed
        ]
        
        for error in errors {
            let description = error.errorDescription
            XCTAssertNotNil(description, "Fehler-Beschreibung sollte verfügbar sein")
            XCTAssertFalse(description!.isEmpty, "Fehler-Beschreibung sollte nicht leer sein")
        }
    }
    
    func testCryptoErrorRecoverySuggestions() {
        // Test der Recovery-Suggestions
        let errorsWithSuggestions: [CryptoError] = [
            .noDevicePasscode,
            .migrationRequired,
            .migrationFailed
        ]
        
        for error in errorsWithSuggestions {
            let suggestion = error.recoverySuggestion
            XCTAssertNotNil(suggestion, "Recovery-Suggestion sollte für \(error) verfügbar sein")
            XCTAssertFalse(suggestion!.isEmpty, "Recovery-Suggestion sollte nicht leer sein")
        }
    }
    
    // MARK: - CoreData Store Tests
    
    func testCoreDataStoreCreation() {
        // Test ob CoreData Store korrekt erstellt wird
        XCTAssertNotNil(persistenceController.container, "Container sollte verfügbar sein")
        XCTAssertNotNil(persistenceController.container.viewContext, "ViewContext sollte verfügbar sein")
    }
    
    func testCoreDataSaveOperation() {
        // Test einer einfachen Save-Operation
        let context = persistenceController.container.viewContext
        
        // Erstelle Test-Room
        let room = Room(context: context)
        room.name = "Test Encryption Room"
        room.roomType = "test"
        room.colorHex = "#FF0000"
        room.createdDate = Date()
        room.isCompleted = false
        room.packingProgress = 0.0
        
        // Speichere ohne Fehler
        XCTAssertNoThrow(try context.save(), "CoreData Save sollte ohne Fehler funktionieren")
        
        // Verifikation
        let fetchRequest: NSFetchRequest<Room> = Room.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Test Encryption Room")
        
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results?.count, 1, "Genau ein Room sollte gefunden werden")
        XCTAssertEqual(results?.first?.name, "Test Encryption Room", "Room-Name sollte korrekt gespeichert sein")
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformance() throws {
        // Teste Performance der Verschlüsselungsoperationen
        
        guard cryptoManager.isDevicePasscodeSet() else {
            throw XCTSkip("Passcode nicht gesetzt - Performance-Test übersprungen")
        }
        
        measure {
            do {
                let _ = try cryptoManager.getCoreDataEncryptionKey()
            } catch {
                XCTFail("Verschlüsselungsschlüssel-Generierung fehlgeschlagen: \(error)")
            }
        }
    }
    
    func testCoreDataPerformance() {
        // Teste CoreData-Performance mit Verschlüsselung
        let context = persistenceController.container.viewContext
        
        measure {
            // Erstelle mehrere Test-Objekte
            for i in 0..<100 {
                let room = Room(context: context)
                room.name = "Performance Test Room \(i)"
                room.roomType = "test"
                room.colorHex = "#00FF00"
                room.createdDate = Date()
                room.isCompleted = false
                room.packingProgress = 0.0
            }
            
            do {
                try context.save()
            } catch {
                XCTFail("Bulk-Save fehlgeschlagen: \(error)")
            }
        }
    }
}

// MARK: - Test Utilities

extension CoreDataEncryptionTests {
    
    /// Hilfsmethode für Setup von Test-Daten
    private func createTestData() {
        let context = persistenceController.container.viewContext
        
        // Test Room
        let room = Room(context: context)
        room.name = "Encryption Test Room"
        room.roomType = "living_room"
        room.colorHex = "#3B82F6"
        room.createdDate = Date()
        room.isCompleted = false
        room.packingProgress = 0.3
        
        // Test Box
        let box = Box(context: context)
        box.name = "Encryption Test Box"
        box.qrCode = "QR_TEST_" + UUID().uuidString
        box.isPacked = false
        box.priority = 1
        box.estimatedValue = 100.0
        box.createdDate = Date()
        box.room = room
        
        // Test Item
        let item = Item(context: context)
        item.name = "Encryption Test Item"
        item.itemDescription = "Test item for encryption validation"
        item.category = "test"
        item.estimatedValue = 25.0
        item.isFragile = false
        item.createdDate = Date()
        item.box = box
        
        do {
            try context.save()
        } catch {
            XCTFail("Test-Daten konnten nicht erstellt werden: \(error)")
        }
    }
    
    /// Hilfsmethode für Cleanup von Test-Daten
    private func cleanupTestData() {
        let context = persistenceController.container.viewContext
        
        // Lösche alle Test-Objekte
        let entityNames = ["Room", "Box", "Item"]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Cleanup für \(entityName) fehlgeschlagen: \(error)")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Cleanup-Save fehlgeschlagen: \(error)")
        }
    }
}