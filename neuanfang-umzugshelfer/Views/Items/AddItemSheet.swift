
import SwiftUI

struct AddItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var box: Box
    @State private var itemName = ""
    @State private var itemValue = ""
    @State private var isFragile = false
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @State private var suggestedCategory: ItemCategory = .other
    @State private var predictedIsFragile: Bool = false
    @StateObject private var cameraService = CameraService()
    
    // Validation states
    @State private var nameValidation = InputValidator.ValidationResult.valid
    @State private var valueValidation = InputValidator.ValidationResult.valid
    @StateObject private var validator = InputValidator.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Neuen Gegenstand erstellen")) {
                    VStack(alignment: .leading, spacing: 4) {
                        ValidatedTextField(
                            "Name des Gegenstands",
                            text: $itemName,
                            validator: { name in
                                validator.validateName(name)
                            }
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ValidatedTextField(
                            "Wert",
                            text: $itemValue,
                            validator: { value in
                                validator.validateValue(value)
                            },
                            keyboardType: .decimalPad
                        )
                    }
                    
                    Toggle("Zerbrechlich", isOn: $isFragile)
                }
                
                Section(header: Text("Foto")) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                showingImagePicker = true
                            }
                    } else {
                        Button("Foto hinzufügen") {
                            showingImagePicker = true
                        }
                        .modifier(interactiveGlass())
                    }
                    
                    if cameraService.isProcessing {
                        ProgressView("Analysiere Bild...")
                    }
                    
                    if !cameraService.detectedObjects.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Erkannte Objekte:")
                                .font(.caption)
                            ForEach(cameraService.detectedObjects, id: \.label) { object in
                                Text("- \(object.label) (\(object.confidencePercentage)%)")
                                    .font(.caption2)
                            }
                        }
                    }
                    
                    if suggestedCategory != .other {
                        Text("Vorgeschlagene Kategorie: \(suggestedCategory.displayName)")
                            .font(.caption)
                    }
                    
                    if predictedIsFragile {
                        Text("Zerbrechlichkeit vorhergesagt!")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Neuer Gegenstand")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let sanitizedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let sanitizedValue = itemValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Validate before saving
                        guard validator.validateName(sanitizedName).isValid,
                              validator.validateValue(sanitizedValue).isValid else {
                            return
                        }
                        
                        let newItem = Item(context: box.managedObjectContext!)
                        newItem.name = sanitizedName
                        newItem.value = Double(sanitizedValue) ?? 0.0
                        newItem.isFragile = isFragile
                        newItem.box = box
                        
                        if let image = image {
                            newItem.photo = image.jpegData(compressionQuality: 0.8)
                        }
                        
                        do {
                            try box.managedObjectContext?.save()
                            dismiss()
                        } catch {
                            // Handle the save error
                            print("Failed to save item: \(error.localizedDescription)")
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoCaptureView(image: $image)
                    .onDisappear {
                        if let img = image {
                            Task {
                                let processedImage = await cameraService.processImage(img)
                                self.suggestedCategory = processedImage.suggestedCategory
                                self.predictedIsFragile = processedImage.isFragilePrediction
                                self.isFragile = processedImage.isFragilePrediction // Auto-set fragility
                            }
                        }
                    }
            }
            .onAppear {
                Task {
                    _ = await cameraService.requestCameraPermission()
                }
                validateForm()
            }
            .onChange(of: itemName) { _, _ in
                validateForm()
            }
            .onChange(of: itemValue) { _, _ in
                validateForm()
            }
            .modifier(liquidGlass(.overlay))
        }
    }
    
    private var isFormValid: Bool {
        nameValidation.isValid &&
        valueValidation.isValid &&
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !itemValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func validateForm() {
        nameValidation = validator.validateName(itemName)
        valueValidation = validator.validateValue(itemValue)
    }
}

#if DEBUG
struct AddItemSheet_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let box = Box(context: context)
        box.name = "Küche"
        
        return AddItemSheet(box: box)
    }
}
#endif
