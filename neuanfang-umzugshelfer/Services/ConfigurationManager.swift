//
//  ConfigurationManager.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import os.log

/// Zentrale Konfigurationsverwaltung für die App
final class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private static let logger = Logger(subsystem: "com.neuanfang.umzugshelfer", category: "ConfigurationManager")
    
    // MARK: - Private Properties
    
    private var configCache: [String: Any]?
    private let configFileName = "Config"
    private let configFileExtension = "plist"
    
    // MARK: - Initialization
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Public Configuration Properties
    
    /// CloudKit Container Identifier
    var cloudKitContainerIdentifier: String {
        return getCloudKitConfiguration("ContainerIdentifier", defaultValue: "iCloud.com.neuanfang.umzugshelfer")
    }
    
    /// CloudKit Environment (production/development)
    var cloudKitEnvironment: String {
        return getCloudKitConfiguration("Environment", defaultValue: "production")
    }
    
    /// CloudKit Batch Size für Synchronisation
    var cloudKitBatchSize: Int {
        return getCloudKitConfiguration("BatchSize", defaultValue: 50)
    }
    
    /// CloudKit Sync Timeout in Sekunden
    var cloudKitSyncTimeout: Int {
        return getCloudKitConfiguration("SyncTimeout", defaultValue: 30)
    }
    
    /// App Version
    var appVersion: String {
        return getAppConfiguration("Version", defaultValue: "1.0.0")
    }
    
    /// App Build Number
    var appBuild: String {
        return getAppConfiguration("Build", defaultValue: "1")
    }
    
    /// Minimum iOS Version
    var minimumIOSVersion: String {
        return getAppConfiguration("MinimumIOSVersion", defaultValue: "15.0")
    }
    
    /// Verschlüsselung aktiviert
    var isEncryptionEnabled: Bool {
        return getSecurityConfiguration("EncryptionEnabled", defaultValue: true)
    }
    
    /// File Protection Level
    var fileProtectionLevel: String {
        return getSecurityConfiguration("FileProtectionLevel", defaultValue: "complete")
    }
    
    /// CloudKit Verschlüsselung aktiviert
    var isCloudKitEncryptionEnabled: Bool {
        return getSecurityConfiguration("CloudKitEncryptionEnabled", defaultValue: true)
    }
    
    /// Debug Logging aktiviert
    var isDebugLoggingEnabled: Bool {
        return getDevelopmentConfiguration("DebugLogging", defaultValue: false)
    }
    
    /// Test Mode aktiviert
    var isTestModeEnabled: Bool {
        return getDevelopmentConfiguration("TestMode", defaultValue: false)
    }
    
    // MARK: - Configuration Loading
    
    private func loadConfiguration() {
        guard let path = Bundle.main.path(forResource: configFileName, ofType: configFileExtension),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            Self.logger.error("Failed to load configuration from \(self.configFileName).\(self.configFileExtension)")
            handleConfigurationError(.configurationFileNotFound)
            return
        }
        
        configCache = plist
        Self.logger.info("Configuration loaded successfully from \(self.configFileName).\(self.configFileExtension)")
        
        // Validiere kritische Konfigurationswerte
        validateConfiguration()
    }
    
    private func validateConfiguration() {
        guard let config = configCache else {
            handleConfigurationError(.configurationNotLoaded)
            return
        }
        
        // Validiere CloudKit Konfiguration
        guard let cloudKitConfig = config["CloudKit"] as? [String: Any],
              let containerIdentifier = cloudKitConfig["ContainerIdentifier"] as? String,
              !containerIdentifier.isEmpty else {
            handleConfigurationError(.invalidCloudKitConfiguration)
            return
        }
        
        // Validiere Container ID Format
        if !containerIdentifier.hasPrefix("iCloud.") {
            Self.logger.warning("CloudKit Container ID does not start with 'iCloud.': \(containerIdentifier)")
        }
        
        Self.logger.info("Configuration validation completed successfully")
    }
    
    // MARK: - Configuration Getters
    
    private func getCloudKitConfiguration<T>(_ key: String, defaultValue: T) -> T {
        return getNestedConfiguration("CloudKit", key: key, defaultValue: defaultValue)
    }
    
    private func getAppConfiguration<T>(_ key: String, defaultValue: T) -> T {
        return getNestedConfiguration("App", key: key, defaultValue: defaultValue)
    }
    
    private func getSecurityConfiguration<T>(_ key: String, defaultValue: T) -> T {
        return getNestedConfiguration("Security", key: key, defaultValue: defaultValue)
    }
    
    private func getDevelopmentConfiguration<T>(_ key: String, defaultValue: T) -> T {
        return getNestedConfiguration("Development", key: key, defaultValue: defaultValue)
    }
    
    private func getNestedConfiguration<T>(_ section: String, key: String, defaultValue: T) -> T {
        guard let config = configCache,
              let sectionConfig = config[section] as? [String: Any],
              let value = sectionConfig[key] as? T else {
            Self.logger.warning("Configuration value not found for \(section).\(key), using default: \(defaultValue)")
            return defaultValue
        }
        return value
    }
    
    // MARK: - Configuration Updates (for testing/development)
    
    /// Aktualisiert die Konfiguration zur Laufzeit (nur für Tests/Development)
    func updateConfiguration(_ updates: [String: Any]) {
        guard isTestModeEnabled || isDebugLoggingEnabled else {
            Self.logger.warning("Configuration updates are only allowed in test or debug mode")
            return
        }
        
        guard var config = configCache else {
            Self.logger.error("Cannot update configuration: no configuration loaded")
            return
        }
        
        for (key, value) in updates {
            config[key] = value
        }
        
        configCache = config
        Self.logger.info("Configuration updated with \(updates.count) changes")
    }
    
    /// Lädt die Konfiguration neu
    func reloadConfiguration() {
        configCache = nil
        loadConfiguration()
    }
    
    // MARK: - Error Handling
    
    private func handleConfigurationError(_ error: ConfigurationError) {
        Self.logger.error("Configuration error: \(error.localizedDescription)")
        
        #if DEBUG
        print("ConfigurationManager Error: \(error.localizedDescription)")
        #else
        // In Production: Post notification für UI handling
        NotificationCenter.default.post(
            name: Notification.Name("ConfigurationError"),
            object: error
        )
        #endif
        
        // Für kritische Fehler: Fallback-Konfiguration verwenden
        switch error {
        case .configurationFileNotFound, .configurationNotLoaded:
            useFallbackConfiguration()
        case .invalidCloudKitConfiguration:
            // CloudKit-spezifische Fallback-Behandlung
            break
        }
    }
    
    private func useFallbackConfiguration() {
        Self.logger.info("Using fallback configuration")
        
        configCache = [
            "CloudKit": [
                "ContainerIdentifier": "iCloud.com.neuanfang.umzugshelfer",
                "Environment": "production",
                "BatchSize": 50,
                "SyncTimeout": 30
            ],
            "App": [
                "Version": "1.0.0",
                "Build": "1",
                "MinimumIOSVersion": "15.0"
            ],
            "Security": [
                "EncryptionEnabled": true,
                "FileProtectionLevel": "complete",
                "CloudKitEncryptionEnabled": true
            ],
            "Development": [
                "DebugLogging": false,
                "TestMode": false
            ]
        ]
    }
    
    // MARK: - Configuration Summary
    
    /// Gibt eine Zusammenfassung der aktuellen Konfiguration zurück
    func getConfigurationSummary() -> [String: Any] {
        return [
            "CloudKit": [
                "ContainerIdentifier": cloudKitContainerIdentifier,
                "Environment": cloudKitEnvironment,
                "BatchSize": cloudKitBatchSize,
                "SyncTimeout": cloudKitSyncTimeout
            ],
            "App": [
                "Version": appVersion,
                "Build": appBuild,
                "MinimumIOSVersion": minimumIOSVersion
            ],
            "Security": [
                "EncryptionEnabled": isEncryptionEnabled,
                "FileProtectionLevel": fileProtectionLevel,
                "CloudKitEncryptionEnabled": isCloudKitEncryptionEnabled
            ],
            "Development": [
                "DebugLogging": isDebugLoggingEnabled,
                "TestMode": isTestModeEnabled
            ]
        ]
    }
}

// MARK: - Configuration Errors

enum ConfigurationError: LocalizedError {
    case configurationFileNotFound
    case configurationNotLoaded
    case invalidCloudKitConfiguration
    
    var errorDescription: String? {
        switch self {
        case .configurationFileNotFound:
            return "Konfigurationsdatei konnte nicht gefunden werden"
        case .configurationNotLoaded:
            return "Konfiguration konnte nicht geladen werden"
        case .invalidCloudKitConfiguration:
            return "Ungültige CloudKit-Konfiguration"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let configurationError = Notification.Name("ConfigurationError")
    static let configurationReloaded = Notification.Name("ConfigurationReloaded")
}