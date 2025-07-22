
import SwiftUI

struct NFCWriterView: View {
    @State private var isWriting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    let dataToWrite: String

    var body: some View {
        VStack(spacing: 20) {
            Text("NFC Tag beschreiben")
                .font(.largeTitle)
                .modifier(liquidGlass(.floating))

            if isWriting {
                ProgressView()
                Text("Bitte NFC-Tag an das iPhone halten...")
            } else {
                Button(action: { 
                    isWriting = true
                    NFCService().writeNFCTag(with: dataToWrite) { result in
                        DispatchQueue.main.async {
                            isWriting = false
                            switch result {
                            case .success:
                                successMessage = "NFC-Tag erfolgreich beschrieben!"
                                errorMessage = nil
                            case .failure(let error):
                                errorMessage = "Fehler beim Beschreiben des NFC-Tags: \(error.localizedDescription)"
                                successMessage = nil
                            }
                        }
                    }
                }) {
                    Label("Schreibvorgang starten", systemImage: "sensor.tag.radiowaves.forward.fill")
                }
                .modifier(interactiveGlass())
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
            }
        }
        .navigationTitle("NFC Writer")
        .alert("Fehler", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

#if DEBUG
struct NFCWriterView_Previews: PreviewProvider {
    static var previews: some View {
        NFCWriterView(dataToWrite: "preview-dummy-data")
    }
}
#endif
