
import SwiftUI

struct BoxListView: View {
    @ObservedObject var room: Room
    @State private var showingAddBoxSheet = false
    @FetchRequest var boxes: FetchedResults<Box>

    init(room: Room) {
        self.room = room
        _boxes = FetchRequest<Box>(
            sortDescriptors: [NSSortDescriptor(keyPath: \.name, ascending: true)],
            predicate: NSPredicate(format: "room == %@", room)
        )
    }

    var body: some View {
        VStack {
            List(boxes) { box in
                NavigationLink(destination: BoxDetailView(viewModel: BoxDetailViewModel(box: box))) {
                    Text(box.name ?? "Unbenannte Kiste")
                        .padding()
                        .modifier(interactiveGlass())
                        .accessibilityLabel("Kiste \(box.name ?? "Unbenannte Kiste")")
                        .accessibilityHint("Tippen Sie, um Details zur Kiste anzuzeigen.")
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Kisten in \(room.name ?? "Unbenannter Raum")")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddBoxSheet.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .modifier(interactiveGlass())
                }
                .accessibilityLabel("Neue Kiste hinzufügen")
                .accessibilityHint("Öffnet ein Formular zum Hinzufügen einer neuen Kiste.")
            }
        }
        .sheet(isPresented: $showingAddBoxSheet) {
            AddBoxSheet(room: room)
        }
        .modifier(liquidGlass(.toolbar))
    }
}

#if DEBUG
struct BoxListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let room = Room(context: context)
        room.name = "Wohnzimmer"
        
        let box1 = Box(context: context)
        box1.name = "Bücher"
        box1.room = room
        
        let box2 = Box(context: context)
        box2.name = "Deko"
        box2.room = room
        
        return NavigationView {
            BoxListView(room: room)
        }
    }
}
#endif
