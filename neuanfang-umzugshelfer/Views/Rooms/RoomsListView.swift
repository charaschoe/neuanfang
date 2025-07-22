//
//  RoomsListView.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import SwiftUI
import CoreData

struct RoomsListView: View {
    @StateObject private var viewModel = RoomListViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var cloudKitService: CloudKitService
    
    @State private var showingAddRoom = false
    @State private var showingFilterSheet = false
    @State private var showingStatsSheet = false
    
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Statistics Overview
                        if !viewModel.rooms.isEmpty {
                            StatisticsOverviewCard(
                                statistics: viewModel.getStatistics(),
                                onStatsPressed: { showingStatsSheet = true }
                            )
                        }
                        
                        // Search and Filter Section
                        SearchAndFilterSection(viewModel: viewModel) {
                            showingFilterSheet = true
                        }
                        
                        // Rooms Grid
                        RoomsGridSection(
                            rooms: viewModel.filteredRooms,
                            onRoomToggled: { room in
                                viewModel.toggleRoomCompletion(room)
                            }
                        )
                        
                        // Empty State
                        if viewModel.filteredRooms.isEmpty {
                            EmptyRoomsView {
                                showingAddRoom = true
                            }
                        }
                        
                        // Add Room Button (Always visible)
                        AddRoomButton {
                            showingAddRoom = true
                        }
                        .padding(.bottom, 100) // Extra padding for tab bar
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .navigationTitle("Räume")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { showingAddRoom = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddRoom) {
                AddRoomSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterAndSortSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingStatsSheet) {
                StatisticsDetailSheet(statistics: viewModel.getStatistics())
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

// MARK: - Statistics Overview Card

struct StatisticsOverviewCard: View {
    let statistics: RoomStatistics
    let onStatsPressed: () -> Void
    
    var body: some View {
        Button(action: onStatsPressed) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gesamtfortschritt")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(statistics.completedRooms) von \(statistics.totalRooms) Räumen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(
                        progress: Double(statistics.overallProgress),
                        lineWidth: 8
                    )
                    .frame(width: 60, height: 60)
                }
                
                HStack {
                    StatisticItem(
                        title: "Kisten",
                        value: "\(statistics.packedBoxes)/\(statistics.totalBoxes)",
                        icon: "shippingbox.fill",
                        color: .orange
                    )
                    
                    Divider()
                        .frame(height: 30)
                    
                    StatisticItem(
                        title: "Gegenstände",
                        value: "\(statistics.totalItems)",
                        icon: "cube.fill",
                        color: .green
                    )
                    
                    Divider()
                        .frame(height: 30)
                    
                    StatisticItem(
                        title: "Fortschritt",
                        value: "\(statistics.completionPercentage)%",
                        icon: "chart.pie.fill",
                        color: .blue
                    )
                }
            }
            .padding()
        }
        .liquidGlass(.floating)
        .glassDepth(.elevated)
        .interactiveGlass()
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Search and Filter Section

struct SearchAndFilterSection: View {
    @ObservedObject var viewModel: RoomListViewModel
    let onFilterPressed: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Räume durchsuchen...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: viewModel.clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .liquidGlass(.subtle)
            
            // Filter Button
            Button(action: onFilterPressed) {
                Image(systemName: viewModel.filterCriteria == .all ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                    .font(.title3)
                    .foregroundColor(viewModel.filterCriteria == .all ? .primary : .accentColor)
            }
            .padding(12)
            .liquidGlass(.subtle)
        }
    }
}

// MARK: - Rooms Grid Section


struct RoomsGridSection: View {
    let rooms: [Room]
    let onRoomToggled: (Room) -> Void
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(rooms, id: \.objectID) { room in
                NavigationLink(destination: RoomDetailView(room: room)) {
                    RoomCardView(
                        room: room,
                        onToggleCompletion: { onRoomToggled(room) }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Room Card View

struct RoomCardView: View {
    let room: Room
    let onToggleCompletion: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                // Header with icon and status
                HStack {
                    Image(systemName: room.iconName)
                        .font(.title2)
                        .foregroundColor(room.color)
                        .frame(width: 30, height: 30)
                    
                    Spacer()
                    
                    Button(action: onToggleCompletion) {
                        Image(systemName: room.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(room.isCompleted ? .green : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Room name
                Text(room.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Statistics
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(room.totalBoxes) Kisten")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(room.completionStatus.description)
                            .font(.caption)
                            .foregroundColor(room.completionStatus.color)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(room.color)
                                .frame(width: geometry.size.width * CGFloat(room.progressPercentage), height: 4)
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 4)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 140)
            .liquidGlass(.floating)
            .glassDepth(.elevated)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
                isPressed = pressing
            } perform: {}
    }
}

// MARK: - Empty State

struct EmptyRoomsView: View {
    let onAddRoom: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "house.circle")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
                .symbolEffect(.bounce, options: .repeat(false))
            
            VStack(spacing: 8) {
                Text("Noch keine Räume")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Fügen Sie Ihren ersten Raum hinzu, um mit der Umzugsplanung zu beginnen")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: onAddRoom) {
                Label("Ersten Raum hinzufügen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(.blue.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.vertical, 40)
        .liquidGlass(.floating)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Room Button

struct AddRoomButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Neuen Raum hinzufügen", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.accentColor)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .liquidGlass(.floating)
        .glassDepth(.elevated)
        .interactiveGlass()
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        RoomsListView()
            .environmentObject(CloudKitService.shared)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}