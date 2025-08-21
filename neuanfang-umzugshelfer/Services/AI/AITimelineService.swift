//
//  AITimelineService.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import Foundation
import CoreData

/// Service für die Generierung personalisierter Umzugszeitpläne
@MainActor
final class AITimelineService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isGenerating = false
    @Published var currentTimeline: MovingTimeline?
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let foundationService: FoundationModelsService
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(foundationService: FoundationModelsService = .shared,
         viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.foundationService = foundationService
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods
    
    /// Generiert einen personalisierten Umzugszeitplan
    func generatePersonalizedTimeline(
        movingDate: Date,
        rooms: [Room],
        preferences: TimelinePreferences
    ) async throws -> MovingTimeline {
        isGenerating = true
        defer { isGenerating = false }
        
        let context = TimelineContext(
            movingDate: movingDate,
            rooms: rooms,
            preferences: preferences,
            totalItems: rooms.reduce(0) { $0 + $1.totalItems },
            totalBoxes: rooms.reduce(0) { $0 + $1.totalBoxes }
        )
        
        let timeline = try await createTimeline(for: context)
        currentTimeline = timeline
        
        return timeline
    }
    
    /// Aktualisiert bestehenden Zeitplan basierend auf Fortschritt
    func updateTimelineProgress(
        timeline: MovingTimeline,
        completedTasks: [String]
    ) async throws -> MovingTimeline {
        isGenerating = true
        defer { isGenerating = false }
        
        let updatedMilestones = timeline.milestones.map { milestone in
            var updatedMilestone = milestone
            updatedMilestone.tasks = milestone.tasks.map { task in
                var updatedTask = task
                if completedTasks.contains(task.id) {
                    updatedTask.status = .completed
                    updatedTask.completedDate = Date()
                }
                return updatedTask
            }
            updatedMilestone.updateProgress()
            return updatedMilestone
        }
        
        let updatedTimeline = MovingTimeline(
            movingDate: timeline.movingDate,
            milestones: updatedMilestones,
            preferences: timeline.preferences
        )
        
        currentTimeline = updatedTimeline
        return updatedTimeline
    }
    
    /// Generiert angepasste Empfehlungen basierend auf Verzögerungen
    func generateDelayRecommendations(
        timeline: MovingTimeline,
        delayedTasks: [TimelineTask]
    ) async throws -> [DelayRecommendation] {
        let prompt = buildDelayRecommendationPrompt(timeline: timeline, delayedTasks: delayedTasks)
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 250)
        
        return parseDelayRecommendations(response)
    }
    
    /// Erstellt einen Notfall-Zeitplan für kurzfristige Umzüge
    func generateEmergencyTimeline(
        movingDate: Date,
        rooms: [Room],
        daysAvailable: Int
    ) async throws -> MovingTimeline {
        isGenerating = true
        defer { isGenerating = false }
        
        let emergencyPreferences = TimelinePreferences(
            startTime: 8,
            endTime: 20,
            workDaysOnly: false,
            intensity: .high,
            helpersAvailable: 2
        )
        
        let context = TimelineContext(
            movingDate: movingDate,
            rooms: rooms,
            preferences: emergencyPreferences,
            totalItems: rooms.reduce(0) { $0 + $1.totalItems },
            totalBoxes: rooms.reduce(0) { $0 + $1.totalBoxes }
        )
        
        return try await createEmergencyTimeline(for: context, daysAvailable: daysAvailable)
    }
    
    /// Schätzt den Zeitaufwand für verschiedene Umzugsphasen
    func estimateTimeRequirements(for rooms: [Room]) async throws -> TimeEstimate {
        let totalBoxes = rooms.reduce(0) { $0 + $1.totalBoxes }
        let totalItems = rooms.reduce(0) { $0 + $1.totalItems }
        let fragileItems = rooms.flatMap { $0.boxesArray.flatMap { $0.itemsArray.filter { $0.isFragile } } }.count
        
        let prompt = """
        Schätze den Zeitaufwand für einen Umzug mit folgenden Eigenschaften:
        
        Räume: \(rooms.count)
        Kisten: \(totalBoxes)
        Gegenstände: \(totalItems)
        Zerbrechliche Gegenstände: \(fragileItems)
        
        Gib eine detaillierte Zeitschätzung für:
        1. Vorbereitung (Planen, Organisieren)
        2. Packen
        3. Transport
        4. Auspacken
        5. Nachbereitung
        
        Format: [Phase]: [Stunden]h
        """
        
        let response = try await foundationService.generateText(prompt: prompt, maxTokens: 200)
        return parseTimeEstimate(response)
    }
    
    // MARK: - Private Methods
    
    private func createTimeline(for context: TimelineContext) async throws -> MovingTimeline {
        let milestones = try await generateMilestones(for: context)
        
        return MovingTimeline(
            movingDate: context.movingDate,
            milestones: milestones,
            preferences: context.preferences
        )
    }
    
    private func generateMilestones(for context: TimelineContext) async throws -> [TimelineMilestone] {
        var milestones: [TimelineMilestone] = []
        
        // 8 Wochen vor Umzug: Planung
        if context.weeksUntilMove >= 8 {
            milestones.append(createPlanningMilestone(context: context))
        }
        
        // 6 Wochen vor Umzug: Organisatorisches
        if context.weeksUntilMove >= 6 {
            milestones.append(createOrganizationalMilestone(context: context))
        }
        
        // 4 Wochen vor Umzug: Vorbereitung
        if context.weeksUntilMove >= 4 {
            milestones.append(createPreparationMilestone(context: context))
        }
        
        // 2 Wochen vor Umzug: Packen beginnen
        if context.weeksUntilMove >= 2 {
            milestones.append(createInitialPackingMilestone(context: context))
        }
        
        // 1 Woche vor Umzug: Intensives Packen
        if context.weeksUntilMove >= 1 {
            milestones.append(createIntensivePackingMilestone(context: context))
        }
        
        // Umzugstag
        milestones.append(createMovingDayMilestone(context: context))
        
        // Nach dem Umzug
        milestones.append(createPostMoveMilestone(context: context))
        
        return milestones
    }
    
    private func createEmergencyTimeline(for context: TimelineContext, daysAvailable: Int) async throws -> MovingTimeline {
        var milestones: [TimelineMilestone] = []
        
        // Sofortige Maßnahmen
        milestones.append(createEmergencyPreparationMilestone(context: context))
        
        // Packen (parallel zu Organisierung)
        milestones.append(createEmergencyPackingMilestone(context: context))
        
        // Umzugstag
        milestones.append(createMovingDayMilestone(context: context))
        
        return MovingTimeline(
            movingDate: context.movingDate,
            milestones: milestones,
            preferences: context.preferences
        )
    }
    
    // MARK: - Milestone Creation Methods
    
    private func createPlanningMilestone(context: TimelineContext) -> TimelineMilestone {
        let dueDate = Calendar.current.date(byAdding: .weekOfYear, value: -8, to: context.movingDate) ?? context.movingDate
        
        let tasks = [
            TimelineTask(
                title: "Umzugstermin festlegen",
                description: "Finalen Umzugstermin bestätigen und in Kalender eintragen",
                category: .planning,
                estimatedDuration: 0.5,
                priority: .high
            ),
            TimelineTask(
                title: "Budget planen",
                description: "Umzugsbudget festlegen und verschiedene Kostenpunkte durchgehen",
                category: .planning,
                estimatedDuration: 2.0,
                priority: .medium
            ),
            TimelineTask(
                title: "Umzugsunternehmen recherchieren",
                description: "Angebote von Umzugsunternehmen einholen und vergleichen",
                category: .planning,
                estimatedDuration: 4.0,
                priority: .medium
            )
        ]
        
        return TimelineMilestone(
            title: "Planung & Vorbereitung",
            dueDate: dueDate,
            tasks: tasks
        )
    }
    
    private func createOrganizationalMilestone(context: TimelineContext) -> TimelineMilestone {
        let dueDate = Calendar.current.date(byAdding: .weekOfYear, value: -6, to: context.movingDate) ?? context.movingDate
        
        let tasks = [
            TimelineTask(
                title: "Verträge kündigen",
                description: "Internet, Strom, Gas und andere Verträge kündigen bzw. ummelden",
                category: .administrative,
                estimatedDuration: 3.0,
                priority: .high
            ),
            TimelineTask(
                title: "Adresse ändern",
                description: "Adressänderung bei Post, Bank, Versicherungen und Behörden",
                category: .administrative,
                estimatedDuration: 2.0,
                priority: .medium
            ),
            TimelineTask(
                title: "Umzugskartons besorgen",
                description: "Ausreichend Umzugskartons und Verpackungsmaterial kaufen",
                category: .preparation,
                estimatedDuration: 1.0,
                priority: .medium
            )
        ]
        
        return TimelineMilestone(
            title: "Organisation & Verwaltung",
            dueDate: dueDate,
            tasks: tasks
        )
    }
    
    private func createPreparationMilestone(context: TimelineContext) -> TimelineMilestone {
        let dueDate = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: context.movingDate) ?? context.movingDate
        
        let tasks = [
            TimelineTask(
                title: "Inventar erstellen",
                description: "Vollständige Liste aller Gegenstände mit der App erstellen",
                category: .preparation,
                estimatedDuration: 4.0,
                priority: .medium
            ),
            TimelineTask(
                title: "Aussortieren",
                description: "Nicht benötigte Gegenstände aussortieren und spenden/verkaufen",
                category: .preparation,
                estimatedDuration: 6.0,
                priority: .medium
            ),
            TimelineTask(
                title: "Sondertermine vereinbaren",
                description: "Termine für Sperrmüll, Reinigung, Übergabe vereinbaren",
                category: .administrative,
                estimatedDuration: 1.0,
                priority: .low
            )
        ]
        
        return TimelineMilestone(
            title: "Vorbereitung & Sortierung",
            dueDate: dueDate,
            tasks: tasks
        )
    }
    
    private func createInitialPackingMilestone(context: TimelineContext) -> TimelineMilestone {
        let dueDate = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: context.movingDate) ?? context.movingDate
        
        let tasks = [
            TimelineTask(
                title: "Nebensächliche Räume packen",
                description: "Keller, Dachboden, Abstellräume komplett packen",
                category: .packing,
                estimatedDuration: 8.0,
                priority: .medium
            ),
            TimelineTask(
                title: "Saisonale Gegenstände verpacken",
                description: "Winterkleidung, Sportausrüstung und selten genutzte Gegenstände",
                category: .packing,
                estimatedDuration: 4.0,
                priority: .low
            ),
            TimelineTask(
                title: "Bücher und Dokumente",
                description: "Alle Bücher und wichtige Dokumente sicher verpacken",
                category: .packing,
                estimatedDuration: 3.0,
                priority: .medium
            )
        ]
        
        return TimelineMilestone(
            title: "Erstes Packen",
            dueDate: dueDate,
            tasks: tasks
        )
    }
    
    private func createIntensivePackingMilestone(context: TimelineContext) -> TimelineMilestone {
        let dueDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: context.movingDate) ?? context.movingDate
        
        let tasks = [
            TimelineTask(
                title: "Haupträume packen",
                description: "Wohnzimmer, Schlafzimmer und Büro vollständig packen",
                category: .packing,
                estimatedDuration: 12.0,
                priority: .high
            ),
            TimelineTask(
                title: "Küche vorbereiten",
                description: "Küche bis auf Notwendigstes packen, zerbrechlich sichern",
                category: .packing,
                estimatedDuration: 6.0,
                priority: .high
            ),
            TimelineTask(
                title: "Reinigung beauftragen",
                description: "Endreinigung der alten Wohnung organisieren",
                category: .administrative,
                estimatedDuration: 1.0,
                priority: .medium
            )
        ]
        
        return TimelineMilestone(
            title: "Intensives Packen",
            dueDate: dueDate,
            tasks: tasks
        )
    }
    
    private func createMovingDayMilestone(context: TimelineContext) -> TimelineMilestone {
        let tasks = [
            TimelineTask(
                title: "Letzte Gegenstände packen",
                description: "Restliche Gegenstände, Reinigungsmittel und persönliche Sachen",
                category: .packing,
                estimatedDuration: 2.0,
                priority: .high
            ),
            TimelineTask(
                title: "Transport koordinieren",
                description: "Umzugswagen beladen und Transport überwachen",
                category: .transport,
                estimatedDuration: 8.0,
                priority: .high
            ),
            TimelineTask(
                title: "Wohnungsübergabe",
                description: "Alte Wohnung übergeben und neue Wohnung übernehmen",
                category: .administrative,
                estimatedDuration: 2.0,
                priority: .high
            )
        ]
        
        return TimelineMilestone(
            title: "Umzugstag",
            dueDate: context.movingDate,
            tasks: tasks
        )
    }
    
    private func createPostMoveMilestone(context: TimelineContext) -> TimelineMilestone {
        let dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: context.movingDate) ?? context.movingDate
        
        let tasks = [
            TimelineTask(
                title: "Wichtigste Gegenstände auspacken",
                description: "Kleidung, Küchengrundasusstattung und Hygieneartikel",
                category: .unpacking,
                estimatedDuration: 4.0,
                priority: .high
            ),
            TimelineTask(
                title: "Anmeldungen erledigen",
                description: "Einwohnermeldeamt, neue Verträge, Nachsendeauftrag bestätigen",
                category: .administrative,
                estimatedDuration: 3.0,
                priority: .medium
            ),
            TimelineTask(
                title: "Umgebung erkunden",
                description: "Supermärkte, Ärzte und wichtige Einrichtungen finden",
                category: .settling,
                estimatedDuration: 2.0,
                priority: .low
            )
        ]
        
        return TimelineMilestone(
            title: "Nach dem Umzug",
            dueDate: dueDate,
            tasks: tasks
        )
    }
    
    private func createEmergencyPreparationMilestone(context: TimelineContext) -> TimelineMilestone {
        let dueDate = Calendar.current.date(byAdding: .day, value: -1, to: context.movingDate) ?? context.movingDate
        
        let tasks = [
            TimelineTask(
                title: "Sofort Umzugsunternehmen kontaktieren",
                description: "Verfügbare Umzugsunternehmen für kurzfristige Termine anfragen",
                category: .planning,
                estimatedDuration: 2.0,
                priority: .critical
            ),
            TimelineTask(
                title: "Notfall-Packmaterial besorgen",
                description: "Kartons, Klebeband und Verpackungsmaterial sofort kaufen",
                category: .preparation,
                estimatedDuration: 1.0,
                priority: .critical
            ),
            TimelineTask(
                title: "Helfer mobilisieren",
                description: "Familie und Freunde um Hilfe bitten",
                category: .planning,
                estimatedDuration: 1.0,
                priority: .high
            )
        ]
        
        return TimelineMilestone(
            title: "Notfall-Vorbereitung",
            dueDate: dueDate,
            tasks: tasks
        )
    }
    
    private func createEmergencyPackingMilestone(context: TimelineContext) -> TimelineMilestone {
        let dueDate = Calendar.current.date(byAdding: .hour, value: -12, to: context.movingDate) ?? context.movingDate
        
        let tasks = [
            TimelineTask(
                title: "Express-Packen aller Räume",
                description: "Alle Gegenstände schnell aber sicher verpacken - Priorität auf Wichtiges",
                category: .packing,
                estimatedDuration: 16.0,
                priority: .critical
            ),
            TimelineTask(
                title: "Überlebenstasche packen",
                description: "Wichtigste Gegenstände für erste Tage separat verpacken",
                category: .packing,
                estimatedDuration: 1.0,
                priority: .critical
            )
        ]
        
        return TimelineMilestone(
            title: "Express-Packen",
            dueDate: dueDate,
            tasks: tasks
        )
    }
    
    // MARK: - Helper Methods
    
    private func buildDelayRecommendationPrompt(timeline: MovingTimeline, delayedTasks: [TimelineTask]) -> String {
        let delayedTaskTitles = delayedTasks.map { $0.title }.joined(separator: ", ")
        
        return """
        Ein Umzug ist verzögert. Folgende Aufgaben sind im Rückstand:
        \(delayedTaskTitles)
        
        Umzugstermin: \(timeline.movingDate.formatted())
        Verfügbare Tageszeit: \(timeline.preferences.startTime):00 - \(timeline.preferences.endTime):00
        Helfer verfügbar: \(timeline.preferences.helpersAvailable)
        
        Gib praktische Empfehlungen, wie die Verzögerung aufgeholt werden kann:
        """
    }
    
    private func parseDelayRecommendations(_ response: String) -> [DelayRecommendation] {
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return lines.enumerated().map { index, line in
            DelayRecommendation(
                title: "Empfehlung \(index + 1)",
                description: line,
                priority: index < 2 ? .high : .medium,
                estimatedTimeReduction: Double.random(in: 1...4)
            )
        }
    }
    
    private func parseTimeEstimate(_ response: String) -> TimeEstimate {
        // Vereinfachte Parsing-Logik
        var preparationHours = 8.0
        var packingHours = 12.0
        var transportHours = 6.0
        var unpackingHours = 16.0
        var postMoveHours = 4.0
        
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            if line.lowercased().contains("vorbereitung") {
                preparationHours = extractHours(from: line) ?? preparationHours
            } else if line.lowercased().contains("packen") {
                packingHours = extractHours(from: line) ?? packingHours
            } else if line.lowercased().contains("transport") {
                transportHours = extractHours(from: line) ?? transportHours
            } else if line.lowercased().contains("auspacken") {
                unpackingHours = extractHours(from: line) ?? unpackingHours
            } else if line.lowercased().contains("nachbereitung") {
                postMoveHours = extractHours(from: line) ?? postMoveHours
            }
        }
        
        return TimeEstimate(
            preparation: preparationHours,
            packing: packingHours,
            transport: transportHours,
            unpacking: unpackingHours,
            postMove: postMoveHours
        )
    }
    
    private func extractHours(from text: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)h"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        return Double(text[range])
    }
}

// MARK: - Supporting Types

struct MovingTimeline {
    let movingDate: Date
    let milestones: [TimelineMilestone]
    let preferences: TimelinePreferences
    
    var overallProgress: Double {
        let totalTasks = milestones.flatMap { $0.tasks }.count
        let completedTasks = milestones.flatMap { $0.tasks }.filter { $0.status == .completed }.count
        
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var nextMilestone: TimelineMilestone? {
        return milestones.first { !$0.isCompleted }
    }
    
    var criticalTasks: [TimelineTask] {
        return milestones.flatMap { $0.tasks }.filter { $0.priority == .critical && $0.status != .completed }
    }
}

struct TimelineMilestone {
    let title: String
    let dueDate: Date
    var tasks: [TimelineTask]
    
    var isCompleted: Bool {
        return !tasks.isEmpty && tasks.allSatisfy { $0.status == .completed }
    }
    
    var progress: Double {
        let completedTasks = tasks.filter { $0.status == .completed }.count
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks) / Double(tasks.count)
    }
    
    var totalEstimatedHours: Double {
        return tasks.reduce(0) { $0 + $1.estimatedDuration }
    }
    
    mutating func updateProgress() {
        // Automatisch als erledigt markieren wenn alle Tasks erledigt sind
        if !tasks.isEmpty && tasks.allSatisfy({ $0.status == .completed }) {
            // Milestone abgeschlossen
        }
    }
}

struct TimelineTask {
    let id = UUID().uuidString
    let title: String
    let description: String
    let category: TaskCategory
    let estimatedDuration: Double // in Stunden
    let priority: TaskPriority
    var status: TaskStatus = .pending
    var completedDate: Date?
    
    enum TaskCategory {
        case planning
        case administrative
        case preparation
        case packing
        case transport
        case unpacking
        case settling
        
        var displayName: String {
            switch self {
            case .planning: return "Planung"
            case .administrative: return "Verwaltung"
            case .preparation: return "Vorbereitung"
            case .packing: return "Packen"
            case .transport: return "Transport"
            case .unpacking: return "Auspacken"
            case .settling: return "Einleben"
            }
        }
        
        var iconName: String {
            switch self {
            case .planning: return "calendar"
            case .administrative: return "doc.text"
            case .preparation: return "list.bullet.clipboard"
            case .packing: return "shippingbox"
            case .transport: return "truck"
            case .unpacking: return "shippingbox.fill"
            case .settling: return "house"
            }
        }
        
        var color: String {
            switch self {
            case .planning: return "blue"
            case .administrative: return "orange"
            case .preparation: return "green"
            case .packing: return "purple"
            case .transport: return "red"
            case .unpacking: return "indigo"
            case .settling: return "teal"
            }
        }
    }
    
    enum TaskPriority {
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
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    enum TaskStatus {
        case pending
        case inProgress
        case completed
        case overdue
        
        var displayName: String {
            switch self {
            case .pending: return "Ausstehend"
            case .inProgress: return "In Bearbeitung"
            case .completed: return "Erledigt"
            case .overdue: return "Überfällig"
            }
        }
        
        var iconName: String {
            switch self {
            case .pending: return "circle"
            case .inProgress: return "clock"
            case .completed: return "checkmark.circle.fill"
            case .overdue: return "exclamationmark.triangle.fill"
            }
        }
    }
}

struct TimelinePreferences {
    let startTime: Int // Stunde (0-23)
    let endTime: Int // Stunde (0-23)
    let workDaysOnly: Bool
    let intensity: WorkIntensity
    let helpersAvailable: Int
    
    enum WorkIntensity {
        case relaxed, normal, high
        
        var displayName: String {
            switch self {
            case .relaxed: return "Entspannt"
            case .normal: return "Normal"
            case .high: return "Intensiv"
            }
        }
        
        var hoursPerDay: Double {
            switch self {
            case .relaxed: return 4.0
            case .normal: return 6.0
            case .high: return 8.0
            }
        }
    }
}

struct TimelineContext {
    let movingDate: Date
    let rooms: [Room]
    let preferences: TimelinePreferences
    let totalItems: Int
    let totalBoxes: Int
    
    var weeksUntilMove: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.weekOfYear], from: now, to: movingDate)
        return max(0, components.weekOfYear ?? 0)
    }
}

struct DelayRecommendation {
    let title: String
    let description: String
    let priority: TaskPriority
    let estimatedTimeReduction: Double // Stunden
    
    var formattedTimeReduction: String {
        return String(format: "%.1f Stunden sparen", estimatedTimeReduction)
    }
}

struct TimeEstimate {
    let preparation: Double
    let packing: Double
    let transport: Double
    let unpacking: Double
    let postMove: Double
    
    var total: Double {
        return preparation + packing + transport + unpacking + postMove
    }
    
    var formattedTotal: String {
        let days = Int(total / 8) // 8 Stunden pro Arbeitstag
        let remainingHours = Int(total.truncatingRemainder(dividingBy: 8))
        
        if days > 0 {
            return "\(days) Tage, \(remainingHours) Stunden"
        } else {
            return "\(Int(total)) Stunden"
        }
    }
}

// MARK: - Error Types

enum TimelineError: LocalizedError {
    case invalidDate
    case noRooms
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "Ungültiges Umzugsdatum"
        case .noRooms:
            return "Keine Räume zum Planen vorhanden"
        case .configurationError:
            return "Fehler in der Timeline-Konfiguration"
        }
    }
}