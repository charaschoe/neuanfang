//
//  CloudKitService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import CloudKit
import SwiftUI
import Combine

@MainActor
final class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var cloudKitStatus: CloudKitStatus = .couldNotDetermine
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    
    private let container = CKContainer(identifier: "iCloud.com.neuanfang.umzugshelfer")
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
        
        var description: String {
            switch self {
            case .idle:
                return "Bereit"
            case .syncing:
                return "Synchronisiert..."
            case .success:
                return "Erfolgreich synchronisiert"
            case .failed(let error):
                return "Fehler: \(error.localizedDescription)"
            }
        }
        
        var isError: Bool {
            if case .failed = self { return true }
            return false
        }
    }
    
    private init() {
        self.database = container.privateCloudDatabase
        setupNotifications()
    }
    
    func initializeCloudKit() async {
        await checkAccountStatus()
        await setupSubscriptions()
    }
    
    private func setupNotifications() {
        // Listen for CloudKit notifications
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task {
                    await self?.checkAccountStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            
            switch status {
            case .available:
                cloudKitStatus = .available
                errorMessage = nil
            case .noAccount:
                cloudKitStatus = .noAccount
                errorMessage = "Bitte melden Sie sich bei iCloud an, um Ihre Daten zu synchronisieren."
            case .restricted:
                cloudKitStatus = .restricted
                errorMessage = "iCloud ist auf diesem Gerät eingeschränkt."
            case .couldNotDetermine:
                cloudKitStatus = .couldNotDetermine
                errorMessage = "CloudKit-Status konnte nicht ermittelt werden."
            case .temporarilyUnavailable:
                cloudKitStatus = .temporarilyUnavailable
                errorMessage = "iCloud ist vorübergehend nicht verfügbar."
            @unknown default:
                cloudKitStatus = .couldNotDetermine
                errorMessage = "Unbekannter iCloud-Status."
            }
        } catch {
            cloudKitStatus = .couldNotDetermine
            errorMessage = "Fehler beim Überprüfen des iCloud-Status: \(error.localizedDescription)"
        }
    }
    
    private func setupSubscriptions() async {
        guard cloudKitStatus == .available else { return }
        
        do {
            // Create subscriptions for real-time updates
            let roomSubscription = CKQuerySubscription(
                recordType: "CD_Room",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            
            let boxSubscription = CKQuerySubscription(
                recordType: "CD_Box",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            
            let itemSubscription = CKQuerySubscription(
                recordType: "CD_Item",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            
            // Save subscriptions
            let subscriptions = [roomSubscription, boxSubscription, itemSubscription]
            try await database.modifySubscriptions(saving: subscriptions, deleting: [])
            
        } catch {
            print("Failed to setup CloudKit subscriptions: \(error)")
        }
    }
    
    func syncData() async {
        guard cloudKitStatus == .available else {
            syncStatus = .failed(CloudKitError.accountNotAvailable)
            return
        }
        
        syncStatus = .syncing
        
        do {
            // Fetch changes from CloudKit
            try await fetchRemoteChanges()
            
            // Update sync status
            syncStatus = .success
            lastSyncDate = Date()
            
        } catch {
            syncStatus = .failed(error)
            print("Sync failed: \(error)")
        }
    }
    
    private func fetchRemoteChanges() async throws {
        // Implement fetching remote changes from CloudKit
        let roomQuery = CKQuery(recordType: "CD_Room", predicate: NSPredicate(value: true))
        let boxQuery = CKQuery(recordType: "CD_Box", predicate: NSPredicate(value: true))
        let itemQuery = CKQuery(recordType: "CD_Item", predicate: NSPredicate(value: true))
        
        // Fetch rooms
        let roomResults = try await database.records(matching: roomQuery)
        print("Fetched \(roomResults.matchResults.count) rooms from CloudKit")
        
        // Fetch boxes
        let boxResults = try await database.records(matching: boxQuery)
        print("Fetched \(boxResults.matchResults.count) boxes from CloudKit")
        
        // Fetch items
        let itemResults = try await database.records(matching: itemQuery)
        print("Fetched \(itemResults.matchResults.count) items from CloudKit")
        
        // Process and merge with local data
        // This would typically involve updating Core Data entities
    }
    
    func shareRoom(_ room: Room) async throws -> CKShare {
        guard cloudKitStatus == .available else {
            throw CloudKitError.accountNotAvailable
        }
        
        // Create CloudKit share for collaborative room
        let share = CKShare(rootRecord: try await getCloudKitRecord(for: room))
        share[CKShare.SystemFieldKey.title] = "Raum: \(room.name ?? "Unbekannt")" as CKRecordValue
        share[CKShare.SystemFieldKey.shareType] = "com.neuanfang.umzugshelfer.room" as CKRecordValue
        
        // Set permissions
        share.publicPermission = .none
        share.participants.forEach { participant in
            participant.permission = .readWrite
            participant.role = .privateUser
        }
        
        try await database.modifyRecords(saving: [share], deleting: [])
        return share
    }
    
    private func getCloudKitRecord(for room: Room) async throws -> CKRecord {
        // Convert Core Data entity to CloudKit record
        // This is a simplified implementation
        let recordID = CKRecord.ID(recordName: room.objectID.uriRepresentation().absoluteString)
        let record = CKRecord(recordType: "CD_Room", recordID: recordID)
        
        record["name"] = room.name as CKRecordValue?
        record["roomType"] = room.roomType as CKRecordValue?
        record["colorHex"] = room.colorHex as CKRecordValue?
        record["isCompleted"] = (room.isCompleted ? 1 : 0) as CKRecordValue
        record["packingProgress"] = room.packingProgress as CKRecordValue
        record["createdDate"] = room.createdDate as CKRecordValue?
        
        return record
    }
    
    func deleteShare(for room: Room) async throws {
        // Implementation for deleting CloudKit shares
        let recordID = CKRecord.ID(recordName: room.objectID.uriRepresentation().absoluteString)
        
        do {
            let record = try await database.record(for: recordID)
            if let shareReference = record.share {
                try await database.deleteRecord(withID: shareReference.recordID)
            }
        } catch {
            print("Failed to delete share: \(error)")
            throw error
        }
    }
    
    func getShareURL(for room: Room) async throws -> URL? {
        let recordID = CKRecord.ID(recordName: room.objectID.uriRepresentation().absoluteString)
        
        do {
            let record = try await database.record(for: recordID)
            if let shareReference = record.share {
                let shareRecord = try await database.record(for: shareReference.recordID) as? CKShare
                return shareRecord?.url
            }
        } catch {
            print("Failed to get share URL: \(error)")
            throw error
        }
        
        return nil
    }
}

// MARK: - CloudKit Errors

enum CloudKitError: LocalizedError {
    case accountNotAvailable
    case networkUnavailable
    case quotaExceeded
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud-Account nicht verfügbar"
        case .networkUnavailable:
            return "Netzwerk nicht verfügbar"
        case .quotaExceeded:
            return "iCloud-Speicher voll"
        case .syncFailed:
            return "Synchronisation fehlgeschlagen"
        }
    }
}

// MARK: - CloudKit Notification Extensions

extension Notification.Name {
    static let CKAccountChanged = NSNotification.Name.CKAccountChanged
}

// MARK: - CloudKit Status from PersistenceController

extension CloudKitService {
    var persistenceCloudKitStatus: CloudKitStatus {
        switch cloudKitStatus {
        case .available: return .available
        case .restricted: return .restricted
        case .noAccount: return .noAccount
        case .couldNotDetermine: return .couldNotDetermine
        case .temporarilyUnavailable: return .temporarilyUnavailable
        }
    }
}