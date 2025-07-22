//
//  OnboardingView.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var userProfile = UserProfile(name: "", email: "")
    
    private let pages = OnboardingPage.allCases
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background
                AnimatedBackgroundView()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    HStack {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentPage ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Content
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingPageView(
                                page: pages[index],
                                userProfile: $userProfile,
                                geometry: geometry
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.5), value: currentPage)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Zurück") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        } else {
                            Spacer()
                        }
                        
                        Spacer()
                        
                        Button(currentPage == pages.count - 1 ? "Los geht's!" : "Weiter") {
                            if currentPage == pages.count - 1 {
                                completeOnboarding()
                            } else {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(currentPage == pages.count - 1 && !isProfileComplete)
                    }
                    .padding()
                    .liquidGlass(.floating)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var isProfileComplete: Bool {
        !userProfile.name.isEmpty && !userProfile.email.isEmpty
    }
    
    private func completeOnboarding() {
        appState.currentUser = userProfile
        appState.completeOnboarding()
    }
}

enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case features = 1
    case profile = 2
    case permissions = 3
    
    var title: String {
        switch self {
        case .welcome: return "Willkommen bei neuanfang"
        case .features: return "Ihre Umzugshilfe"
        case .profile: return "Ihr Profil"
        case .permissions: return "Berechtigungen"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome: return "Der intelligente Umzugshelfer für stressfreie Umzüge"
        case .features: return "Organisieren, verfolgen und koordinieren Sie Ihren Umzug"
        case .profile: return "Erstellen Sie Ihr persönliches Umzugsprofil"
        case .permissions: return "Für die beste Erfahrung benötigen wir einige Berechtigungen"
        }
    }
    
    var icon: String {
        switch self {
        case .welcome: return "house.and.flag.fill"
        case .features: return "checklist"
        case .profile: return "person.crop.circle.fill"
        case .permissions: return "lock.shield.fill"
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var userProfile: UserProfile
    let geometry: GeometryProxy
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 50)
                
                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.bounce, options: .repeat(false))
                
                // Title and subtitle
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(page.subtitle)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Page-specific content
                Group {
                    switch page {
                    case .welcome:
                        WelcomeContentView()
                    case .features:
                        FeaturesContentView()
                    case .profile:
                        ProfileContentView(userProfile: $userProfile)
                    case .permissions:
                        PermissionsContentView()
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
        }
    }
}

struct WelcomeContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🏠 ➜ 🏡")
                .font(.system(size: 60))
            
            Text("Machen Sie Ihren Umzug zu einem stressfreien Erlebnis mit intelligenter Organisation und modernen Technologien.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .liquidGlass(.floating)
        .padding()
    }
}

struct FeaturesContentView: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            FeatureCard(icon: "house.fill", title: "Räume", description: "Organisieren Sie nach Zimmern")
            FeatureCard(icon: "shippingbox.fill", title: "Kisten", description: "QR-Codes & NFC-Tags")
            FeatureCard(icon: "calendar", title: "Timeline", description: "Schritt-für-Schritt Plan")
            FeatureCard(icon: "person.2.fill", title: "Teilen", description: "Mit Familie koordinieren")
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(height: 120)
        .liquidGlass(.floating)
    }
}

struct ProfileContentView: View {
    @Binding var userProfile: UserProfile
    @State private var movingDate = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                TextField("Name", text: $userProfile.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("E-Mail", text: $userProfile.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                DatePicker("Umzugsdatum (optional)", selection: $movingDate, displayedComponents: .date)
                    .onChange(of: movingDate) { _, newValue in
                        userProfile.movingDate = newValue
                    }
            }
            .padding()
            .liquidGlass(.floating)
        }
    }
}

struct PermissionsContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            PermissionRow(
                icon: "camera.fill",
                title: "Kamera",
                description: "Für Fotos von Gegenständen",
                isRequired: true
            )
            
            PermissionRow(
                icon: "antenna.radiowaves.left.and.right",
                title: "NFC",
                description: "Zum Lesen und Schreiben von Tags",
                isRequired: false
            )
            
            PermissionRow(
                icon: "icloud.fill",
                title: "iCloud",
                description: "Für Synchronisation zwischen Geräten",
                isRequired: false
            )
        }
        .padding()
        .liquidGlass(.floating)
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isRequired: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    if isRequired {
                        Text("Erforderlich")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.2))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(.blue.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct AnimatedBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated circles
            ForEach(0..<5) { i in
                Circle()
                    .fill(.blue.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .offset(
                        x: animate ? .random(in: -100...100) : .random(in: -50...50),
                        y: animate ? .random(in: -100...100) : .random(in: -50...50)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.5),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState.shared)
}