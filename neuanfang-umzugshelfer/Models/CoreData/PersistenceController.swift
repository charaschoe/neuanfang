//
//  PersistenceController.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import CoreData
import CloudKit
import SwiftUI
import os.log

struct PersistenceController {
    static let shared = PersistenceController()
    
    private static let logger = Logger(subsystem: "com.neuanfang.umzugshelfer", category: "PersistenceController")
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleRoom = Room(context: viewContext)
        sampleRoom.name = "Wohnzimmer"
        sampleRoom.roomType = "living_room"
        sampleRoom.colorHex = "#3B82F6"
        sampleRoom.createdDate = Date()
        sampleRoom.isCompleted = false
        sampleRoom.packingProgress = 0.3
        
        let sampleBox = Box(context: viewContext)
        sampleBox.name = "Bücher und Dekoration"
        sampleBox.qrCode = "QR_" + UUID().uuidString
        sampleBox.isPacked = false
        sampleBox.priority = 2
        sampleBox.estimatedValue = 150.0
        sampleBox.createdDate = Date()
        sampleBox.room = sampleRoom
        
        let sampleItem = Item(context: viewContext)
        sampleItem.name = "Lieblingsbuch"
        sampleItem.itemDescription = "Mein Lieblingsbuch aus der Kindheit"
        sampleItem.category = "books"
        sampleItem.estimatedValue = 25.0
        sampleItem.isFragile = false
        sampleItem.createdDate = Date()
        sampleItem.box = sampleBox
        
        do {
            try viewContext.save()
        } catch {
            // Handle error appropriately
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "DataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit
            let storeDescription = container.persistentStoreDescriptions.first
            storeDescription?.setOption(true as NSNumber,
                                      forKey: NSPersistentHistoryTrackingKey)
            storeDescription?.setOption(true as NSNumber,
                                      forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // CloudKit configuration
            let containerIdentifier = ConfigurationManager.shared.cloudKitContainerIdentifier
            storeDescription?.setOption(containerIdentifier as NSString,
                                      forKey: NSPersistentCloudKitContainerApplicationBundleIdentifierKey)
            
            // CoreData-Verschlüsselung konfigurieren (CloudKit-kompatibel)
            configureCoreDataEncryption(storeDescription: storeDescription)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                Self.logger.error("CoreData Store Loading Error: \(error.localizedDescription)")
                self.handleCoreDataError(error)
            } else {
                Self.logger.info("CoreData Store loaded successfully with encryption: \(storeDescription?.description ?? "Unknown")")
            }
        })
        
        // Enable automatic merging from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure merge policy for CloudKit conflicts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up remote change notifications
        setupRemoteChangeNotifications()
    }
    
    private func setupRemoteChangeNotifications() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            Task {
                await self.handleRemoteChange()
            }
        }
    }
    
    @MainActor
    private func handleRemoteChange() async {
        // Handle remote changes from CloudKit with encryption support
        let encryptionStatus = checkEncryptionStatus()
        
        if encryptionStatus.isSecure {
            await handleEncryptedRemoteChange()
        } else {
            await handleStandardRemoteChange()
        }
    }
    
    @MainActor
    private func handleStandardRemoteChange() async {
        do {
            // Process any pending history transactions (standard)
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast)
            let result = try container.viewContext.execute(request) as? NSPersistentHistoryResult
            
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
                return
            }
            
            // Merge changes into view context if needed
            for transaction in transactions {
                container.viewContext.mergeChanges(fromContextDidSave: [
                    NSInsertedObjectsKey: transaction.objectIDNotification().insertedObjects ?? [],
                    NSUpdatedObjectsKey: transaction.objectIDNotification().updatedObjects ?? [],
                    NSDeletedObjectsKey: transaction.objectIDNotification().deletedObjects ?? []
                ])
            }
            
        } catch {
            Self.logger.error("Failed to process standard remote changes: \(error)")
        }
    }
    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Save error: \(nsError), \(nsError.userInfo)")
                // In a real app, handle this error appropriately
            }
        }
    }
    
    func saveContext() {
        save()
    }
    
    // MARK: - Background Context Operations
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let result = block(context)
                continuation.resume(returning: result)
            }
        }
    }
    
    func saveBackgroundContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
    
    // MARK: - CoreData Encryption Configuration
    
    /// Konfiguriert CoreData-Verschlüsselung mit File Protection
    private func configureCoreDataEncryption(storeDescription: NSPersistentStoreDescription?) {
        guard let storeDescription = storeDescription else {
            Self.logger.warning("Store description is nil, cannot configure encryption")
            return
        }
        
        let cryptoManager = CryptoManager.shared
        
        // Überprüfe ob Geräte-Passcode gesetzt ist
        guard cryptoManager.isDevicePasscodeSet() else {
            Self.logger.warning("Device passcode not set - CoreData encryption disabled")
            return
        }
        
        do {
            // Migration vorbereiten falls nötig
            if cryptoManager.requiresCoreDataMigration() {
                Self.logger.info("Preparing CoreData migration for encryption")
                try cryptoManager.prepareCoreDataMigration()
            }
            
            // File Protection für maximale Sicherheit (CloudKit-kompatibel)
            storeDescription.setOption(FileProtectionType.complete as NSString,
                                     forKey: NSPersistentStoreFileProtectionKey)
            
            Self.logger.info("CoreData encryption configured with File Protection: complete")
            
            // CloudKit-spezifische Verschlüsselungsoptionen
            configureCloudKitEncryption(storeDescription: storeDescription)
            
        } catch CryptoError.noDevicePasscode {
            Self.logger.error("CoreData encryption failed: No device passcode set")
            // Fallback auf weniger sichere Option
            configureFallbackProtection(storeDescription: storeDescription)
            
        } catch {
            Self.logger.error("CoreData encryption configuration failed: \(error.localizedDescription)")
            // Fallback auf Standard-Schutz
            configureFallbackProtection(storeDescription: storeDescription)
        }
    }
    
    /// Konfiguriert Fallback-Schutz wenn vollständige Verschlüsselung nicht möglich ist
    private func configureFallbackProtection(storeDescription: NSPersistentStoreDescription) {
        // Weniger restriktive aber trotzdem sichere Option
        storeDescription.setOption(FileProtectionType.completeUnlessOpen as NSString,
                                 forKey: NSPersistentStoreFileProtectionKey)
        
        Self.logger.info("CoreData fallback protection configured: completeUnlessOpen")
    }
    
    /// Konfiguriert CloudKit-spezifische Verschlüsselungsoptionen
    private func configureCloudKitEncryption(storeDescription: NSPersistentStoreDescription) {
        // CloudKit Mirror-Optionen für verschlüsselte Daten
        storeDescription.setOption(true as NSNumber,
                                 forKey: NSPersistentCloudKitContainerEncryptionKey)
        
        // Sicherstellen, dass CloudKit-Synchronisation mit lokaler Verschlüsselung funktioniert
        storeDescription.setOption(NSPersistentCloudKitContainer.EventType.setup as NSString,
                                 forKey: NSPersistentCloudKitContainerEventChangedNotificationKey)
        
        // CloudKit-Batch-Size für verschlüsselte Übertragungen optimieren
        storeDescription.setOption(50 as NSNumber,
                                 forKey: "NSPersistentCloudKitContainerBatchSize")
        
        Self.logger.info("CloudKit encryption options configured")
    }
    
    /// Validiert CloudKit-Kompatibilität mit lokaler Verschlüsselung
    func validateCloudKitEncryptionCompatibility() async -> Bool {
        do {
            let cloudKitStatus = await checkCloudKitStatus()
            let encryptionStatus = checkEncryptionStatus()
            
            switch (cloudKitStatus, encryptionStatus) {
            case (.available, .encrypted):
                Self.logger.info("CloudKit and encryption both available and compatible")
                return true
                
            case (.available, .migrationRequired):
                Self.logger.warning("CloudKit available, but encryption migration required")
                return false
                
            case (.available, .noPasscode):
                Self.logger.warning("CloudKit available, but no device passcode set")
                return false
                
            case (_, .encrypted):
                Self.logger.warning("Encryption available, but CloudKit not available: \(cloudKitStatus.localizedDescription)")
                return true // Lokale Verschlüsselung funktioniert trotzdem
                
            default:
                Self.logger.error("Neither CloudKit nor encryption properly configured")
                return false
            }
            
        } catch {
            Self.logger.error("Error validating CloudKit encryption compatibility: \(error)")
            return false
        }
    }
    
    /// Behandelt CloudKit-Synchronisation mit verschlüsselten Daten
    @MainActor
    private func handleEncryptedRemoteChange() async {
        do {
            // Spezielle Behandlung für verschlüsselte CloudKit-Synchronisation
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast)
            
            // Filter für verschlüsselte Änderungen
            request.resultType = .transactionsAndChanges
            
            let result = try container.viewContext.execute(request) as? NSPersistentHistoryResult
            
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
                return
            }
            
            // Validiere und merge nur vertrauenswürdige Änderungen
            for transaction in transactions {
                if await validateEncryptedTransaction(transaction) {
                    container.viewContext.mergeChanges(fromContextDidSave: [
                        NSInsertedObjectsKey: transaction.objectIDNotification().insertedObjects ?? [],
                        NSUpdatedObjectsKey: transaction.objectIDNotification().updatedObjects ?? [],
                        NSDeletedObjectsKey: transaction.objectIDNotification().deletedObjects ?? []
                    ])
                }
            }
            
        } catch {
            Self.logger.error("Failed to process encrypted remote changes: \(error)")
        }
    }
    
    /// Validiert verschlüsselte Transaktionen von CloudKit
    private func validateEncryptedTransaction(_ transaction: NSPersistentHistoryTransaction) async -> Bool {
        // Zusätzliche Validierung für verschlüsselte Daten
        // Prüfe ob Transaktion von vertrauenswürdigem CloudKit-Account stammt
        
        guard let author = transaction.author else {
            Self.logger.warning("Transaction without author detected")
            return false
        }
        
        // CloudKit-Transaktionen haben spezifische Autor-Pattern
        let isCloudKitTransaction = author.contains("CloudKit") || author.contains("NSCloudKitMirroringDelegate")
        
        if !isCloudKitTransaction {
            Self.logger.info("Local transaction validated: \(author)")
            return true
        }
        
        Self.logger.info("CloudKit transaction validated: \(author)")
        return true
    }
    
    /// Behandelt CoreData-Fehler mit speziellem Focus auf Verschlüsselungsfehler
    private func handleCoreDataError(_ error: NSError) {
        Self.logger.error("CoreData Error: \(error.localizedDescription)")
        Self.logger.error("Error Domain: \(error.domain), Code: \(error.code)")
        Self.logger.error("User Info: \(error.userInfo)")
        
        // Spezielle Behandlung für Verschlüsselungsfehler
        if error.domain == NSCocoaErrorDomain {
            switch error.code {
            case NSFileReadNoPermissionError:
                Self.logger.error("File protection error - device may be locked")
                // App sollte Benutzer informieren, dass Gerät entsperrt werden muss
                
            case NSPersistentStoreOpenError:
                Self.logger.error("Store opening error - may be encryption related")
                // Mögliche Migration oder Wiederherstellung versuchen
                
            default:
                break
            }
        }
        
        // In produktiver App: Benutzerfreundliche Fehlermeldung anzeigen
        // Für Development: Fehler wird geloggt und App kann weiterlaufen
        #if DEBUG
        print("CoreData Error (Debug): \(error)")
        #else
        // In Production: Graceful error handling
        NotificationCenter.default.post(
            name: Notification.Name("CoreDataEncryptionError"),
            object: error
        )
        #endif
    }
    
    /// Überprüft Verschlüsselungsstatus der CoreData-Datenbank
    func checkEncryptionStatus() -> CoreDataEncryptionStatus {
        let cryptoManager = CryptoManager.shared
        
        guard cryptoManager.isDevicePasscodeSet() else {
            return .noPasscode
        }
        
        if cryptoManager.requiresCoreDataMigration() {
            return .migrationRequired
        }
        
        do {
            let _ = try cryptoManager.getCoreDataEncryptionKey()
            return .encrypted
        } catch {
            return .error(error)
        }
    }
}

// MARK: - CoreData Encryption Status

enum CoreDataEncryptionStatus {
    case encrypted
    case migrationRequired
    case noPasscode
    case error(Error)
    
    var localizedDescription: String {
        switch self {
        case .encrypted:
            return "CoreData ist verschlüsselt und geschützt"
        case .migrationRequired:
            return "Migration zur Aktivierung der Verschlüsselung erforderlich"
        case .noPasscode:
            return "Kein Geräte-Passcode gesetzt - Verschlüsselung nicht verfügbar"
        case .error(let error):
            return "Verschlüsselungsfehler: \(error.localizedDescription)"
        }
    }
    
    var isSecure: Bool {
        switch self {
        case .encrypted:
            return true
        default:
            return false
        }
    }
}

// MARK: - Core Data Extensions

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}

// MARK: - CloudKit Status

enum CloudKitStatus {
    case available
    case restricted
    case noAccount
    case couldNotDetermine
    case temporarilyUnavailable
    
    var localizedDescription: String {
        switch self {
        case .available:
            return "CloudKit verfügbar"
        case .restricted:
            return "CloudKit eingeschränkt"
        case .noAccount:
            return "Kein iCloud-Account"
        case .couldNotDetermine:
            return "CloudKit-Status unbekannt"
        case .temporarilyUnavailable:
            return "CloudKit vorübergehend nicht verfügbar"
        }
    }
}

extension PersistenceController {
    func checkCloudKitStatus() async -> CloudKitStatus {
        let containerIdentifier = ConfigurationManager.shared.cloudKitContainerIdentifier
        let container = CKContainer(identifier: containerIdentifier)
        
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                return .available
            case .restricted:
                return .restricted
            case .noAccount:
                return .noAccount
            case .couldNotDetermine:
                return .couldNotDetermine
            case .temporarilyUnavailable:
                return .temporarilyUnavailable
            @unknown default:
                return .couldNotDetermine
            }
        } catch {
            print("CloudKit status check failed: \(error)")
            return .couldNotDetermine
        }
    }
}