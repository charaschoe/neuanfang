
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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Neuen Gegenstand erstellen")) {
                    TextField("Name des Gegenstands", text: $itemName)
                    TextField("Wert", text: $itemValue)
                        .keyboardType(.decimalPad)
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
                        let newItem = Item(context: box.managedObjectContext!)
                        newItem.name = itemName
                        newItem.value = Double(itemValue) ?? 0.0
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
                    .disabled(itemName.isEmpty)
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
            }
            .modifier(liquidGlass(.overlay))
        }
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
