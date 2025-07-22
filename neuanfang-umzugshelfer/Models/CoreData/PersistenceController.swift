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

struct PersistenceController {
    static let shared = PersistenceController()
    
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
            storeDescription?.setOption("iCloud.com.neuanfang.umzugshelfer" as NSString,
                                      forKey: NSPersistentCloudKitContainerApplicationBundleIdentifierKey)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // This is a serious application error. In a real app, you should handle this properly.
                fatalError("Unresolved error \(error), \(error.userInfo)")
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
        // Handle remote changes from CloudKit
        do {
            // Process any pending history transactions
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
            print("Failed to process remote changes: \(error)")
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
        let container = CKContainer(identifier: "iCloud.com.neuanfang.umzugshelfer")
        
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