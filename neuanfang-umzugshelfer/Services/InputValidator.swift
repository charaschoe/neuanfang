//
//  InputValidator.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

/// Input validation service for securing and validating user inputs
@MainActor
final class InputValidator: ObservableObject {
    static let shared = InputValidator()
    
    private init() {}
    
    // MARK: - Validation Rules
    
    struct ValidationRules {
        static let nameLength = 2...50
        static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        static let addressLength = 5...200
        static let descriptionLength = 0...500
        static let valueRange = 0.01...999999.99
        
        // Character sets for different input types
        static let nameAllowedCharacters = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-'"))
        
        static let addressAllowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(.punctuationCharacters)
            .union(CharacterSet(charactersIn: "äöüßÄÖÜ"))
        
        // SQL injection patterns to detect and prevent
        static let sqlInjectionPatterns = [
            "(?i)\\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\\b",
            "(?i)--",
            "(?i)/\\*.*?\\*/",
            "(?i)'.*?'.*?(OR|AND).*?'.*?'",
            "(?i)\\b(XP_|SP_)\\w+"
        ]
    }
    
    // MARK: - Validation Results
    
    struct ValidationResult {
        let isValid: Bool
        let errorMessage: String?
        let sanitizedInput: String?
        
        static let valid = ValidationResult(isValid: true, errorMessage: nil, sanitizedInput: nil)
        
        static func invalid(_ message: String) -> ValidationResult {
            ValidationResult(isValid: false, errorMessage: message, sanitizedInput: nil)
        }
        
        static func sanitized(_ input: String, _ sanitized: String) -> ValidationResult {
            ValidationResult(isValid: true, errorMessage: nil, sanitizedInput: sanitized)
        }
    }
    
    // MARK: - Email Validation
    
    func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty input
        guard !trimmedEmail.isEmpty else {
            return .invalid(NSLocalizedString("validation.email.empty", comment: ""))
        }
        
        // Check length
        guard trimmedEmail.count <= 254 else {
            return .invalid(NSLocalizedString("validation.email.tooLong", comment: ""))
        }
        
        // SQL injection check
        if let result = checkForSQLInjection(trimmedEmail), !result.isValid {
            return result
        }
        
        // Regex validation
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", ValidationRules.emailRegex)
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            return .invalid(NSLocalizedString("validation.email.invalid", comment: ""))
        }
        
        return .valid
    }
    
    // MARK: - Name Validation
    
    func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty input
        guard !trimmedName.isEmpty else {
            return .invalid(NSLocalizedString("validation.name.empty", comment: ""))
        }
        
        // Check length
        guard ValidationRules.nameLength.contains(trimmedName.count) else {
            return .invalid(NSLocalizedString("validation.name.length", comment: ""))
        }
        
        // SQL injection check
        if let result = checkForSQLInjection(trimmedName), !result.isValid {
            return result
        }
        
        // Character validation
        let sanitizedName = sanitizeInput(trimmedName, allowedCharacters: ValidationRules.nameAllowedCharacters)
        
        guard sanitizedName == trimmedName else {
            return .invalid(NSLocalizedString("validation.name.invalidCharacters", comment: ""))
        }
        
        // Check for consecutive spaces or hyphens
        guard !trimmedName.contains("  ") && !trimmedName.contains("--") else {
            return .invalid(NSLocalizedString("validation.name.consecutiveChars", comment: ""))
        }
        
        return .valid
    }
    
    // MARK: - Address Validation
    
    func validateAddress(_ address: String) -> ValidationResult {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty input (addresses can be optional in some contexts)
        if trimmedAddress.isEmpty {
            return .valid
        }
        
        // Check length
        guard ValidationRules.addressLength.contains(trimmedAddress.count) else {
            return .invalid(NSLocalizedString("validation.address.length", comment: ""))
        }
        
        // SQL injection check
        if let result = checkForSQLInjection(trimmedAddress), !result.isValid {
            return result
        }
        
        // Character validation (more permissive for addresses)
        let sanitizedAddress = sanitizeInput(trimmedAddress, allowedCharacters: ValidationRules.addressAllowedCharacters)
        
        guard sanitizedAddress == trimmedAddress else {
            return .invalid(NSLocalizedString("validation.address.invalidCharacters", comment: ""))
        }
        
        return .valid
    }
    
    // MARK: - Description Validation
    
    func validateDescription(_ description: String) -> ValidationResult {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check length
        guard ValidationRules.descriptionLength.contains(trimmedDescription.count) else {
            return .invalid(NSLocalizedString("validation.description.length", comment: ""))
        }
        
        // SQL injection check
        if let result = checkForSQLInjection(trimmedDescription), !result.isValid {
            return result
        }
        
        return .valid
    }
    
    // MARK: - Value Validation
    
    func validateValue(_ valueString: String) -> ValidationResult {
        let trimmedValue = valueString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty input
        guard !trimmedValue.isEmpty else {
            return .invalid(NSLocalizedString("validation.value.empty", comment: ""))
        }
        
        // SQL injection check
        if let result = checkForSQLInjection(trimmedValue), !result.isValid {
            return result
        }
        
        // Convert to double
        guard let value = Double(trimmedValue) else {
            return .invalid(NSLocalizedString("validation.value.notNumeric", comment: ""))
        }
        
        // Check range
        guard ValidationRules.valueRange.contains(value) else {
            return .invalid(NSLocalizedString("validation.value.range", comment: ""))
        }
        
        return .valid
    }
    
    // MARK: - SQL Injection Protection
    
    private func checkForSQLInjection(_ input: String) -> ValidationResult? {
        for pattern in ValidationRules.sqlInjectionPatterns {
            if input.range(of: pattern, options: .regularExpression) != nil {
                return .invalid(NSLocalizedString("validation.security.sqlInjection", comment: ""))
            }
        }
        return nil
    }
    
    // MARK: - Input Sanitization
    
    private func sanitizeInput(_ input: String, allowedCharacters: CharacterSet) -> String {
        return String(input.unicodeScalars.filter { allowedCharacters.contains($0) })
    }
    
    // MARK: - Real-time Validation Publishers
    
    func emailValidationPublisher(for emailSubject: Published<String>.Publisher) -> AnyPublisher<ValidationResult, Never> {
        emailSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] email in
                self?.validateEmail(email) ?? .invalid("Validation service unavailable")
            }
            .eraseToAnyPublisher()
    }
    
    func nameValidationPublisher(for nameSubject: Published<String>.Publisher) -> AnyPublisher<ValidationResult, Never> {
        nameSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] name in
                self?.validateName(name) ?? .invalid("Validation service unavailable")
            }
            .eraseToAnyPublisher()
    }
    
    func addressValidationPublisher(for addressSubject: Published<String>.Publisher) -> AnyPublisher<ValidationResult, Never> {
        addressSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] address in
                self?.validateAddress(address) ?? .invalid("Validation service unavailable")
            }
            .eraseToAnyPublisher()
    }
    
    func descriptionValidationPublisher(for descriptionSubject: Published<String>.Publisher) -> AnyPublisher<ValidationResult, Never> {
        descriptionSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] description in
                self?.validateDescription(description) ?? .invalid("Validation service unavailable")
            }
            .eraseToAnyPublisher()
    }
    
    func valueValidationPublisher(for valueSubject: Published<String>.Publisher) -> AnyPublisher<ValidationResult, Never> {
        valueSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] value in
                self?.validateValue(value) ?? .invalid("Validation service unavailable")
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SwiftUI Integration

struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    let validator: (String) -> InputValidator.ValidationResult
    let keyboardType: UIKeyboardType
    
    @State private var validationResult = InputValidator.ValidationResult.valid
    @State private var showError = false
    
    init(
        _ title: String,
        text: Binding<String>,
        validator: @escaping (String) -> InputValidator.ValidationResult,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self._text = text
        self.validator = validator
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: showError ? 2 : 0)
                )
                .onChange(of: text) { _, newValue in
                    validateInput(newValue)
                }
            
            if showError, let errorMessage = validationResult.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
    }
    
    private var borderColor: Color {
        if showError {
            return .red
        }
        return .clear
    }
    
    private func validateInput(_ input: String) {
        validationResult = validator(input)
        withAnimation(.easeInOut(duration: 0.2)) {
            showError = !validationResult.isValid && !input.isEmpty
        }
    }
}

// MARK: - View Modifier for Validation

struct ValidationModifier: ViewModifier {
    let validationResult: InputValidator.ValidationResult
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(validationResult.isValid ? .clear : .red, lineWidth: 2)
            )
    }
}

extension View {
    func validated(_ result: InputValidator.ValidationResult) -> some View {
        modifier(ValidationModifier(validationResult: result))
    }
}