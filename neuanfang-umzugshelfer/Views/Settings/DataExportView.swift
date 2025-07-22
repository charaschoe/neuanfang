import SwiftUI
import CoreData

struct DataExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showShareSheet = false
    @State private var csvExportData: String = ""
    @State private var pdfExportData: Data? = nil

    var body: some View {
        VStack(spacing: 20) {
            Button(action: { 
                csvExportData = generateCSV()
                showShareSheet = true
            }) {
                Label("Als CSV exportieren", systemImage: "doc.text")
            }
            .modifier(interactiveGlass())
            
            Button(action: { 
                pdfExportData = generatePDF()
                showShareSheet = true
            }) {
                Label("Als PDF exportieren", systemImage: "doc.richtext")
            }
            .modifier(interactiveGlass())
        }
        .navigationTitle("Datenexport")
        .modifier(liquidGlass(.floating))
        .sheet(isPresented: $showShareSheet) {
            if let pdfData = pdfExportData {
                ShareSheet(activityItems: [pdfData])
            } else {
                ShareSheet(activityItems: [csvExportData])
            }
        }
    }
    
    private func generatePDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "neuanfang: Umzugshelfer",
            kCGPDFContextAuthor: "\(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "")",
            kCGPDFContextTitle: "Umzugsdaten Export"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { (context) in
            context.beginPage()
            let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
            let text = "Umzugsdaten Export"
            text.draw(at: CGPoint(x: 20, y: 20), withAttributes: attributes)

            var yOffset: CGFloat = 100
            let fetchRequest: NSFetchRequest<Room> = Room.fetchRequest()
            do {
                let rooms = try viewContext.fetch(fetchRequest)
                for room in rooms {
                    let roomText = "Room: \(room.name ?? "")"
                    roomText.draw(at: CGPoint(x: 20, y: yOffset), withAttributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
                    yOffset += 20

                    if let boxes = room.boxes as? Set<Box> {
                        for box in boxes {
                            let boxText = "  Box: \(box.name ?? "")"
                            boxText.draw(at: CGPoint(x: 30, y: yOffset), withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)])
                            yOffset += 18

                            if let items = box.items as? Set<Item> {
                                for item in items {
                                    let itemText = "    Item: \(item.name ?? "") (Value: \(item.value), Fragile: \(item.isFragile ? "Yes" : "No"))"
                                    itemText.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)])
                                    yOffset += 16
                                }
                            }
                        }
                    }
                    yOffset += 20
                }
            } catch {
                print("Failed to fetch data for PDF export: \(error)")
            }
        }
        return data
    }
    
    private func generateCSV() -> String {
        var csvString = "Room,Box,Item Name,Value,Fragile\n"
        
        let fetchRequest: NSFetchRequest<Room> = Room.fetchRequest()
        do {
            let rooms = try viewContext.fetch(fetchRequest)
            for room in rooms {
                if let boxes = room.boxes as? Set<Box> {
                    for box in boxes {
                        if let items = box.items as? Set<Item> {
                            for item in items {
                                let roomName = room.name ?? ""
                                let boxName = box.name ?? ""
                                let itemName = item.name ?? ""
                                let itemValue = String(format: "%.2f", item.value)
                                let isFragile = item.isFragile ? "Yes" : "No"
                                csvString += "\"\(roomName)\",\"\(boxName)\",\"\(itemName)\",\(itemValue),\(isFragile)\n"
                            }
                        }
                    }
                }
            }
        } catch {
            print("Failed to fetch data for CSV export: \(error)")
        }
        return csvString
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#if DEBUG
struct DataExportView_Previews: PreviewProvider {
    static var previews: some View {
        DataExportView()
    }
}
#endif