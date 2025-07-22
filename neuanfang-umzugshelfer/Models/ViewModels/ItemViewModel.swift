
import SwiftUI
import CoreData

class ItemViewModel: ObservableObject {
    @Published var item: Item
    @Published var errorMessage: String?
    @Published var isLoading = false

    init(item: Item) {
        self.item = item
    }

    func save() {
        do {
            try item.managedObjectContext?.save()
        } catch {
            errorMessage = "Fehler beim Speichern des Gegenstands: \(error.localizedDescription)"
        }
    }
    
    func updateItem(name: String, value: Double, isFragile: Bool) {
        item.name = name
        item.value = value
        item.isFragile = isFragile
        save()
    }

    func deleteItem() {
        guard let context = item.managedObjectContext else { return }
        context.delete(item)
        save()
    }
}
