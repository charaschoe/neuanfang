
import SwiftUI

struct BoxDetailView: View {
    @ObservedObject var viewModel: BoxDetailViewModel

    var body: some View {
        Form {
            Section(header: Text("Kisten-Details")) {
                Text(viewModel.boxName)
                Text("Priorität: \(viewModel.boxPriority.displayName)")
                Text("Geschätzter Wert: \(viewModel.boxEstimatedValue, specifier: "%.2f") €")
            }

            Section(header: Text("Aktionen")) {
                Button(action: { viewModel.showingQRCode = true }) {
                    Label("QR-Code anzeigen", systemImage: "qrcode.viewfinder")
                }
                .modifier(interactiveGlass())

                Button(action: { viewModel.showingNFCWriter = true }) {
                    Label("NFC-Tag beschreiben", systemImage: "sensor.tag.radiowaves.forward.fill")
                }
                .modifier(interactiveGlass())
            }

            Section(header: Text("Gegenstände")) {
                NavigationLink(destination: ItemListView(box: viewModel.box!)) {
                    Text("Alle Gegenstände anzeigen")
                }
            }
        }
        .navigationTitle(viewModel.boxName)
        .sheet(isPresented: $viewModel.showingQRCode) {
            if let qrCodeImage = viewModel.generateQRCode() {
                QRCodeView(qrCodeImage: qrCodeImage)
            }
        }
        .sheet(isPresented: $viewModel.showingNFCWriter) {
            NFCWriterView(dataToWrite: viewModel.getQRCodeData()?.qrCode ?? "")
        }
        .modifier(liquidGlass(.floating))
    }
}
