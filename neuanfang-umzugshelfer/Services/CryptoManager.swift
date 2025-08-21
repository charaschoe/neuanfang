//
//  CryptoManager.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CryptoKit
import Security
import LocalAuthentication

/// Manager für NFC-Datenverschlüsselung und CoreData-Verschlüsselung mit AES-256-GCM
final class CryptoManager {
    
    // MARK: - Constants
    
    private static let service = "com.neuanfang.umzugshelfer.nfc-encryption"
    private static let keyLabel = "nfc-encryption-key"
    private static let coreDataKeyLabel = "coredata-encryption-key"
    private static let keySize = 32 // 256 bits für AES-256
    
    // MARK: - Singleton
    
    static let shared = CryptoManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Verschlüsselt die gegebenen Daten mit AES-256-GCM
    /// - Parameter data: Zu verschlüsselnde Daten
    /// - Returns: Verschlüsseltes Datenpaket oder nil bei Fehler
    func encrypt(data: Data) -> EncryptedData? {
        do {
            // Encryption key abrufen oder erstellen
            guard let key = try getOrCreateEncryptionKey() else {
                print("CryptoManager: Fehler beim Abrufen des Verschlüsselungsschlüssels")
                return nil
            }
            
            // Neuen IV generieren
            let iv = AES.GCM.Nonce()
            
            // Daten verschlüsseln
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: iv)
            
            guard let encryptedData = sealedBox.ciphertext,
                  let tag = sealedBox.tag else {
                print("CryptoManager: Fehler beim Extrahieren der verschlüsselten Daten")
                return nil
            }
            
            return EncryptedData(
                encryptedData: encryptedData,
                iv: Data(iv),
                tag: tag
            )
            
        } catch {
            print("CryptoManager: Verschlüsselungsfehler: \(error)")
            return nil
        }
    }
    
    /// Entschlüsselt die gegebenen verschlüsselten Daten
    /// - Parameter encryptedData: Verschlüsselte Daten
    /// - Returns: Entschlüsselte Daten oder nil bei Fehler
    func decrypt(encryptedData: EncryptedData) -> Data? {
        do {
            // Encryption key abrufen
            guard let key = try getOrCreateEncryptionKey() else {
                print("CryptoManager: Fehler beim Abrufen des Verschlüsselungsschlüssels")
                return nil
            }
            
            // Nonce aus IV erstellen
            let nonce = try AES.GCM.Nonce(data: encryptedData.iv)
            
            // SealedBox erstellen
            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: encryptedData.encryptedData,
                tag: encryptedData.tag
            )
            
            // Daten entschlüsseln
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            return decryptedData
            
        } catch {
            print("CryptoManager: Entschlüsselungsfehler: \(error)")
            return nil
        }
    }
    
    /// Erstellt ein verschlüsseltes JSON-Paket für NFC-Tags
    /// - Parameter boxData: BoxShareData zum Verschlüsseln
    /// - Returns: JSON-Data mit verschlüsselten Inhalten
    func createEncryptedNFCPayload(from boxData: BoxShareData) -> Data? {
        do {
            // BoxShareData zu JSON konvertieren
            let jsonData = try JSONEncoder().encode(boxData)
            
            // Daten verschlüsseln
            guard let encryptedData = encrypt(data: jsonData) else {
                print("CryptoManager: Fehler beim Verschlüsseln der BoxShareData")
                return nil
            }
            
            // Verschlüsseltes Paket erstellen
            let encryptedPackage = NFCEncryptedPackage(
                encrypted: true,
                version: 1,
                iv: encryptedData.iv.base64EncodedString(),
                data: encryptedData.encryptedData.base64EncodedString(),
                tag: encryptedData.tag.base64EncodedString()
            )
            
            // Zu JSON konvertieren
            return try JSONEncoder().encode(encryptedPackage)
            
        } catch {
            print("CryptoManager: Fehler beim Erstellen des verschlüsselten NFC-Payloads: \(error)")
            return nil
        }
    }
    
    /// Entschlüsselt ein verschlüsseltes JSON-Paket von NFC-Tags
    /// - Parameter data: Verschlüsselte JSON-Daten
    /// - Returns: BoxShareData oder nil bei Fehler
    func decryptNFCPayload(from data: Data) -> BoxShareData? {
        do {
            // Versuche zuerst, als verschlüsseltes Paket zu parsen
            if let encryptedPackage = try? JSONDecoder().decode(NFCEncryptedPackage.self, from: data) {
                return decryptEncryptedPackage(encryptedPackage)
            }
            
            // Fallback: Versuche als unverschlüsselte BoxShareData zu parsen (Legacy)
            if let boxData = try? JSONDecoder().decode(BoxShareData.self, from: data) {
                print("CryptoManager: Legacy unverschlüsseltes NFC-Tag erkannt")
                return boxData
            }
            
            print("CryptoManager: Unbekanntes NFC-Datenformat")
            return nil
            
        } catch {
            print("CryptoManager: Fehler beim Entschlüsseln des NFC-Payloads: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Ruft den Verschlüsselungsschlüssel aus der Keychain ab oder erstellt einen neuen
    private func getOrCreateEncryptionKey() throws -> SymmetricKey? {
        // Versuche Schlüssel aus Keychain zu laden
        if let existingKey = try loadKeyFromKeychain() {
            return existingKey
        }
        
        // Neuen Schlüssel erstellen und speichern
        let newKey = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(newKey)
        return newKey
    }
    
    /// Lädt den Verschlüsselungsschlüssel aus der Keychain
    private func loadKeyFromKeychain() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.keyLabel,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil // Schlüssel existiert noch nicht
            }
            throw CryptoError.keychainError(status)
        }
        
        guard let keyData = result as? Data else {
            throw CryptoError.invalidKeyData
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Speichert den Verschlüsselungsschlüssel in der Keychain
    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.keyLabel,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw CryptoError.keychainError(status)
        }
    }
    
    /// Entschlüsselt ein verschlüsseltes Paket
    private func decryptEncryptedPackage(_ package: NFCEncryptedPackage) -> BoxShareData? {
        guard package.encrypted else {
            print("CryptoManager: Paket ist als unverschlüsselt markiert")
            return nil
        }
        
        guard package.version == 1 else {
            print("CryptoManager: Nicht unterstützte Verschlüsselungsversion: \(package.version)")
            return nil
        }
        
        // Base64 Daten dekodieren
        guard let ivData = Data(base64Encoded: package.iv),
              let encryptedData = Data(base64Encoded: package.data),
              let tagData = Data(base64Encoded: package.tag) else {
            print("CryptoManager: Fehler beim Dekodieren der Base64-Daten")
            return nil
        }
        
        let encryptedDataPackage = EncryptedData(
            encryptedData: encryptedData,
            iv: ivData,
            tag: tagData
        )
        
        // Entschlüsseln
        guard let decryptedData = decrypt(encryptedData: encryptedDataPackage) else {
            print("CryptoManager: Fehler beim Entschlüsseln der Daten")
            return nil
        }
        
        // BoxShareData parsen
        do {
            return try JSONDecoder().decode(BoxShareData.self, from: decryptedData)
        } catch {
            print("CryptoManager: Fehler beim Parsen der entschlüsselten BoxShareData: \(error)")
            return nil
        }
    }
    
    // MARK: - CoreData Encryption Methods
    
    /// Überprüft ob ein Geräte-Passcode gesetzt ist
    func isDevicePasscodeSet() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    /// Überprüft ob Secure Enclave verfügbar ist
    func isSecureEnclaveAvailable() -> Bool {
        let context = LAContext()
        return context.biometryType != .none || context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    /// Erstellt oder ruft den CoreData-Verschlüsselungsschlüssel ab
    func getCoreDataEncryptionKey() throws -> SymmetricKey? {
        guard isDevicePasscodeSet() else {
            throw CryptoError.noDevicePasscode
        }
        
        // Versuche Schlüssel aus Keychain zu laden
        if let existingKey = try loadCoreDataKeyFromKeychain() {
            return existingKey
        }
        
        // Neuen Schlüssel erstellen und speichern
        let newKey = SymmetricKey(size: .bits256)
        try saveCoreDataKeyToKeychain(newKey)
        return newKey
    }
    
    /// Lädt den CoreData-Verschlüsselungsschlüssel aus der Keychain
    private func loadCoreDataKeyFromKeychain() throws -> SymmetricKey? {
        let accessControl = try createAccessControl()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.coreDataKeyLabel,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessControl as String: accessControl
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil // Schlüssel existiert noch nicht
            }
            throw CryptoError.keychainError(status)
        }
        
        guard let keyData = result as? Data else {
            throw CryptoError.invalidKeyData
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Speichert den CoreData-Verschlüsselungsschlüssel in der Keychain mit Secure Enclave
    private func saveCoreDataKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        let accessControl = try createAccessControl()
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.coreDataKeyLabel,
            kSecValueData as String: keyData,
            kSecAttrAccessControl as String: accessControl
        ]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw CryptoError.keychainError(status)
        }
    }
    
    /// Erstellt Access Control für Secure Enclave
    private func createAccessControl() throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        
        // Versuche zuerst mit Secure Enclave
        if isSecureEnclaveAvailable() {
            if let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.privateKeyUsage, .biometryAny],
                &error
            ) {
                return accessControl
            }
        }
        
        // Fallback ohne Secure Enclave aber mit Device Passcode
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .devicePasscode,
            &error
        ) else {
            throw CryptoError.accessControlCreationFailed
        }
        
        return accessControl
    }
    
    /// Überprüft ob CoreData-Migration notwendig ist
    func requiresCoreDataMigration() -> Bool {
        // Prüfe ob bereits ein CoreData-Verschlüsselungsschlüssel existiert
        do {
            return try loadCoreDataKeyFromKeychain() == nil
        } catch {
            return true
        }
    }
    
    /// Bereitet CoreData-Migration vor
    func prepareCoreDataMigration() throws {
        guard isDevicePasscodeSet() else {
            throw CryptoError.noDevicePasscode
        }
        
        // Erstelle Backup-Info für Migration
        let migrationInfo = CoreDataMigrationInfo(
            timestamp: Date(),
            hasDevicePasscode: true,
            secureEnclaveAvailable: isSecureEnclaveAvailable()
        )
        
        try saveMigrationInfo(migrationInfo)
    }
    
    /// Speichert Migration-Informationen
    private func saveMigrationInfo(_ info: CoreDataMigrationInfo) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(info)
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: "migration-info",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Lösche vorhandene Migration-Info
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: "migration-info"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CryptoError.keychainError(status)
        }
    }
}

// MARK: - Supporting Types

/// Verschlüsselte Datenstruktur
struct EncryptedData {
    let encryptedData: Data
    let iv: Data
    let tag: Data
}

/// NFC-Verschlüsselungspaket für JSON-Serialisierung
struct NFCEncryptedPackage: Codable {
    let encrypted: Bool
    let version: Int
    let iv: String
    let data: String
    let tag: String
}

/// CoreData Migration Info
struct CoreDataMigrationInfo: Codable {
    let timestamp: Date
    let hasDevicePasscode: Bool
    let secureEnclaveAvailable: Bool
}

/// CryptoManager Fehlertypen
enum CryptoError: LocalizedError {
    case keychainError(OSStatus)
    case invalidKeyData
    case encryptionFailed
    case decryptionFailed
    case noDevicePasscode
    case accessControlCreationFailed
    case migrationRequired
    case migrationFailed
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain-Fehler: \(status)"
        case .invalidKeyData:
            return "Ungültige Schlüsseldaten"
        case .encryptionFailed:
            return "Verschlüsselung fehlgeschlagen"
        case .decryptionFailed:
            return "Entschlüsselung fehlgeschlagen"
        case .noDevicePasscode:
            return "Kein Geräte-Passcode gesetzt. Verschlüsselung erfordert einen Passcode oder Touch/Face ID."
        case .accessControlCreationFailed:
            return "Fehler beim Erstellen der Zugriffskontrolle"
        case .migrationRequired:
            return "CoreData-Migration zur Aktivierung der Verschlüsselung erforderlich"
        case .migrationFailed:
            return "CoreData-Migration fehlgeschlagen"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noDevicePasscode:
            return "Bitte setzen Sie einen Geräte-Passcode in den Einstellungen oder aktivieren Sie Touch ID/Face ID."
        case .migrationRequired:
            return "Die App wird die Datenbank zur Aktivierung der Verschlüsselung migrieren."
        case .migrationFailed:
            return "Bitte starten Sie die App neu oder kontaktieren Sie den Support."
        default:
            return nil
        }
    }
}