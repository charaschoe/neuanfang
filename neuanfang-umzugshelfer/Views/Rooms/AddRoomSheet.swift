
import SwiftUI

struct AddRoomSheet: View {
    @ObservedObject var viewModel: RoomListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var roomName = ""
    @State private var roomType: RoomType = .other
    @State private var nameValidation = InputValidator.ValidationResult.valid
    @StateObject private var validator = InputValidator.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Raumdetails")) {
                    VStack(alignment: .leading, spacing: 4) {
                        ValidatedTextField(
                            "Name des Raums",
                            text: $roomName,
                            validator: { name in
                                validator.validateName(name)
                            }
                        )
                        .accessibilityLabel("Raumname")
                        .accessibilityHint("Geben Sie den Namen des neuen Raums ein.")
                    }
                    
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
                        let sanitizedName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
                        viewModel.addRoom(name: sanitizedName, type: roomType)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .accessibilityLabel("Speichern")
                    .accessibilityHint("Speichert den neuen Raum.")
                }
            }
            .modifier(liquidGlass(.overlay))
        }
        .onChange(of: roomName) { _, _ in
            validateForm()
        }
        .onAppear {
            validateForm()
        }
    }
    
    private var isFormValid: Bool {
        nameValidation.isValid && !roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func validateForm() {
        nameValidation = validator.validateName(roomName)
    }
}
