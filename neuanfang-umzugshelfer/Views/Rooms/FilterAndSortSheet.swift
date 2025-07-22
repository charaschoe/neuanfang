
import SwiftUI

struct FilterAndSortSheet: View {
    @ObservedObject var viewModel: RoomListViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sortieren nach")) {
                    Picker("Sortierung", selection: $viewModel.sortOrder) {
                        ForEach(RoomListViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Filtern nach Status")) {
                    Picker("Filter", selection: $viewModel.filterCriteria) {
                        ForEach(RoomListViewModel.FilterCriteria.allCases, id: \.self) { criteria in
                            Text(criteria.displayName).tag(criteria)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Filter & Sortierung")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .modifier(liquidGlass(.overlay))
        }
    }
}
