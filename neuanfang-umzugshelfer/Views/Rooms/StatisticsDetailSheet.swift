
import SwiftUI

// Assuming RoomStatistics is defined elsewhere, likely in the ViewModel

struct StatisticsDetailSheet: View {
    let statistics: RoomStatistics
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gesamtstatistik")) {
                    Text("Räume Gesamt: \(statistics.totalRooms)")
                    Text("Räume abgeschlossen: \(statistics.completedRooms)")
                    Text("Fortschritt: \(statistics.completionPercentage)%")
                }
                
                Section(header: Text("Kisten & Gegenstände")) {
                    Text("Kisten Gesamt: \(statistics.totalBoxes)")
                    Text("Kisten gepackt: \(statistics.packedBoxes)")
                    Text("Gegenstände Gesamt: \(statistics.totalItems)")
                }
            }
            .navigationTitle("Statistik-Details")
            .modifier(liquidGlass(.overlay))
        }
    }
}
