//
//  MovingNotesAssistant.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData

/// AI-Assistent für kontextuelle Tipps und Erinnerungen während des Umzugs
@MainActor
final class MovingNotesAssistant: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isGenerating = false
    @Published var currentTips: [MovingTip] = []
    @Published var contextualReminders: [MovingReminder] = []
    @Published var dailyAdvice: String?
    @Published var errorMessage: String?
    @Published var lastUpdateDate: Date?
    
    // MARK: - Dependencies
    
    private let foundationService: FoundationModelsService
    private let viewContext: NSManagedObjectContext
    
    // MARK: - State Management
    
    private var userPreferences: AssistantPreferences = .default
    private var movingPhase: MovingPhase = .planning
    
    // MARK: - Initialization
    
    init(foundationService: FoundationModelsService = .shared,
         viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.foundationService = foundationService
        self.viewContext = viewContext
        
        loadUserPreferences()
        updateMovingPhase()
    }
    
    // MARK: - Public Methods
    
    /// Generiert kontextuelle Tipps basierend auf aktuellem Umzugsstatus
    func generateContextualTips() async throws -> [MovingTip] {
        isGenerating = true
        defer { isGenerating = false }
        
        let context = try await buildCurrentContext()
        let tips = try await generateTipsForContext(context)
        
        currentTips = tips
        lastUpdateDate = Date()
        
        return tips
    }
    
    /// Erstellt personalisierte Erinnerungen
    func generatePersonalizedReminders(for timeframe: ReminderTimeframe) async throws -> [MovingReminder] {
        let context = try await buildCurrentContext()
        let reminders = try await generateRemindersForTimeframe(timeframe, context: context)
        
        contextualReminders = reminders
        return reminders
    }
    
    /// Generiert tägliche Umzugsberatung
    func generateDailyAdvice() async throws -> String {
        isGenerating = true
        defer { isGenerating = false }
        
        let context = try await buildCurrentContext()
        let advice = try await generateAdviceForDay(context: context)
        
        dailyAdvice = advice
        return advice
    }
    
    /// Analysiert Umzugsfortschritt und gibt Empfehlungen
    func analyzeProgressAndSuggest() async throws -> ProgressAnalysis {
        let rooms = try fetchAllRooms()
        let analysis = try await performProgressAnalysis(rooms: rooms)
        
        return analysis
    }
    
    /// Generiert Notfallhilfe bei Problemen
    func generateEmergencyAssistance(problem: MovingProblem) async throws -> EmergencyAssistance {
        let context = try await buildCurrentContext()
        let assistance = try await generateEmergencyHelp(problem: problem, context: context)
        
        return assistance
    }
    
    /// Erstellt Checklisten für spezifische Situationen
    func generateSituationalChecklist(situation: MovingSituation) async throws -> MovingChecklist {
        let checklist = try await createChecklistForSituation(situation)
        return checklist
    }
    
    /// Gibt wetterbasierte Empfehlungen
    func generateWeatherBasedAdvice(weatherCondition: WeatherCondition, movingDate: Date) async throws -> [WeatherTip] {
        let tips = try await generateWeatherTips(condition: weatherCondition, date: movingDate)
        return tips
    }
    
    /// Aktualisiert Benutzereinstellungen
    func updatePreferences(_ preferences: AssistantPreferences) {
        userPreferences = preferences
        saveUserPreferences()
    }
    
    // MARK: - Private Methods
    
    private func buildCurrentContext() async throws -> MovingContext {
        let rooms = try fetchAllRooms()
        let totalBoxes = rooms.reduce(0) { $0 + $1.totalBoxes }
        let packedBoxes = rooms.reduce(0) { $0 + $1.packedBoxes }
        let totalItems = rooms.reduce(0) { $0 + $1.totalItems }
        
        // Schätze Umzugstermin basierend auf Fortschritt
        let estimatedMovingDate = estimateMovingDate(based: rooms)
        
        return MovingContext(
            phase: movingPhase,
            totalRooms: rooms.count,
            completedRooms: rooms.filter { $0.isCompleted }.count,
            totalBoxes: totalBoxes,
            packedBoxes: packedBoxes,
            totalItems: totalItems,
            estimatedMovingDate: estimatedMovingDate,
            daysUntilMove: daysBetween(Date(), and: estimatedMovingDate),
            preferences: userPreferences
        )
    }
    
    private func generateTipsForContext(_ context: MovingContext) async throws -> [MovingTip] {
        let prompt = buildTipsPrompt(context: context)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 400)
        
        return parseTips(from: response, context: context)
    }
    
    private func generateRemindersForTimeframe(_ timeframe: ReminderTimeframe, context: MovingContext) async throws -> [MovingReminder] {
        let prompt = buildRemindersPrompt(timeframe: timeframe, context: context)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 300)
        
        return parseReminders(from: response, timeframe: timeframe)
    }
    
    private func generateAdviceForDay(context: MovingContext) async throws -> String {
        let prompt = buildDailyAdvicePrompt(context: context)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 200)
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func performProgressAnalysis(rooms: [Room]) async throws -> ProgressAnalysis {
        let prompt = buildProgressAnalysisPrompt(rooms: rooms)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 300)
        
        return parseProgressAnalysis(response, rooms: rooms)
    }
    
    private func generateEmergencyHelp(problem: MovingProblem, context: MovingContext) async throws -> EmergencyAssistance {
        let prompt = buildEmergencyPrompt(problem: problem, context: context)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 250)
        
        return EmergencyAssistance(
            problem: problem,
            urgencyLevel: problem.urgencyLevel,
            solutions: parseSolutions(from: response),
            resources: suggestResources(for: problem),
            timeEstimate: estimateResolutionTime(for: problem)
        )
    }
    
    private func createChecklistForSituation(_ situation: MovingSituation) async throws -> MovingChecklist {
        let prompt = buildChecklistPrompt(situation: situation)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 300)
        
        return parseChecklist(from: response, situation: situation)
    }
    
    private func generateWeatherTips(condition: WeatherCondition, date: Date) async throws -> [WeatherTip] {
        let prompt = buildWeatherPrompt(condition: condition, date: date)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 200)
        
        return parseWeatherTips(from: response, condition: condition)
    }
    
    // MARK: - Prompt Building Methods
    
    private func buildTipsPrompt(context: MovingContext) -> String {
        return """
        Erstelle hilfreiche Umzugstipps basierend auf dem aktuellen Status:
        
        Phase: \(context.phase.displayName)
        Fortschritt: \(context.packedBoxes)/\(context.totalBoxes) Kisten gepackt
        Räume: \(context.completedRooms)/\(context.totalRooms) fertig
        Tage bis Umzug: \(context.daysUntilMove)
        Intensität: \(context.preferences.workIntensity.displayName)
        
        Gib 3-5 spezifische, umsetzbare Tipps für die aktuelle Situation:
        
        Format:
        1. [Kategorie]: [Konkreter Tipp]
        2. [Kategorie]: [Konkreter Tipp]
        ...
        """
    }
    
    private func buildRemindersPrompt(timeframe: ReminderTimeframe, context: MovingContext) -> String {
        return """
        Erstelle wichtige Erinnerungen für den Zeitraum: \(timeframe.displayName)
        
        Aktueller Status:
        - Phase: \(context.phase.displayName)
        - Tage bis Umzug: \(context.daysUntilMove)
        - Packfortschritt: \(Int((Double(context.packedBoxes) / Double(max(context.totalBoxes, 1))) * 100))%
        
        Generiere zeitspezifische Erinnerungen mit Prioritäten:
        
        Format:
        [Priorität] [Aufgabe]: [Beschreibung]
        """
    }
    
    private func buildDailyAdvicePrompt(context: MovingContext) -> String {
        let today = Date().formatted(date: .abbreviated, time: .omitted)
        
        return """
        Erstelle einen motivierenden Tagesratschlag für heute (\(today)):
        
        Situation:
        - Umzugsphase: \(context.phase.displayName)
        - Fortschritt: \(context.completedRooms) von \(context.totalRooms) Räumen fertig
        - Verbleibende Zeit: \(context.daysUntilMove) Tage
        
        Gib einen ermutigenden, praktischen Rat für den heutigen Tag (max. 100 Wörter):
        """
    }
    
    private func buildProgressAnalysisPrompt(rooms: [Room]) -> String {
        let roomProgress = rooms.map { room in
            "\(room.displayName): \(Int(room.packingProgress * 100))% gepackt"
        }.joined(separator: "\n")
        
        return """
        Analysiere den Umzugsfortschritt und gib Empfehlungen:
        
        Raumfortschritt:
        \(roomProgress)
        
        Erstelle:
        1. Gesamtbewertung des Fortschritts
        2. Kritische Bereiche, die Aufmerksamkeit brauchen
        3. Konkrete nächste Schritte
        4. Zeitschätzung bis zur Fertigstellung
        
        Format:
        Status: [Bewertung]
        Kritisch: [Bereiche]
        Nächste Schritte: [Aktionen]
        Zeitschätzung: [Tage/Stunden]
        """
    }
    
    private func buildEmergencyPrompt(problem: MovingProblem, context: MovingContext) -> String {
        return """
        NOTFALL-HILFE benötigt für: \(problem.displayName)
        
        Kontext:
        - Umzugsphase: \(context.phase.displayName)
        - Tage bis Umzug: \(context.daysUntilMove)
        - Dringlichkeit: \(problem.urgencyLevel.displayName)
        
        Problemdetails: \(problem.description)
        
        Gib sofortige, praktische Lösungsschritte:
        1. [Sofortmaßnahme]
        2. [Kurzfristige Lösung]
        3. [Langfristige Vorbeugung]
        """
    }
    
    private func buildChecklistPrompt(situation: MovingSituation) -> String {
        return """
        Erstelle eine detaillierte Checkliste für: \(situation.displayName)
        
        Situation: \(situation.description)
        
        Organisiere die Aufgaben in logischer Reihenfolge mit Zeitschätzungen:
        
        Format:
        [ ] [Aufgabe] (ca. X Min/Std)
        [ ] [Aufgabe] (ca. X Min/Std)
        ...
        """
    }
    
    private func buildWeatherPrompt(condition: WeatherCondition, date: Date) -> String {
        return """
        Umzugstag-Wetter: \(condition.displayName)
        Datum: \(date.formatted(date: .abbreviated, time: .omitted))
        
        Gib spezifische Tipps für Umzug bei diesem Wetter:
        1. Schutzmaßnahmen für Gegenstände
        2. Sicherheitshinweise für Transport
        3. Vorbereitungen und benötigte Ausrüstung
        
        Format pro Tipp:
        [Bereich]: [Konkreter Tipp]
        """
    }
    
    // MARK: - Parsing Methods
    
    private func parseTips(from response: String, context: MovingContext) -> [MovingTip] {
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains(":") }
        
        return lines.enumerated().map { index, line in
            let components = line.components(separatedBy: ":")
            let category = components[0].trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            let content = components.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
            
            return MovingTip(
                category: TipCategory.fromString(category),
                content: content,
                priority: index < 2 ? .high : .medium,
                phase: context.phase,
                estimatedTimeToImplement: estimateImplementationTime(content)
            )
        }
    }
    
    private func parseReminders(from response: String, timeframe: ReminderTimeframe) -> [MovingReminder] {
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return lines.compactMap { line in
            // Parse Format: [Priorität] [Aufgabe]: [Beschreibung]
            let priorityPattern = #"\[(high|medium|low|hoch|mittel|niedrig)\]"#
            guard let regex = try? NSRegularExpression(pattern: priorityPattern, options: .caseInsensitive) else {
                return nil
            }
            
            let range = NSRange(line.startIndex..., in: line)
            guard let match = regex.firstMatch(in: line, range: range) else {
                return createDefaultReminder(from: line, timeframe: timeframe)
            }
            
            let priorityRange = Range(match.range(at: 1), in: line)!
            let priorityString = String(line[priorityRange])
            
            let remainingText = line.replacingOccurrences(of: "[\(priorityString)]", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let components = remainingText.components(separatedBy: ":")
            let task = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let description = components.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
            
            return MovingReminder(
                task: task,
                description: description,
                priority: ReminderPriority.fromString(priorityString),
                timeframe: timeframe,
                dueDate: calculateDueDate(for: timeframe)
            )
        }
    }
    
    private func parseProgressAnalysis(_ response: String, rooms: [Room]) -> ProgressAnalysis {
        var status = "Fortschritt wird analysiert..."
        var criticalAreas: [String] = []
        var nextSteps: [String] = []
        var timeEstimate = "Unbekannt"
        
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.lowercased().hasPrefix("status:") {
                status = extractValue(from: trimmedLine)
            } else if trimmedLine.lowercased().hasPrefix("kritisch:") {
                let criticalText = extractValue(from: trimmedLine)
                criticalAreas = criticalText.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else if trimmedLine.lowercased().hasPrefix("nächste schritte:") {
                let stepsText = extractValue(from: trimmedLine)
                nextSteps = stepsText.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else if trimmedLine.lowercased().hasPrefix("zeitschätzung:") {
                timeEstimate = extractValue(from: trimmedLine)
            }
        }
        
        return ProgressAnalysis(
            overallStatus: status,
            completionPercentage: calculateOverallProgress(rooms: rooms),
            criticalAreas: criticalAreas,
            nextSteps: nextSteps,
            timeEstimate: timeEstimate,
            recommendations: generateProgressRecommendations(rooms: rooms)
        )
    }
    
    private func parseSolutions(from response: String) -> [String] {
        return response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { String($0) }
    }
    
    private func parseChecklist(from response: String, situation: MovingSituation) -> MovingChecklist {
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("[ ]") || $0.hasPrefix("[x]") }
        
        let items = lines.map { line in
            let isCompleted = line.hasPrefix("[x]")
            let taskText = line.replacingOccurrences(of: isCompleted ? "[x]" : "[ ]", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extrahiere Zeitschätzung falls vorhanden
            let timePattern = #"\(ca\.\s*(\d+)\s*(Min|Std|min|std)\)"#
            var estimatedTime: TimeInterval = 0
            
            if let regex = try? NSRegularExpression(pattern: timePattern),
               let match = regex.firstMatch(in: taskText, range: NSRange(taskText.startIndex..., in: taskText)) {
                
                let numberRange = Range(match.range(at: 1), in: taskText)!
                let unitRange = Range(match.range(at: 2), in: taskText)!
                
                let number = Double(taskText[numberRange]) ?? 0
                let unit = String(taskText[unitRange]).lowercased()
                
                estimatedTime = unit.contains("std") ? number * 3600 : number * 60
            }
            
            return ChecklistItem(
                task: taskText.replacingOccurrences(of: #"\(ca\..*?\)"#, with: "", options: .regularExpression),
                isCompleted: isCompleted,
                estimatedTime: estimatedTime
            )
        }
        
        return MovingChecklist(
            situation: situation,
            items: items,
            estimatedTotalTime: items.reduce(0) { $0 + $1.estimatedTime }
        )
    }
    
    private func parseWeatherTips(from response: String, condition: WeatherCondition) -> [WeatherTip] {
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains(":") }
        
        return lines.map { line in
            let components = line.components(separatedBy: ":")
            let area = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let tip = components.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
            
            return WeatherTip(
                weatherCondition: condition,
                area: area,
                tip: tip,
                importance: determineWeatherTipImportance(condition: condition)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchAllRooms() throws -> [Room] {
        let request: NSFetchRequest<Room> = Room.fetchRequest()
        return try viewContext.fetch(request)
    }
    
    private func updateMovingPhase() {
        // Bestimme aktuelle Phase basierend auf Fortschritt
        do {
            let rooms = try fetchAllRooms()
            let totalBoxes = rooms.reduce(0) { $0 + $1.totalBoxes }
            let packedBoxes = rooms.reduce(0) { $0 + $1.packedBoxes }
            
            if totalBoxes == 0 {
                movingPhase = .planning
            } else if packedBoxes == 0 {
                movingPhase = .preparation
            } else if packedBoxes < totalBoxes {
                movingPhase = .packing
            } else {
                movingPhase = .transport
            }
        } catch {
            movingPhase = .planning
        }
    }
    
    private func estimateMovingDate(based rooms: [Room]) -> Date {
        // Vereinfachte Schätzung basierend auf Fortschritt
        let totalWork = rooms.reduce(0) { $0 + $1.totalBoxes }
        let completedWork = rooms.reduce(0) { $0 + $1.packedBoxes }
        
        if totalWork == 0 || completedWork == totalWork {
            return Date().addingTimeInterval(7 * 24 * 3600) // 1 Woche
        }
        
        let remainingWork = totalWork - completedWork
        let estimatedDays = max(1, remainingWork / 5) // 5 Kisten pro Tag angenommen
        
        return Date().addingTimeInterval(TimeInterval(estimatedDays * 24 * 3600))
    }
    
    private func daysBetween(_ startDate: Date, and endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(0, components.day ?? 0)
    }
    
    private func createDefaultReminder(from line: String, timeframe: ReminderTimeframe) -> MovingReminder {
        return MovingReminder(
            task: line,
            description: "",
            priority: .medium,
            timeframe: timeframe,
            dueDate: calculateDueDate(for: timeframe)
        )
    }
    
    private func calculateDueDate(for timeframe: ReminderTimeframe) -> Date {
        let calendar = Calendar.current
        
        switch timeframe {
        case .today:
            return calendar.endOfDay(for: Date()) ?? Date()
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        case .thisWeek:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        case .nextWeek:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date()
        }
    }
    
    private func estimateImplementationTime(_ content: String) -> TimeInterval {
        // Einfache Schätzung basierend auf Content-Länge und Schlüsselwörtern
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).count
        let baseTime = min(60.0, Double(wordCount) * 3.0) // 3 Sekunden pro Wort, max 1 Minute
        
        if content.lowercased().contains("packen") {
            return baseTime * 10 // Packen dauert länger
        } else if content.lowercased().contains("organisieren") {
            return baseTime * 5
        } else {
            return baseTime
        }
    }
    
    private func calculateOverallProgress(rooms: [Room]) -> Double {
        guard !rooms.isEmpty else { return 0 }
        
        let totalProgress = rooms.reduce(0) { $0 + Double($1.packingProgress) }
        return totalProgress / Double(rooms.count)
    }
    
    private func generateProgressRecommendations(rooms: [Room]) -> [String] {
        var recommendations: [String] = []
        
        let notStartedRooms = rooms.filter { $0.packingProgress == 0 }
        if !notStartedRooms.isEmpty {
            recommendations.append("Beginnen Sie mit dem Packen in: \(notStartedRooms.map { $0.displayName }.joined(separator: ", "))")
        }
        
        let slowRooms = rooms.filter { $0.packingProgress > 0 && $0.packingProgress < 0.5 }
        if !slowRooms.isEmpty {
            recommendations.append("Beschleunigen Sie das Packen in: \(slowRooms.map { $0.displayName }.joined(separator: ", "))")
        }
        
        return recommendations
    }
    
    private func suggestResources(for problem: MovingProblem) -> [String] {
        switch problem {
        case .packingDelay:
            return ["Zusätzliche Helfer kontaktieren", "Professionellen Packservice beauftragen", "Prioritäten neu setzen"]
        case .transportIssues:
            return ["Alternative Umzugsfirma suchen", "Größeren LKW mieten", "Transport auf mehrere Tage aufteilen"]
        case .damageControl:
            return ["Versicherung kontaktieren", "Schadensdokumentation erstellen", "Reparatur-Services finden"]
        case .timeConstraints:
            return ["Zeitplan überarbeiten", "Nicht-essentielles später transportieren", "Express-Services nutzen"]
        case .weatherProblems:
            return ["Wetterschutz besorgen", "Umzug verschieben", "Indoor-Zwischenlagerung organisieren"]
        }
    }
    
    private func estimateResolutionTime(for problem: MovingProblem) -> TimeInterval {
        switch problem {
        case .packingDelay: return 4 * 3600 // 4 Stunden
        case .transportIssues: return 2 * 3600 // 2 Stunden
        case .damageControl: return 1 * 3600 // 1 Stunde
        case .timeConstraints: return 30 * 60 // 30 Minuten
        case .weatherProblems: return 1 * 3600 // 1 Stunde
        }
    }
    
    private func determineWeatherTipImportance(condition: WeatherCondition) -> WeatherTipImportance {
        switch condition {
        case .sunny: return .low
        case .cloudy: return .low
        case .rainy: return .high
        case .snowy: return .high
        case .windy: return .medium
        case .stormy: return .critical
        }
    }
    
    private func extractValue(from line: String) -> String {
        let components = line.components(separatedBy: ":")
        if components.count > 1 {
            return components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
    
    private func loadUserPreferences() {
        // In einer echten App würden hier die Einstellungen aus UserDefaults oder Core Data geladen
        userPreferences = .default
    }
    
    private func saveUserPreferences() {
        // In einer echten App würden hier die Einstellungen gespeichert
    }
}

// MARK: - Supporting Types

struct MovingContext {
    let phase: MovingPhase
    let totalRooms: Int
    let completedRooms: Int
    let totalBoxes: Int
    let packedBoxes: Int
    let totalItems: Int
    let estimatedMovingDate: Date
    let daysUntilMove: Int
    let preferences: AssistantPreferences
}

enum MovingPhase {
    case planning
    case preparation
    case packing
    case transport
    case unpacking
    case settling
    
    var displayName: String {
        switch self {
        case .planning: return "Planung"
        case .preparation: return "Vorbereitung"
        case .packing: return "Packen"
        case .transport: return "Transport"
        case .unpacking: return "Auspacken"
        case .settling: return "Einrichten"
        }
    }
}

struct MovingTip: Identifiable {
    let id = UUID()
    let category: TipCategory
    let content: String
    let priority: TipPriority
    let phase: MovingPhase
    let estimatedTimeToImplement: TimeInterval
    
    var formattedTime: String {
        let hours = Int(estimatedTimeToImplement) / 3600
        let minutes = (Int(estimatedTimeToImplement) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

enum TipCategory {
    case packing, organization, safety, efficiency, timeline, general
    
    var displayName: String {
        switch self {
        case .packing: return "Packen"
        case .organization: return "Organisation"
        case .safety: return "Sicherheit"
        case .efficiency: return "Effizienz"
        case .timeline: return "Zeitplanung"
        case .general: return "Allgemein"
        }
    }
    
    var iconName: String {
        switch self {
        case .packing: return "shippingbox"
        case .organization: return "list.clipboard"
        case .safety: return "shield"
        case .efficiency: return "speedometer"
        case .timeline: return "clock"
        case .general: return "lightbulb"
        }
    }
    
    static func fromString(_ string: String) -> TipCategory {
        switch string.lowercased() {
        case "packen", "packing": return .packing
        case "organisation", "organization": return .organization
        case "sicherheit", "safety": return .safety
        case "effizienz", "efficiency": return .efficiency
        case "zeitplanung", "timeline": return .timeline
        default: return .general
        }
    }
}

enum TipPriority {
    case low, medium, high, critical
    
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        case .critical: return "Kritisch"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

struct MovingReminder: Identifiable {
    let id = UUID()
    let task: String
    let description: String
    let priority: ReminderPriority
    let timeframe: ReminderTimeframe
    let dueDate: Date
    
    var isOverdue: Bool {
        return Date() > dueDate
    }
    
    var timeUntilDue: String {
        let interval = dueDate.timeIntervalSince(Date())
        
        if interval < 0 {
            return "Überfällig"
        } else if interval < 3600 {
            return "\(Int(interval / 60)) Min"
        } else if interval < 86400 {
            return "\(Int(interval / 3600)) Std"
        } else {
            return "\(Int(interval / 86400)) Tage"
        }
    }
}

enum ReminderPriority {
    case low, medium, high
    
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        }
    }
    
    static func fromString(_ string: String) -> ReminderPriority {
        switch string.lowercased() {
        case "high", "hoch": return .high
        case "low", "niedrig": return .low
        default: return .medium
        }
    }
}

enum ReminderTimeframe {
    case today, tomorrow, thisWeek, nextWeek
    
    var displayName: String {
        switch self {
        case .today: return "Heute"
        case .tomorrow: return "Morgen"
        case .thisWeek: return "Diese Woche"
        case .nextWeek: return "Nächste Woche"
        }
    }
}

struct ProgressAnalysis {
    let overallStatus: String
    let completionPercentage: Double
    let criticalAreas: [String]
    let nextSteps: [String]
    let timeEstimate: String
    let recommendations: [String]
    
    var formattedProgress: String {
        return String(format: "%.1f%%", completionPercentage * 100)
    }
}

enum MovingProblem {
    case packingDelay
    case transportIssues
    case damageControl
    case timeConstraints
    case weatherProblems
    
    var displayName: String {
        switch self {
        case .packingDelay: return "Packverzögerung"
        case .transportIssues: return "Transportprobleme"
        case .damageControl: return "Schadensbegrenzung"
        case .timeConstraints: return "Zeitdruck"
        case .weatherProblems: return "Wetterprobleme"
        }
    }
    
    var description: String {
        switch self {
        case .packingDelay: return "Das Packen dauert länger als geplant"
        case .transportIssues: return "Probleme mit dem Transport oder Umzugswagen"
        case .damageControl: return "Gegenstände wurden beschädigt"
        case .timeConstraints: return "Nicht genug Zeit für den geplanten Umzug"
        case .weatherProblems: return "Schlechtes Wetter erschwert den Umzug"
        }
    }
    
    var urgencyLevel: UrgencyLevel {
        switch self {
        case .packingDelay: return .medium
        case .transportIssues: return .high
        case .damageControl: return .medium
        case .timeConstraints: return .high
        case .weatherProblems: return .medium
        }
    }
}

enum UrgencyLevel {
    case low, medium, high, critical
    
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        case .critical: return "Kritisch"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

struct EmergencyAssistance {
    let problem: MovingProblem
    let urgencyLevel: UrgencyLevel
    let solutions: [String]
    let resources: [String]
    let timeEstimate: TimeInterval
    
    var formattedTimeEstimate: String {
        let hours = Int(timeEstimate) / 3600
        let minutes = (Int(timeEstimate) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

enum MovingSituation {
    case firstTimeMove
    case longDistanceMove
    case lastMinuteMove
    case movingWithKids
    case movingWithPets
    case movingOffice
    
    var displayName: String {
        switch self {
        case .firstTimeMove: return "Erster Umzug"
        case .longDistanceMove: return "Fernumzug"
        case .lastMinuteMove: return "Kurzfristiger Umzug"
        case .movingWithKids: return "Umzug mit Kindern"
        case .movingWithPets: return "Umzug mit Haustieren"
        case .movingOffice: return "Büroumzug"
        }
    }
    
    var description: String {
        switch self {
        case .firstTimeMove: return "Ihr erster Umzug - was Sie beachten sollten"
        case .longDistanceMove: return "Umzug über weite Entfernungen"
        case .lastMinuteMove: return "Umzug mit wenig Vorbereitungszeit"
        case .movingWithKids: return "Umzug mit Kindern - Tipps für Familien"
        case .movingWithPets: return "Umzug mit Haustieren"
        case .movingOffice: return "Büro- oder Geschäftsumzug"
        }
    }
}

struct MovingChecklist {
    let situation: MovingSituation
    let items: [ChecklistItem]
    let estimatedTotalTime: TimeInterval
    
    var completedItems: Int {
        return items.filter { $0.isCompleted }.count
    }
    
    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedItems) / Double(items.count)
    }
    
    var formattedTotalTime: String {
        let hours = Int(estimatedTotalTime) / 3600
        let minutes = (Int(estimatedTotalTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    let task: String
    var isCompleted: Bool
    let estimatedTime: TimeInterval
    
    var formattedTime: String {
        let hours = Int(estimatedTime) / 3600
        let minutes = (Int(estimatedTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

enum WeatherCondition {
    case sunny, cloudy, rainy, snowy, windy, stormy
    
    var displayName: String {
        switch self {
        case .sunny: return "Sonnig"
        case .cloudy: return "Bewölkt"
        case .rainy: return "Regnerisch"
        case .snowy: return "Schnee"
        case .windy: return "Windig"
        case .stormy: return "Sturm"
        }
    }
    
    var iconName: String {
        switch self {
        case .sunny: return "sun.max"
        case .cloudy: return "cloud"
        case .rainy: return "cloud.rain"
        case .snowy: return "cloud.snow"
        case .windy: return "wind"
        case .stormy: return "cloud.bolt"
        }
    }
}

struct WeatherTip {
    let weatherCondition: WeatherCondition
    let area: String
    let tip: String
    let importance: WeatherTipImportance
}

enum WeatherTipImportance {
    case low, medium, high, critical
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

struct AssistantPreferences {
    let workIntensity: WorkIntensity
    let notificationFrequency: NotificationFrequency
    let tipCategories: Set<TipCategory>
    let reminderTimeframes: Set<ReminderTimeframe>
    
    static let `default` = AssistantPreferences(
        workIntensity: .normal,
        notificationFrequency: .daily,
        tipCategories: Set(TipCategory.allCases),
        reminderTimeframes: Set(ReminderTimeframe.allCases)
    )
    
    enum WorkIntensity {
        case relaxed, normal, intensive
        
        var displayName: String {
            switch self {
            case .relaxed: return "Entspannt"
            case .normal: return "Normal"
            case .intensive: return "Intensiv"
            }
        }
    }
    
    enum NotificationFrequency {
        case realtime, hourly, daily, weekly
        
        var displayName: String {
            switch self {
            case .realtime: return "Echtzeit"
            case .hourly: return "Stündlich"
            case .daily: return "Täglich"
            case .weekly: return "Wöchentlich"
            }
        }
    }
}

// MARK: - Extensions

extension TipCategory: CaseIterable {}
extension ReminderTimeframe: CaseIterable {}