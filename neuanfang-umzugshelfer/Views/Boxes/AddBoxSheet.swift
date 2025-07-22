
import SwiftUI

struct AddBoxSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var room: Room
    @State private var boxName = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Neue Kiste erstellen")) {
                    TextField("Name der Kiste", text: $boxName)
                }
            }
            .navigationTitle("Neue Kiste")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let newBox = Box(context: room.managedObjectContext!)
                        newBox.name = boxName
                        newBox.room = room
                        
                        do {
                            try room.managedObjectContext?.save()
                            dismiss()
                        } catch {
                            // Handle the save error
                            print("Failed to save box: \(error.localizedDescription)")
                        }
                    }
                    .disabled(boxName.isEmpty)
                }
            }
            .modifier(liquidGlass(.overlay))
        }
    }
}

#if DEBUG
struct AddBoxSheet_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let room = Room(context: context)
        room.name = "Küche"
        
        return AddBoxSheet(room: room)
    }
}
#endif
