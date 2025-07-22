
import SwiftUI

struct ItemDetailView: View {
    @ObservedObject var viewModel: ItemViewModel

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                Text(viewModel.item.name ?? "Unbenannter Gegenstand")
                Text("Wert: \(viewModel.item.value, specifier: "%.2f") €")
                Text(viewModel.item.isFragile ? "Zerbrechlich" : "Nicht zerbrechlich")
            }
            
            if let imageData = viewModel.item.photo, let uiImage = UIImage(data: imageData) {
                Section(header: Text("Foto")) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
            }
        }
        .navigationTitle(viewModel.item.name ?? "Unbenannter Gegenstand")
        .modifier(liquidGlass(.floating))
    }
}

#if DEBUG
struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let item = Item(context: context)
        item.name = "Lampe"
        item.value = 120.50
        item.isFragile = true
        
        let viewModel = ItemViewModel(item: item)
        
        return NavigationView {
            ItemDetailView(viewModel: viewModel)
        }
    }
}
#endif
