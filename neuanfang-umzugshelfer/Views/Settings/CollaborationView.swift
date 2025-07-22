
import SwiftUI

struct CollaborationView: View {
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Teile deinen Umzug mit Familie und Freunden.")
                .font(.headline)
                .multilineTextAlignment(.center)

            Button(action: { 
                showShareSheet = true
            }) {
                Label("Personen einladen", systemImage: "person.crop.circle.badge.plus")
            }
            .modifier(interactiveGlass())
        }
        .padding()
        .modifier(liquidGlass(.floating))
        .navigationTitle("Zusammenarbeit")
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: ["Ich lade dich ein, mir beim Umzug zu helfen! Lade die neuanfang: Umzugshelfer App herunter."])
        }
    }
}

#if DEBUG
struct CollaborationView_Previews: PreviewProvider {
    static var previews: some View {
        CollaborationView()
    }
}
#endif
