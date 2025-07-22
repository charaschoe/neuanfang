
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                NavigationLink(destination: DataExportView()) {
                    Label("Datenexport", systemImage: "doc.circle")
                }
                
                NavigationLink(destination: CollaborationView()) {
                    Label("Zusammenarbeit", systemImage: "person.2.circle")
                }
            }
            .navigationTitle("Einstellungen")
            .modifier(liquidGlass(.toolbar))
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
