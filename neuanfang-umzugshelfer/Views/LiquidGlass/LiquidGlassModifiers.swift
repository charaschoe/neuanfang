//
//  LiquidGlassModifiers.swift
//  neuanfang: Umzugshelfer
//
//  Created by neuanfang Team
//  Copyright © 2024 neuanfang. All rights reserved.
//

import SwiftUI

// MARK: - Main Liquid Glass Modifier

extension View {
    /// Applies the Liquid Glass effect with specified style
    func liquidGlass(_ style: LiquidGlassStyle = .dynamic) -> some View {
        self.modifier(LiquidGlassModifier(style: style))
    }
    
    /// Adds depth-based glass layering
    func glassDepth(_ depth: GlassDepth) -> some View {
        self.modifier(GlassDepthModifier(depth: depth))
    }
    
    /// Enables adaptive glass behavior based on context
    func adaptiveGlass(_ adaptive: Bool = true) -> some View {
        self.modifier(AdaptiveGlassModifier(isAdaptive: adaptive))
    }
    
    /// Adds animated glass shimmer effect
    func glassShimmer(_ isAnimating: Bool = true) -> some View {
        self.modifier(GlassShimmerModifier(isAnimating: isAnimating))
    }
    
    /// Adds interactive glass feedback
    func interactiveGlass() -> some View {
        self.modifier(InteractiveGlassModifier())
    }
}

// MARK: - Liquid Glass Styles

enum LiquidGlassStyle {
    case dynamic    // Adapts to content and context
    case toolbar    // Optimized for navigation and tabs
    case floating   // For cards and floating elements
    case overlay    // For modals and overlays
    case subtle     // Minimal glass effect
    case prominent  // Strong glass effect
    
    var cornerRadius: CGFloat {
        switch self {
        case .dynamic: return 12
        case .toolbar: return 8
        case .floating: return 16
        case .overlay: return 20
        case .subtle: return 8
        case .prominent: return 14
        }
    }
    
    var backgroundOpacity: Double {
        switch self {
        case .dynamic: return 0.85
        case .toolbar: return 0.9
        case .floating: return 0.8
        case .overlay: return 0.95
        case .subtle: return 0.7
        case .prominent: return 0.9
        }
    }
    
    var borderOpacity: Double {
        switch self {
        case .dynamic: return 0.3
        case .toolbar: return 0.2
        case .floating: return 0.4
        case .overlay: return 0.5
        case .subtle: return 0.1
        case .prominent: return 0.4
        }
    }
}

// MARK: - Glass Depth Levels

enum GlassDepth {
    case surface    // Flush with background
    case elevated   // Slightly raised
    case floating   // Clearly above surface
    case modal      // Highest level
    
    var shadowRadius: CGFloat {
        switch self {
        case .surface: return 0
        case .elevated: return 4
        case .floating: return 12
        case .modal: return 24
        }
    }
    
    var shadowOpacity: Double {
        switch self {
        case .surface: return 0
        case .elevated: return 0.1
        case .floating: return 0.2
        case .modal: return 0.3
        }
    }
    
    var yOffset: CGFloat {
        switch self {
        case .surface: return 0
        case .elevated: return 1
        case .floating: return 3
        case .modal: return 6
        }
    }
}

// MARK: - Liquid Glass Modifier Implementation

struct LiquidGlassModifier: ViewModifier {
    let style: LiquidGlassStyle
    @Environment(\.colorScheme) var colorScheme
    @State private var animationPhase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .overlay(glassOverlay)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animationPhase = 1
                }
            }
    }
    
    private var glassBackground: some View {
        ZStack {
            // Base material
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(backgroundOpacity)
            
            // Specular highlight
            specularHighlight
            
            // Animated flow
            animatedFlow
        }
    }
    
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius)
            .stroke(borderGradient, lineWidth: strokeWidth)
    }
    
    private var specularHighlight: some View {
        LinearGradient(
            colors: [
                .white.opacity(highlightOpacity),
                .clear,
                .white.opacity(highlightOpacity * 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var animatedFlow: some View {
        LinearGradient(
            colors: [
                .clear,
                .white.opacity(0.05),
                .clear
            ],
            startPoint: UnitPoint(
                x: -0.5 + animationPhase * 1.5,
                y: -0.5 + animationPhase * 1.5
            ),
            endPoint: UnitPoint(
                x: 0.5 + animationPhase * 1.5,
                y: 0.5 + animationPhase * 1.5
            )
        )
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(style.borderOpacity),
                .white.opacity(style.borderOpacity * 0.5),
                .clear,
                .white.opacity(style.borderOpacity * 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var backgroundOpacity: Double {
        colorScheme == .dark ? style.backgroundOpacity * 0.9 : style.backgroundOpacity
    }
    
    private var highlightOpacity: Double {
        colorScheme == .dark ? 0.3 : 0.4
    }
    
    private var strokeWidth: CGFloat {
        colorScheme == .dark ? 0.5 : 0.75
    }
}

// MARK: - Glass Depth Modifier

struct GlassDepthModifier: ViewModifier {
    let depth: GlassDepth
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: shadowColor,
                radius: depth.shadowRadius,
                x: 0,
                y: depth.yOffset
            )
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? 
            .black.opacity(depth.shadowOpacity) : 
            .black.opacity(depth.shadowOpacity * 0.7)
    }
}

// MARK: - Adaptive Glass Modifier

struct AdaptiveGlassModifier: ViewModifier {
    let isAdaptive: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    func body(content: Content) -> some View {
        if isAdaptive && reduceTransparency {
            // Fallback for accessibility
            content
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            content
        }
    }
}

// MARK: - Glass Shimmer Modifier

struct GlassShimmerModifier: ViewModifier {
    let isAnimating: Bool
    @State private var shimmerPhase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(shimmerOverlay)
            .onAppear {
                if isAnimating {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        shimmerPhase = 1
                    }
                }
            }
    }
    
    private var shimmerOverlay: some View {
        LinearGradient(
            colors: [
                .clear,
                .white.opacity(0.1),
                .white.opacity(0.2),
                .white.opacity(0.1),
                .clear
            ],
            startPoint: UnitPoint(x: -1 + shimmerPhase * 2, y: 0),
            endPoint: UnitPoint(x: 0 + shimmerPhase * 2, y: 0)
        )
        .opacity(isAnimating ? 1 : 0)
    }
}

// MARK: - Interactive Glass Modifier

struct InteractiveGlassModifier: ViewModifier {
    @State private var isPressed = false
    @State private var hoverLocation: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .brightness(isPressed ? 0.05 : 0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
                isPressed = pressing
            } perform: {}
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hoverLocation = value.location
                    }
            )
    }
}

// MARK: - Pre-built Glass Components

struct GlassCard<Content: View>: View {
    let content: Content
    let style: LiquidGlassStyle
    let depth: GlassDepth
    
    init(
        style: LiquidGlassStyle = .floating,
        depth: GlassDepth = .elevated,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.depth = depth
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .liquidGlass(style)
            .glassDepth(depth)
            .interactiveGlass()
    }
}

struct GlassButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(GlassButtonStyle())
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .liquidGlass(.dynamic)
            .glassDepth(.elevated)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? 0.1 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Glass Navigation Bar

struct GlassNavigationBar<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .liquidGlass(.toolbar)
            .glassDepth(.surface)
    }
}

// MARK: - Glass Modal

struct GlassModal<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .liquidGlass(.overlay)
            .glassDepth(.modal)
            .adaptiveGlass()
    }
}

#Preview("Liquid Glass Showcase") {
    ScrollView {
        VStack(spacing: 20) {
            GlassCard(style: .floating, depth: .elevated) {
                VStack {
                    Text("Floating Card")
                        .font(.headline)
                    Text("This is a glass card with floating style")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            GlassButton(action: {}) {
                Text("Glass Button")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 16) {
                ForEach(LiquidGlassStyle.allCases, id: \.self) { style in
                    Text(String(describing: style))
                        .font(.caption)
                        .padding(8)
                        .liquidGlass(style)
                }
            }
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

// MARK: - Style Cases Extension

extension LiquidGlassStyle: CaseIterable {
    static var allCases: [LiquidGlassStyle] {
        [.dynamic, .toolbar, .floating, .overlay, .subtle, .prominent]
    }
}