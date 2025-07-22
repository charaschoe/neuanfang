
import SwiftUI

struct TruckLoadingView: View {
    var body: some View {
        VStack {
            Text("3D Truck Loading Visualisierung")
                .font(.largeTitle)
                .modifier(liquidGlass(.floating))
            
            Text("Diese Funktion ist in Entwicklung und wird eine interaktive 3D-Ansicht Ihrer Kisten im Umzugswagen bieten.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .modifier(liquidGlass(.floating))
        }
        .navigationTitle("Ladeplaner")
    }
}

#if DEBUG
struct TruckLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        TruckLoadingView()
    }
}
#endif
