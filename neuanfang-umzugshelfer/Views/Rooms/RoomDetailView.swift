
import SwiftUI

struct RoomDetailView: View {
    @ObservedObject var room: Room

    var body: some View {
        BoxListView(room: room)
    }
}
