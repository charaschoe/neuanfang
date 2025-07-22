
import SwiftUI

class TimelineViewModel: ObservableObject {
    @Published var timelineEvents: [TimelineEvent] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    func fetchTimelineEvents() {
        // This is sample data. In a real application, you would fetch this from a database or API.
        self.timelineEvents = [
            TimelineEvent(date: Date().addingTimeInterval(-86400 * 14), title: "Mietvertrag unterschrieben", description: "Der neue Mietvertrag wurde unterschrieben."),
            TimelineEvent(date: Date().addingTimeInterval(-86400 * 7), title: "Umzugstermin festgelegt", description: "Der Umzug ist für den 15. August geplant."),
            TimelineEvent(date: Date(), title: "Umzugshelfer organisiert", description: "Freunde und Familie haben zugesagt zu helfen."),
            TimelineEvent(date: Date().addingTimeInterval(86400 * 3), title: "Kisten packen", description: "Beginnen, die ersten Kisten zu packen."),
            TimelineEvent(date: Date().addingTimeInterval(86400 * 7), title: "Ummeldung planen", description: "Termin für die Ummeldung beim Bürgeramt vereinbaren.")
        ]
    }
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let description: String
}
