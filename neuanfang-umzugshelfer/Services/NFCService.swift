//
//  NFCService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreNFC
import SwiftUI
import Combine

@MainActor
final class NFCService: NSObject, ObservableObject, NFCServiceProtocol {
    
    // MARK: - Published Properties
    
    @Published var isWriting = false
    @Published var isReading = false
    @Published var message = ""
    @Published var lastWrittenData: BoxShareData?
    @Published var lastReadData: BoxShareData?
    @Published var errorMessage: String?
    @Published var nfcStatus: NFCStatus = .unknown
    
    // MARK: - Private Properties
    
    private var writeSession: NFCNDEFReaderSession?
    private var readSession: NFCNDEFReaderSession?
    private var dataToWrite: BoxShareData?
    private var completion: ((Result<BoxShareData, NFCError>) -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkNFCAvailability()
    }
    
    // MARK: - Public Methods
    
    func writeNFCTag(with data: BoxShareData) {
        guard NFCNDEFReaderSession.readingAvailable else {
            errorMessage = "NFC ist auf diesem Gerät nicht verfügbar"
            nfcStatus = .notAvailable
            return
        }
        
        guard !isWriting else {
            errorMessage = "NFC-Schreibvorgang läuft bereits"
            return
        }
        
        isWriting = true
        errorMessage = nil
        message = "NFC-Tag an das Gerät halten..."
        dataToWrite = data
        
        writeSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        writeSession?.alertMessage = "NFC-Tag an das iPhone halten, um Kistendaten zu schreiben"
        writeSession?.begin()
        
        nfcStatus = .writing
    }
    
    func readNFCTag(completion: @escaping (Result<BoxShareData, NFCError>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(.notAvailable))
            return
        }
        
        guard !isReading else {
            completion(.failure(.alreadyReading))
            return
        }
        
        isReading = true
        errorMessage = nil
        message = "NFC-Tag an das Gerät halten..."
        self.completion = completion
        
        readSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        readSession?.alertMessage = "NFC-Tag an das iPhone halten, um Kistendaten zu lesen"
        readSession?.begin()
        
        nfcStatus = .reading
    }
    
    func stopCurrentSession() {
        writeSession?.invalidate()
        readSession?.invalidate()
        resetState()
    }
    
    private func checkNFCAvailability() {
        if NFCNDEFReaderSession.readingAvailable {
            nfcStatus = .available
        } else {
            nfcStatus = .notAvailable
            errorMessage = "NFC ist auf diesem Gerät nicht verfügbar"
        }
    }
    
    private func resetState() {
        isWriting = false
        isReading = false
        message = ""
        writeSession = nil
        readSession = nil
        dataToWrite = nil
        completion = nil
        nfcStatus = .available
    }
    
    // MARK: - Data Conversion
    
    private func createNDEFMessage(from boxData: BoxShareData) -> NFCNDEFMessage? {
        do {
            let jsonData = try JSONEncoder().encode(boxData)
            
            // Create NDEF records
            var records: [NFCNDEFPayload] = []
            
            // Add app identifier record
            if let appRecord = NFCNDEFPayload.wellKnownTypeURIPayload(string: "https://neuanfang.app/box/\(boxData.qrCode)") {
                records.append(appRecord)
            }
            
            // Add JSON data record
            let jsonRecord = NFCNDEFPayload(
                format: .media,
                type: "application/json".data(using: .utf8)!,
                identifier: "neuanfang-box".data(using: .utf8)!,
                payload: jsonData
            )
            records.append(jsonRecord)
            
            // Add text record for human readability
            let textContent = createHumanReadableText(from: boxData)
            if let textRecord = NFCNDEFPayload.wellKnownTypeTextPayload(string: textContent, locale: Locale(identifier: "de_DE")) {
                records.append(textRecord)
            }
            
            return NFCNDEFMessage(records: records)
            
        } catch {
            errorMessage = "Fehler beim Erstellen der NFC-Daten: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func createHumanReadableText(from boxData: BoxShareData) -> String {
        var text = "📦 Umzugskiste: \(boxData.name)\n"
        text += "🏠 Raum: \(boxData.roomName)\n"
        text += "📊 Status: \(boxData.isPacked ? "Gepackt ✅" : "Nicht gepackt ⏳")\n"
        text += "🔢 QR-Code: \(boxData.qrCode)\n"
        text += "📋 Gegenstände: \(boxData.totalItems)\n"
        
        if boxData.hasFragileItems {
            text += "⚠️ Enthält zerbrechliche Gegenstände\n"
        }
        
        text += "💰 Geschätzter Wert: €\(String(format: "%.2f", boxData.estimatedValue))\n"
        text += "📱 neuanfang: Umzugshelfer"
        
        return text
    }
    
    private func parseNDEFMessage(_ message: NFCNDEFMessage) -> BoxShareData? {
        for record in message.records {
            // Try to parse JSON record
            if let typeString = String(data: record.type, encoding: .utf8),
               typeString == "application/json",
               let identifier = String(data: record.identifier, encoding: .utf8),
               identifier == "neuanfang-box" {
                
                do {
                    let boxData = try JSONDecoder().decode(BoxShareData.self, from: record.payload)
                    return boxData
                } catch {
                    print("Failed to decode JSON from NFC: \(error)")
                }
            }
            
            // Fallback: Try to parse as text and extract basic info
            if record.typeNameFormat == .wellKnown,
               let typeString = String(data: record.type, encoding: .utf8),
               typeString == "T" {
                
                if let textPayload = String(data: record.payload.dropFirst(3), encoding: .utf8) {
                    return parseTextPayload(textPayload)
                }
            }
        }
        
        return nil
    }
    
    private func parseTextPayload(_ text: String) -> BoxShareData? {
        // Basic parsing of human-readable text format
        let lines = text.components(separatedBy: .newlines)
        var name = ""
        var roomName = ""
        var qrCode = ""
        var isPacked = false
        
        for line in lines {
            if line.contains("Umzugskiste:") {
                name = String(line.dropFirst(line.range(of: ": ")?.upperBound.utf16Offset(in: line) ?? 0))
            } else if line.contains("Raum:") {
                roomName = String(line.dropFirst(line.range(of: ": ")?.upperBound.utf16Offset(in: line) ?? 0))
            } else if line.contains("QR-Code:") {
                qrCode = String(line.dropFirst(line.range(of: ": ")?.upperBound.utf16Offset(in: line) ?? 0))
            } else if line.contains("Gepackt ✅") {
                isPacked = true
            }
        }
        
        // Create minimal BoxShareData
        return BoxShareData(
            id: UUID().uuidString,
            name: name,
            roomName: roomName,
            qrCode: qrCode,
            isPacked: isPacked,
            priority: .medium,
            estimatedValue: 0,
            totalItems: 0,
            hasFragileItems: false,
            items: []
        )
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension NFCService: NFCNDEFReaderSessionDelegate {
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    self.message = "NFC-Vorgang abgebrochen"
                case .readerSessionInvalidationErrorSessionTimeout:
                    self.errorMessage = "NFC-Sitzung abgelaufen"
                case .readerSessionInvalidationErrorSystemIsBusy:
                    self.errorMessage = "NFC-System ist beschäftigt"
                default:
                    self.errorMessage = "NFC-Fehler: \(error.localizedDescription)"
                }
            } else {
                self.errorMessage = "NFC-Fehler: \(error.localizedDescription)"
            }
            
            self.completion?(.failure(.sessionError(error)))
            self.resetState()
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first else { return }
        
        DispatchQueue.main.async {
            if let boxData = self.parseNDEFMessage(message) {
                self.lastReadData = boxData
                self.message = "NFC-Tag erfolgreich gelesen"
                self.completion?(.success(boxData))
            } else {
                self.errorMessage = "NFC-Tag konnte nicht gelesen werden"
                self.completion?(.failure(.invalidData))
            }
            
            session.invalidate()
            self.resetState()
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Verbindung zum NFC-Tag fehlgeschlagen: \(error.localizedDescription)"
                    self?.completion?(.failure(.connectionFailed))
                }
                session.invalidate()
                return
            }
            
            // Check if we're writing or reading
            if let dataToWrite = self?.dataToWrite {
                self?.writeToTag(tag, data: dataToWrite, session: session)
            } else {
                self?.readFromTag(tag, session: session)
            }
        }
    }
    
    private func writeToTag(_ tag: NFCNDEFTag, data: BoxShareData, session: NFCNDEFReaderSession) {
        tag.queryNDEFStatus { [weak self] status, capacity, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Fehler beim Abfragen des NFC-Tags: \(error.localizedDescription)"
                }
                session.invalidate()
                return
            }
            
            switch status {
            case .notSupported:
                DispatchQueue.main.async {
                    self.errorMessage = "NFC-Tag unterstützt NDEF nicht"
                }
                session.invalidate()
                
            case .readOnly:
                DispatchQueue.main.async {
                    self.errorMessage = "NFC-Tag ist schreibgeschützt"
                }
                session.invalidate()
                
            case .readWrite:
                guard let ndefMessage = self.createNDEFMessage(from: data) else {
                    session.invalidate()
                    return
                }
                
                // Check capacity
                let messageSize = ndefMessage.length
                if messageSize > capacity {
                    DispatchQueue.main.async {
                        self.errorMessage = "Daten zu groß für NFC-Tag (\(messageSize) > \(capacity) Bytes)"
                    }
                    session.invalidate()
                    return
                }
                
                // Write to tag
                tag.writeNDEF(ndefMessage) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Fehler beim Schreiben: \(error.localizedDescription)"
                            self.completion?(.failure(.writeFailed))
                        } else {
                            self.lastWrittenData = data
                            self.message = "NFC-Tag erfolgreich beschrieben"
                            self.completion?(.success(data))
                        }
                        
                        session.invalidate()
                        self.resetState()
                    }
                }
                
            @unknown default:
                DispatchQueue.main.async {
                    self.errorMessage = "Unbekannter NFC-Tag Status"
                }
                session.invalidate()
            }
        }
    }
    
    private func readFromTag(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        tag.readNDEF { [weak self] message, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Fehler beim Lesen: \(error.localizedDescription)"
                    self?.completion?(.failure(.readFailed))
                } else if let message = message,
                          let boxData = self?.parseNDEFMessage(message) {
                    self?.lastReadData = boxData
                    self?.message = "NFC-Tag erfolgreich gelesen"
                    self?.completion?(.success(boxData))
                } else {
                    self?.errorMessage = "NFC-Tag enthält keine gültigen Daten"
                    self?.completion?(.failure(.invalidData))
                }
                
                session.invalidate()
                self?.resetState()
            }
        }
    }
}

// MARK: - Supporting Types

enum NFCStatus {
    case unknown
    case notAvailable
    case available
    case reading
    case writing
    
    var description: String {
        switch self {
        case .unknown: return "Unbekannt"
        case .notAvailable: return "Nicht verfügbar"
        case .available: return "Verfügbar"
        case .reading: return "Liest..."
        case .writing: return "Schreibt..."
        }
    }
    
    var iconName: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .notAvailable: return "antenna.radiowaves.left.and.right.slash"
        case .available: return "antenna.radiowaves.left.and.right"
        case .reading: return "arrow.down.circle"
        case .writing: return "arrow.up.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .notAvailable: return .red
        case .available: return .green
        case .reading: return .blue
        case .writing: return .orange
        }
    }
}

enum NFCError: LocalizedError {
    case notAvailable
    case alreadyReading
    case alreadyWriting
    case sessionError(Error)
    case connectionFailed
    case writeFailed
    case readFailed
    case invalidData
    case tagNotSupported
    case tagReadOnly
    case capacityExceeded
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "NFC ist auf diesem Gerät nicht verfügbar"
        case .alreadyReading:
            return "NFC-Lesevorgang läuft bereits"
        case .alreadyWriting:
            return "NFC-Schreibvorgang läuft bereits"
        case .sessionError(let error):
            return "NFC-Sitzungsfehler: \(error.localizedDescription)"
        case .connectionFailed:
            return "Verbindung zum NFC-Tag fehlgeschlagen"
        case .writeFailed:
            return "Schreiben auf NFC-Tag fehlgeschlagen"
        case .readFailed:
            return "Lesen vom NFC-Tag fehlgeschlagen"
        case .invalidData:
            return "NFC-Tag enthält ungültige Daten"
        case .tagNotSupported:
            return "NFC-Tag wird nicht unterstützt"
        case .tagReadOnly:
            return "NFC-Tag ist schreibgeschützt"
        case .capacityExceeded:
            return "Daten zu groß für NFC-Tag"
        }
    }
}

// MARK: - Extensions

extension String {
    var utf16Offset: Int {
        return utf16.count
    }
}

extension String.Index {
    func utf16Offset(in string: String) -> Int {
        return string.utf16.distance(from: string.startIndex, to: self)
    }
}