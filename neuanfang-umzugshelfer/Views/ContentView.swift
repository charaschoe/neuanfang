//
//  ContentView.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cloudKitService: CloudKitService
    
    var body: some View {
        Group {
            if appState.isFirstLaunch || !appState.hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            Task {
                await cloudKitService.initializeCloudKit()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            RoomsListView()
                .tabItem {
                    Label(AppState.Tab.rooms.title, 
                          systemImage: AppState.Tab.rooms.icon)
                }
                .tag(AppState.Tab.rooms)
            
            TimelineView()
                .tabItem {
                    Label(AppState.Tab.timeline.title, 
                          systemImage: AppState.Tab.timeline.icon)
                }
                .tag(AppState.Tab.timeline)
            
            SearchView()
                .tabItem {
                    Label(AppState.Tab.search.title, 
                          systemImage: AppState.Tab.search.icon)
                }
                .tag(AppState.Tab.search)
            
            SettingsView()
                .tabItem {
                    Label(AppState.Tab.settings.title, 
                          systemImage: AppState.Tab.settings.icon)
                }
                .tag(AppState.Tab.settings)
        }
        .liquidGlass(.toolbar)
        .tint(.blue)
    }
}

// Placeholder views that will be implemented later
struct RoomsListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Räume werden geladen...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Räume")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TimelineView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Timeline wird geladen...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Suchfunktion wird geladen...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Suchen")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Einstellungen werden geladen...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(CloudKitService.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}