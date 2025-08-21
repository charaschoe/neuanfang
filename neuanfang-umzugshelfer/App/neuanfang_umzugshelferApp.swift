//
//  neuanfang_umzugshelferApp.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import SwiftUI
import CoreData
import CloudKit

@main
struct neuanfang_umzugshelferApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(CloudKitService.shared)
                .environmentObject(AppState.shared)
                .preferredColorScheme(.none) // Respects system setting
        }
    }
}

/// Global app state management
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isFirstLaunch = true
    @Published var hasCompletedOnboarding = false
    @Published var currentUser: UserProfile?
    @Published var selectedTab: Tab = .rooms
    @Published var isOfflineMode = false
    
    private init() {
        loadUserDefaults()
    }
    
    enum Tab: String, CaseIterable {
        case rooms = "rooms"
        case timeline = "timeline"
        case search = "search"
        case settings = "settings"
        
        var title: String {
            switch self {
            case .rooms: return "Räume"
            case .timeline: return "Timeline"
            case .search: return "Suchen"
            case .settings: return "Einstellungen"
            }
        }
        
        var icon: String {
            switch self {
            case .rooms: return "house.fill"
            case .timeline: return "calendar"
            case .search: return "magnifyingglass"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    private func loadUserDefaults() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

/// User profile model with validation support
struct UserProfile: Codable, Identifiable {
    let id = UUID()
    var name: String
    var email: String
    var movingDate: Date?
    var currentAddress: String?
    var newAddress: String?
    var preferredLanguage: String = "de"
    
    // MARK: - Validation
    
    var isValid: Bool {
        isNameValid && isEmailValid && isCurrentAddressValid && isNewAddressValid
    }
    
    var isNameValid: Bool {
        InputValidator.shared.validateName(name).isValid
    }
    
    var isEmailValid: Bool {
        InputValidator.shared.validateEmail(email).isValid
    }
    
    var isCurrentAddressValid: Bool {
        guard let address = currentAddress, !address.isEmpty else { return true }
        return InputValidator.shared.validateAddress(address).isValid
    }
    
    var isNewAddressValid: Bool {
        guard let address = newAddress, !address.isEmpty else { return true }
        return InputValidator.shared.validateAddress(address).isValid
    }
    
    // MARK: - Validation Results
    
    var nameValidationResult: InputValidator.ValidationResult {
        InputValidator.shared.validateName(name)
    }
    
    var emailValidationResult: InputValidator.ValidationResult {
        InputValidator.shared.validateEmail(email)
    }
    
    var currentAddressValidationResult: InputValidator.ValidationResult {
        guard let address = currentAddress else { return .valid }
        return InputValidator.shared.validateAddress(address)
    }
    
    var newAddressValidationResult: InputValidator.ValidationResult {
        guard let address = newAddress else { return .valid }
        return InputValidator.shared.validateAddress(address)
    }
    
    // MARK: - Sanitization
    
    mutating func sanitizeInputs() {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if let address = currentAddress {
            currentAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
            if currentAddress?.isEmpty == true {
                currentAddress = nil
            }
        }
        
        if let address = newAddress {
            newAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
            if newAddress?.isEmpty == true {
                newAddress = nil
            }
        }
    }
    
    static let mock = UserProfile(
        name: "Max Mustermann",
        email: "max@example.com",
        movingDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
        currentAddress: "Alte Straße 123, 12345 Berlin",
        newAddress: "Neue Straße 456, 54321 München"
    )
}