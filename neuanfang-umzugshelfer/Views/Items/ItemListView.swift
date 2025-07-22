
import SwiftUI

struct ItemListView: View {
    @ObservedObject var box: Box
    @State private var showingAddItemSheet = false

    var body: some View {
        VStack {
            let items = box.items as? Set<Item> ?? []
            List(items.sorted(by: { $0.name ?? "" < $1.name ?? "" })) { item in
                NavigationLink(destination: ItemDetailView(viewModel: ItemViewModel(item: item))) {
                    Text(item.name ?? "Unbenannter Gegenstand")
                        .padding()
                        .modifier(interactiveGlass())
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Gegenstände in \(box.name ?? "Unbenannte Kiste")")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddItemSheet.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .modifier(interactiveGlass())
                }
            }
        }
        .sheet(isPresented: $showingAddItemSheet) {
            AddItemSheet(box: box)
        }
        .modifier(liquidGlass(.toolbar))
    }
}

#if DEBUG
struct ItemListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let box = Box(context: context)
        box.name = "Geschirr"
        
        let item1 = Item(context: context)
        item1.name = "Teller"
        item1.box = box
        
        let item2 = Item(context: context)
        item2.name = "Tassen"
        item2.box = box
        
        return NavigationView {
            ItemListView(box: box)
        }
    }
}
#endif
