
import SwiftUI

struct AddRoomSheet: View {
    @ObservedObject var viewModel: RoomListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var roomName = ""
    @State private var roomType: RoomType = .other
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Raumdetails")) {
                    TextField("Name des Raums", text: $roomName)
                        .accessibilityLabel("Raumname")
                        .accessibilityHint("Geben Sie den Namen des neuen Raums ein.")
                    Picker("Raumtyp", selection: $roomType) {
                        ForEach(RoomType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .accessibilityLabel("Raumtyp")
                    .accessibilityHint("Wählen Sie den Typ des Raums aus.")
                }
            }
            .navigationTitle("Neuer Raum")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .accessibilityLabel("Abbrechen")
                        .accessibilityHint("Verwirft die Änderungen und schließt das Fenster.")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        viewModel.addRoom(name: roomName, type: roomType)
                        dismiss()
                    }
                    .disabled(roomName.isEmpty)
                    .accessibilityLabel("Speichern")
                    .accessibilityHint("Speichert den neuen Raum.")
                }
            }
            .modifier(liquidGlass(.overlay))
        }
    }
}
