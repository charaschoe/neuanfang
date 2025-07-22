
import SwiftUI

struct PhotoCaptureView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraService = CameraService()

    var body: some View {
        CameraView(cameraService: cameraService) { result in
            switch result {
            case .success(let capturedImage):
                image = capturedImage
            case .failure(let error):
                print("Camera error: \(error.localizedDescription)")
            }
            dismiss()
        }
        .onAppear {
            Task {
                _ = await cameraService.requestCameraPermission()
            }
        }
    }
}
