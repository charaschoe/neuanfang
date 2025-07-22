
import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.timelineEvents) { event in
                VStack(alignment: .leading) {
                    Text(event.title)
                        .font(.headline)
                    Text(event.description)
                        .font(.subheadline)
                    Text(event.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .modifier(liquidGlass(.floating))
            }
            .navigationTitle("Umzugs-Timeline")
            .onAppear {
                viewModel.fetchTimelineEvents()
            }
            .modifier(liquidGlass(.toolbar))
        }
    }
}

#if DEBUG
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineView()
    }
}
#endif
