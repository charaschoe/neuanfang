
import SwiftUI

struct TaskManagementView: View {
    // This is a placeholder for the task management view.
    var body: some View {
        Text("Aufgabenverwaltung")
            .font(.largeTitle)
            .modifier(liquidGlass(.floating))
            .navigationTitle("Aufgaben")
    }
}

#if DEBUG
struct TaskManagementView_Previews: PreviewProvider {
    static var previews: some View {
        TaskManagementView()
    }
}
#endif
