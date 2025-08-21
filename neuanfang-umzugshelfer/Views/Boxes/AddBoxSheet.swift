
import SwiftUI

struct AddBoxSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var room: Room
    @State private var boxName = ""
    @State private var nameValidation = InputValidator.ValidationResult.valid
    @StateObject private var validator = InputValidator.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Neue Kiste erstellen")) {
                    VStack(alignment: .leading, spacing: 4) {
                        ValidatedTextField(
                            "Name der Kiste",
                            text: $boxName,
                            validator: { name in
                                validator.validateName(name)
                            }
                        )
                    }
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
                        let sanitizedName = boxName.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Validate before saving
                        guard validator.validateName(sanitizedName).isValid else {
                            return
                        }
                        
                        let newBox = Box(context: room.managedObjectContext!)
                        newBox.name = sanitizedName
                        newBox.room = room
                        
                        do {
                            try room.managedObjectContext?.save()
                            dismiss()
                        } catch {
                            // Handle the save error
                            print("Failed to save box: \(error.localizedDescription)")
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .modifier(liquidGlass(.overlay))
        }
        .onChange(of: boxName) { _, _ in
            validateForm()
        }
        .onAppear {
            validateForm()
        }
    }
    
    private var isFormValid: Bool {
        nameValidation.isValid && !boxName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func validateForm() {
        nameValidation = validator.validateName(boxName)
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
