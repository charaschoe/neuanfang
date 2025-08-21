//
//  InputValidatorTests.swift
//  neuanfang: Umzugshelfer Tests
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import XCTest
@testable import neuanfang_umzugshelfer

@MainActor
final class InputValidatorTests: XCTestCase {
    
    var validator: InputValidator!
    
    override func setUpWithError() throws {
        validator = InputValidator.shared
    }
    
    override func tearDownWithError() throws {
        validator = nil
    }
    
    // MARK: - Email Validation Tests
    
    func testValidEmails() throws {
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "first+last@test-domain.com",
            "user123@example123.org",
            "a@b.co"
        ]
        
        for email in validEmails {
            let result = validator.validateEmail(email)
            XCTAssertTrue(result.isValid, "Email '\(email)' should be valid")
            XCTAssertNil(result.errorMessage, "Valid email should not have error message")
        }
    }
    
    func testInvalidEmails() throws {
        let invalidEmails = [
            "",                          // Empty
            "invalid",                   // No domain
            "@example.com",             // No local part
            "test@",                    // No domain
            "test..test@example.com",   // Double dots
            "test@example",             // No TLD
            "test@.com",                // No domain name
            "test@example.",            // No TLD after dot
            String(repeating: "a", count: 250) + "@example.com"  // Too long
        ]
        
        for email in invalidEmails {
            let result = validator.validateEmail(email)
            XCTAssertFalse(result.isValid, "Email '\(email)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Invalid email should have error message")
        }
    }
    
    func testEmailSQLInjection() throws {
        let maliciousEmails = [
            "test@example.com'; DROP TABLE users; --",
            "test@example.com UNION SELECT * FROM passwords",
            "test@example.com' OR 1=1 --"
        ]
        
        for email in maliciousEmails {
            let result = validator.validateEmail(email)
            XCTAssertFalse(result.isValid, "Malicious email '\(email)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Malicious email should have error message")
        }
    }
    
    // MARK: - Name Validation Tests
    
    func testValidNames() throws {
        let validNames = [
            "Max Mustermann",
            "Anna-Maria Schmidt",
            "Jean-Pierre",
            "O'Connor",
            "李小明",
            "José María",
            "Åsa Björk"
        ]
        
        for name in validNames {
            let result = validator.validateName(name)
            XCTAssertTrue(result.isValid, "Name '\(name)' should be valid")
            XCTAssertNil(result.errorMessage, "Valid name should not have error message")
        }
    }
    
    func testInvalidNames() throws {
        let invalidNames = [
            "",                              // Empty
            "A",                            // Too short
            String(repeating: "a", count: 51), // Too long
            "Max  Mustermann",              // Double spaces
            "Test--Name",                   // Double hyphens
            "123456",                       // Numbers only
            "Test@Name",                    // Invalid characters
            "Name#123"                      // Invalid characters
        ]
        
        for name in invalidNames {
            let result = validator.validateName(name)
            XCTAssertFalse(result.isValid, "Name '\(name)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Invalid name should have error message")
        }
    }
    
    func testNameSQLInjection() throws {
        let maliciousNames = [
            "'; DROP TABLE rooms; --",
            "Max' OR 1=1 --",
            "Robert'); DELETE FROM boxes; --"
        ]
        
        for name in maliciousNames {
            let result = validator.validateName(name)
            XCTAssertFalse(result.isValid, "Malicious name '\(name)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Malicious name should have error message")
        }
    }
    
    // MARK: - Address Validation Tests
    
    func testValidAddresses() throws {
        let validAddresses = [
            "Musterstraße 123, 12345 Berlin",
            "Hauptstraße 1A",
            "Am Marktplatz 5-7, 54321 München",
            "Römerstraße 15, 67890 Köln",
            "123 Main Street, New York, NY 10001",
            ""  // Empty address should be valid (optional)
        ]
        
        for address in validAddresses {
            let result = validator.validateAddress(address)
            XCTAssertTrue(result.isValid, "Address '\(address)' should be valid")
            XCTAssertNil(result.errorMessage, "Valid address should not have error message")
        }
    }
    
    func testInvalidAddresses() throws {
        let invalidAddresses = [
            "1234",                         // Too short
            String(repeating: "a", count: 201)  // Too long
        ]
        
        for address in invalidAddresses {
            let result = validator.validateAddress(address)
            XCTAssertFalse(result.isValid, "Address '\(address)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Invalid address should have error message")
        }
    }
    
    func testAddressSQLInjection() throws {
        let maliciousAddresses = [
            "Hauptstraße 1'; DROP TABLE addresses; --",
            "Street 1' OR 1=1 --"
        ]
        
        for address in maliciousAddresses {
            let result = validator.validateAddress(address)
            XCTAssertFalse(result.isValid, "Malicious address '\(address)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Malicious address should have error message")
        }
    }
    
    // MARK: - Description Validation Tests
    
    func testValidDescriptions() throws {
        let validDescriptions = [
            "",                             // Empty description is valid
            "Eine kurze Beschreibung",
            "Dies ist eine längere Beschreibung mit mehr Details über den Gegenstand.",
            String(repeating: "a", count: 500)  // Max length
        ]
        
        for description in validDescriptions {
            let result = validator.validateDescription(description)
            XCTAssertTrue(result.isValid, "Description '\(description)' should be valid")
            XCTAssertNil(result.errorMessage, "Valid description should not have error message")
        }
    }
    
    func testInvalidDescriptions() throws {
        let invalidDescriptions = [
            String(repeating: "a", count: 501)  // Too long
        ]
        
        for description in invalidDescriptions {
            let result = validator.validateDescription(description)
            XCTAssertFalse(result.isValid, "Description '\(description)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Invalid description should have error message")
        }
    }
    
    func testDescriptionSQLInjection() throws {
        let maliciousDescriptions = [
            "Description'; DROP TABLE items; --",
            "Normal text' OR 1=1 --"
        ]
        
        for description in maliciousDescriptions {
            let result = validator.validateDescription(description)
            XCTAssertFalse(result.isValid, "Malicious description '\(description)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Malicious description should have error message")
        }
    }
    
    // MARK: - Value Validation Tests
    
    func testValidValues() throws {
        let validValues = [
            "0.01",                         // Minimum value
            "999999.99",                    // Maximum value
            "123.45",                       // Decimal value
            "100",                          // Integer value
            "50.0"                          // Decimal with zero
        ]
        
        for value in validValues {
            let result = validator.validateValue(value)
            XCTAssertTrue(result.isValid, "Value '\(value)' should be valid")
            XCTAssertNil(result.errorMessage, "Valid value should not have error message")
        }
    }
    
    func testInvalidValues() throws {
        let invalidValues = [
            "",                             // Empty
            "0",                            // Too small
            "0.00",                         // Too small
            "1000000",                      // Too large
            "abc",                          // Not numeric
            "12.34.56",                     // Invalid format
            "-50",                          // Negative
            "12,34"                         // Wrong decimal separator for validator
        ]
        
        for value in invalidValues {
            let result = validator.validateValue(value)
            XCTAssertFalse(result.isValid, "Value '\(value)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Invalid value should have error message")
        }
    }
    
    func testValueSQLInjection() throws {
        let maliciousValues = [
            "100'; DROP TABLE items; --",
            "50' OR 1=1 --"
        ]
        
        for value in maliciousValues {
            let result = validator.validateValue(value)
            XCTAssertFalse(result.isValid, "Malicious value '\(value)' should be invalid")
            XCTAssertNotNil(result.errorMessage, "Malicious value should have error message")
        }
    }
    
    // MARK: - Edge Cases and Performance Tests
    
    func testValidationPerformance() throws {
        let testStrings = (0..<1000).map { "test\($0)@example.com" }
        
        measure {
            for email in testStrings {
                _ = validator.validateEmail(email)
            }
        }
    }
    
    func testUnicodeHandling() throws {
        let unicodeStrings = [
            "测试@example.com",               // Chinese characters
            "تست@example.com",                // Arabic characters
            "тест@example.com",               // Cyrillic characters
            "Müller@example.com"              // German umlauts
        ]
        
        for email in unicodeStrings {
            let result = validator.validateEmail(email)
            // Note: Depending on requirements, these might be valid or invalid
            // This test ensures the validator doesn't crash on unicode input
            XCTAssertNotNil(result, "Validator should handle unicode input without crashing")
        }
    }
    
    func testWhitespaceHandling() throws {
        let inputsWithWhitespace = [
            "  test@example.com  ",         // Leading/trailing spaces
            "\ntest@example.com\n",        // Newlines
            "\ttest@example.com\t"         // Tabs
        ]
        
        for email in inputsWithWhitespace {
            let result = validator.validateEmail(email)
            // Validator should handle whitespace properly
            XCTAssertNotNil(result, "Validator should handle whitespace input")
        }
    }
    
    // MARK: - Integration Tests
    
    func testUserProfileValidation() throws {
        var validProfile = UserProfile(name: "Max Mustermann", email: "max@example.com")
        XCTAssertTrue(validProfile.isValid, "Valid profile should pass validation")
        
        var invalidProfile = UserProfile(name: "", email: "invalid-email")
        XCTAssertFalse(invalidProfile.isValid, "Invalid profile should fail validation")
        
        // Test sanitization
        var profileWithSpaces = UserProfile(name: "  Max  ", email: "  max@example.com  ")
        profileWithSpaces.sanitizeInputs()
        XCTAssertEqual(profileWithSpaces.name, "Max", "Name should be trimmed")
        XCTAssertEqual(profileWithSpaces.email, "max@example.com", "Email should be trimmed and lowercased")
    }
    
    func testValidationResultStruct() throws {
        let validResult = InputValidator.ValidationResult.valid
        XCTAssertTrue(validResult.isValid)
        XCTAssertNil(validResult.errorMessage)
        XCTAssertNil(validResult.sanitizedInput)
        
        let invalidResult = InputValidator.ValidationResult.invalid("Test error")
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertEqual(invalidResult.errorMessage, "Test error")
        XCTAssertNil(invalidResult.sanitizedInput)
        
        let sanitizedResult = InputValidator.ValidationResult.sanitized("original", "sanitized")
        XCTAssertTrue(sanitizedResult.isValid)
        XCTAssertNil(sanitizedResult.errorMessage)
        XCTAssertEqual(sanitizedResult.sanitizedInput, "sanitized")
    }
}