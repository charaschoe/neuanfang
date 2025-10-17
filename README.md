# 📦 neuanfang: Umzugshelfer - Dein smarter Umzugsbegleiter

"neuanfang: Umzugshelfer" ist eine intelligente iOS-Anwendung der nächsten Generation, die entwickelt wurde, um den Umzugsprozess zu revolutionieren und zu organisieren. Von der KI-gestützten Verwaltung einzelner Gegenstände in Kisten bis zur automatisierten Planung des gesamten Umzugs bietet diese App eine umfassende Lösung für einen völlig stressfreien Neuanfang.

## ✨ Features

### 🏠 Kernfunktionen
*   **Raumverwaltung:** Organisiere deine Umzugsgüter raumbasiert mit intelligenter Kategorisierung.
*   **Kistenverwaltung mit QR/NFC:** Erfasse Kisten, weise sie Räumen zu und identifiziere sie schnell per QR-Code oder NFC-Tag.
*   **Gegenstandsverwaltung mit KI-Integration:** Füge Gegenstände zu Kisten hinzu, mache Fotos mit fortschrittlicher KI-Objekterkennung und erhalte intelligente Vorschläge für Kategorisierung und Zerbrechlichkeit.
*   **Umzugs-Timeline:** Behalte den Überblick über wichtige Termine und Phasen deines Umzugs mit KI-gestützter Zeitplanung.
*   **Datenexport:** Exportiere deine Umzugsdaten als CSV oder PDF für eine einfache Dokumentation.
*   **Kollaborationsfunktionen:** Teile deinen Umzug mit Familie und Freunden und arbeite gemeinsam an der Organisation.
*   **Liquid Glass Design System:** Eine einzigartige, visuell ansprechende Benutzeroberfläche, die ein immersives Erlebnis bietet.
*   **Core Data & CloudKit Integration:** Sichere und synchronisiere deine Daten nahtlos über iCloud mit End-to-End-Verschlüsselung.

## 🚀 WWDC 2025 Features

### 🧠 Foundation Models Framework Integration

#### Smart Content Generation
*   **Automated Packing Suggestions:** KI-gestützte Vorschläge für optimale Verpackungsstrategien basierend auf Gegenstandstyp und Zielraum
*   **Moving Timeline Generator:** Automatische Erstellung personalisierter Umzugszeitpläne mit Machine Learning
*   **Box Labeling AI:** Intelligente Beschriftungsvorschläge für Kisten basierend auf Inhalten

#### Natural Language Processing Features
*   **Voice-to-Inventory:** Spreche Gegenstände ein und lass sie automatisch kategorisieren und hinzufügen
*   **Smart Search:** Natürlichsprachige Suche durch dein gesamtes Umzugsinventar
*   **Moving Notes Assistant:** KI-Assistent für Umzugsnotizen und Erinnerungen

```swift
// Foundation Models Integration Beispiel
import FoundationModels

class MovingAssistant {
    private let contentGenerator = FMContentGenerator()
    
    func generatePackingPlan(for items: [Item]) async -> PackingPlan {
        let prompt = "Erstelle einen optimalen Packplan für diese Gegenstände: \(items.map(\.name).joined(separator: ", "))"
        return await contentGenerator.generate(prompt: prompt, type: .packingStrategy)
    }
    
    func processVoiceInput(_ audio: AudioData) async -> [Item] {
        let nlpProcessor = FMNaturalLanguageProcessor()
        let transcription = await nlpProcessor.transcribe(audio)
        return await nlpProcessor.extractItems(from: transcription)
    }
}
```

### 🌊 Liquid Glass Design System 2.0

#### UI Component Redesign
*   **Floating Action Buttons:** Schwebende, glasartige Action-Buttons mit dynamischen Animationen
*   **Interactive Box Cards:** Interaktive Kistenkarten mit Liquid Glass-Effekten und Parallax-Scrolling
*   **Morphing Sheets:** Flüssige Übergänge zwischen verschiedenen View-States

#### Adaptive Navigation
*   **Context-Aware Glass Navigation:** Navigation passt sich automatisch an Inhalte und Benutzerkontext an
*   **Custom Glass Components:** Erweiterte Glaseffekte für verschiedene UI-Elemente

```swift
// Liquid Glass 2.0 Beispiel
struct MovingCardView: View {
    var body: some View {
        VStack {
            // Content
        }
        .liquidGlass(.adaptive)
        .glassDepth(.floating)
        .morphingTransition()
        .contextualGlow()
    }
}
```

### 👁️ Visual Intelligence API Integration

#### Advanced Item Recognition
*   **Multi-Object Detection:** Erkennung mehrerer Objekte in einem einzigen Foto
*   **Smart Categorization:** Automatische Kategorisierung basierend auf visueller Analyse
*   **Damage Documentation:** KI-gestützte Schadenserkennung für Versicherungszwecke

#### QR Code Enhancement
*   **Visual Intelligence QR Enhancement:** Verbesserte QR-Code-Erkennung auch bei schlechten Lichtverhältnissen
*   **Context-Aware Scanning:** QR-Codes werden basierend auf Umgebungskontext interpretiert

```swift
// Visual Intelligence Integration
import VisualIntelligence

class SmartItemRecognizer {
    private let visualIntelligence = VIImageAnalyzer()
    
    func analyzeImage(_ image: UIImage) async -> ItemAnalysis {
        let analysis = await visualIntelligence.analyze(image)
        
        return ItemAnalysis(
            objects: analysis.detectedObjects,
            categories: analysis.suggestedCategories,
            fragility: analysis.fragilityAssessment,
            packingTips: analysis.packingRecommendations
        )
    }
}
```

### 🎙️ App Intents Framework Updates

#### Siri Integration
*   **Voice Commands:** "Hey Siri, füge Küchentisch zu Kiste 5 hinzu"
*   **Status Updates:** "Hey Siri, wie ist der Status meines Umzugs?"
*   **Timeline Management:** Sprachgesteuerte Timeline-Anpassungen

#### Shortcuts and Automation
*   **Moving Day Shortcuts:** Vorgefertigte Shortcuts für Umzugstag-Aktivitäten
*   **Location-Based Triggers:** Automatische Aktionen basierend auf GPS-Position

### 📸 Enhanced Camera und Core ML Features

#### AI-Powered Photography
*   **Automatic Item Recognition:** Sofortige Objekterkennung beim Fotografieren
*   **Smart Tagging:** Automatisches Hinzufügen relevanter Tags
*   **Fragility Assessment:** KI-Bewertung der Zerbrechlichkeit von Gegenständen

### 🎮 Metal 4 Graphics API Integration

#### 3D Visualization
*   **Room Layout Planning:** 3D-Visualisierung von Raumlayouts mit realistischen Schatten
*   **Box Stacking Simulator:** Physik-basierte Simulation für optimale Kistenstapelung
*   **AR Furniture Placement:** Augmented Reality für Möbelplatzierung im neuen Zuhause

## 🚀 Technologien

### Core Frameworks
*   **SwiftUI:** Modernes UI-Framework für iOS-Anwendungen
*   **Core Data:** Persistenz-Framework für die lokale Datenspeicherung mit Verschlüsselung
*   **CloudKit:** Apples Framework für die Synchronisierung von Daten über iCloud
*   **AVFoundation:** Für die Kamera-Integration und Fotoaufnahme

### WWDC 2025 Frameworks
*   **Foundation Models Framework:** KI-gestützte Content-Generierung und Natural Language Processing
*   **Visual Intelligence API:** Fortschrittliche Bilderkennung und -analyse
*   **App Intents Framework 2.0:** Erweiterte Siri-Integration und Shortcuts
*   **Metal 4:** Hochleistungsgrafiken und 3D-Visualisierung
*   **Core ML 6:** Verbesserte On-Device Machine Learning Capabilities

### Zusätzliche Technologien
*   **Vision Framework:** Für die KI-Objekterkennung in Bildern
*   **Core NFC:** Für das Lesen und Schreiben von NFC-Tags
*   **Core Image:** Für die Bildverarbeitung und -verbesserung
*   **XCTest:** Für Unit- und Integrationstests

## 🎨 Liquid Glass Design System 2.0

Das Projekt verwendet das fortschrittliche "Liquid Glass Design System 2.0" für eine revolutionäre Benutzererfahrung. Es ist wichtig, die bereitgestellten Modifier zu verwenden, um die Konsistenz des Designs zu gewährleisten:

```swift
// Basis-Stile
.liquidGlass(.floating)    // Für Cards und Panels
.liquidGlass(.toolbar)     // Für Navigation
.liquidGlass(.overlay)     // Für Modals
.liquidGlass(.adaptive)    // Adaptiv an Kontext
.liquidGlass(.dynamic)     // Dynamische Anpassungen

// Tiefe hinzufügen
.glassDepth(.elevated)     // Leicht erhöht
.glassDepth(.floating)     // Schwebend
.glassDepth(.modal)        // Höchste Ebene

// Interaktivität
.interactiveGlass()        // Für tappbare Elemente
.morphingTransition()      // Flüssige Übergänge
.contextualGlow()          // Kontextuelle Leuchteffekte
.paralaxGlass()            // Parallax-Effekte
```

## 📋 Implementation Roadmap

### Phase 1: Foundation (Q1 2025)
- [x] Foundation Models Framework Integration
- [x] Basic Visual Intelligence API Implementation  
- [x] Core App Intents Setup
- [ ] Enhanced Liquid Glass Components

### Phase 2: Intelligence (Q2 2025)
- [ ] Advanced Multi-Object Detection
- [ ] Complete Natural Language Processing
- [ ] Full Siri Integration
- [ ] Location-Based Automation

### Phase 3: Advanced Features (Q3 2025)
- [ ] Metal 4 3D Visualization
- [ ] AR Furniture Placement
- [ ] Advanced Physics Simulation
- [ ] Complete Voice Control Interface

## 📁 Projektstruktur

```
neuanfang-umzugshelfer/
├── App/                          # App Lifecycle
├── Models/
│   ├── CoreData/                 # Entities + PersistenceController
│   ├── ViewModels/               # Observable ViewModels
│   └── AI/                       # Foundation Models Integration
├── Views/
│   ├── LiquidGlass/              # Design System 2.0 (NICHT ÄNDERN)
│   ├── Rooms/                    # Raum-Views
│   ├── Boxes/                    # Kisten-Views
│   ├── Items/                    # Gegenstände-Views
│   ├── Timeline/                 # Timeline-Views
│   ├── Settings/                 # Einstellungen
│   ├── AR/                       # Augmented Reality Views
│   └── Shared/                   # Wiederverwendbare Components
├── Services/
│   ├── AI/                       # Foundation Models Services
│   ├── Vision/                   # Visual Intelligence Services
│   ├── Voice/                    # App Intents & Siri
│   └── Core/                     # Basis Services
├── Metal/                        # Metal 4 Rendering
└── Resources/                    # Assets & Configs
```

## 🛠️ Setup und Installation

### Voraussetzungen
1.  **Xcode 16.0+:** Stelle sicher, dass du Xcode 16.0 oder neuer installiert hast (für WWDC 2025 Features).
2.  **iOS 18.0+:** Die App benötigt iOS 18.0 oder neuer.
3.  **Apple Developer Account:** Für CloudKit und erweiterte KI-Features erforderlich.

### Installation
1.  **Klonen des Repositories:**
    ```bash
    git clone <repository-url>
    cd neuanfang-umzugshelfer
    ```

2.  **Abhängigkeiten:** Das Projekt verwendet keine externen Abhängigkeiten, die über Swift Package Manager oder CocoaPods verwaltet werden müssen. Alle notwendigen Frameworks sind Teil des iOS 18 SDK.

3.  **Xcode-Projekt öffnen:**
    Öffne die Datei `neuanfang-umzugshelfer.xcodeproj` in Xcode.

4.  **Team und Bundle Identifier:**
    *   Wähle im Xcode-Projektnavigator das Projekt `neuanfang-umzugshelfer` aus.
    *   Gehe zum Tab "Signing & Capabilities".
    *   Wähle dein Entwicklungsteam aus.
    *   Stelle sicher, dass der Bundle Identifier eindeutig ist (z.B. `com.deinname.neuanfang-umzugshelfer`).

5.  **CloudKit-Container:**
    *   Im Tab "Signing & Capabilities" unter "iCloud" muss "CloudKit" aktiviert sein.
    *   Stelle sicher, dass ein CloudKit-Container für deine App ausgewählt oder erstellt wurde.

6.  **WWDC 2025 Framework Berechtigungen:**
    *   Aktiviere "Foundation Models" für KI-Features
    *   Aktiviere "Visual Intelligence" für erweiterte Bilderkennung
    *   Aktiviere "App Intents" für Siri-Integration
    *   Konfiguriere "Metal Performance Shaders" für 3D-Features

7.  **Erweiterte Berechtigungen:**
    *   Überprüfe unter "Signing & Capabilities" die Berechtigungen für:
        - "NFC Tag Reading"
        - "Camera Usage" 
        - "Microphone Usage" (für Voice Commands)
        - "Location Services" (für Location-Based Features)

## 🏃 App starten

1.  **Simulator:** Wähle iPhone 15 Pro oder neuer für optimale Performance der WWDC 2025 Features.
2.  **Physisches Gerät:** iPhone 15 Pro oder neuer empfohlen für Metal 4 und Visual Intelligence Features.
3.  Klicke auf den "Run"-Button (▶️) in Xcode oder drücke `Cmd + R`.

## 🧪 Testing

Das Projekt umfasst umfassende Tests für alle Features:

```bash
# Unit Tests ausführen
xcodebuild test -scheme neuanfang-umzugshelfer -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UI Tests ausführen  
xcodebuild test -scheme neuanfang-umzugshelfer-UITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 🔒 Security & Code Analysis

Das Projekt implementiert moderne Sicherheitsstandards und kontinuierliche Code-Analyse:

### CodeQL Advanced Security Scanning
- **Automatisierte Sicherheitsanalyse:** Tägliche CodeQL-Scans identifizieren potenzielle Sicherheitslücken
- **Swift-optimierte Konfiguration:** Speziell für iOS/Swift-Projekte konfiguriert
- **Pull Request Checks:** Automatische Sicherheitsprüfungen bei Code-Änderungen
- **Konflikt-freie Konfiguration:** Vermeidet Konflikte mit GitHub's Standard-CodeQL-Setup

### Sicherheitsfeatures
- **End-to-End-Verschlüsselung:** Alle CloudKit-Daten sind verschlüsselt
- **Lokale Datenverschlüsselung:** Core Data mit File Protection Level "complete"
- **Sichere KI-Integration:** On-Device Processing mit Foundation Models Framework
- **Privacy by Design:** Minimale Datensammlung und lokale Verarbeitung

Detaillierte Informationen zur Sicherheitskonfiguration finden Sie in [CODEQL_SECURITY_SETUP.md](./CODEQL_SECURITY_SETUP.md).

## 🤝 Beitragen

Wir freuen uns über Beiträge! Bitte beachte:
- Verwende das Liquid Glass Design System 2.0 für UI-Komponenten
- Befolge die Swift Coding Guidelines
- Teste neue Features sowohl im Simulator als auch auf physischen Geräten
- Dokumentiere WWDC 2025 Feature-Implementierungen ausführlich

## 📚 Dokumentation

### Benutzer-Dokumentation
- [`PrivacyPolicy.md`](neuanfang-umzugshelfer/Resources/PrivacyPolicy.md) - Datenschutzrichtlinie
- [`TermsOfService.md`](neuanfang-umzugshelfer/Resources/TermsOfService.md) - Nutzungsbedingungen
- [`CHANGELOG.md`](CHANGELOG.md) - Versionshistorie

### Entwickler-Dokumentation
- [`docs/APP_STORE_CHECKLIST.md`](docs/APP_STORE_CHECKLIST.md) - App Store Release Checkliste
- [`docs/DEVELOPMENT_NOTES.md`](docs/DEVELOPMENT_NOTES.md) - Entwicklungsnotizen und Best Practices
- [`docs/GITHUB_WORKFLOWS.md`](docs/GITHUB_WORKFLOWS.md) - GitHub Actions Workflows
- [`neuanfang-umzugshelfer/CoreDataEncryptionValidation.md`](neuanfang-umzugshelfer/CoreDataEncryptionValidation.md) - Core Data Verschlüsselung
- [`neuanfang-umzugshelfer/INPUT_VALIDATION_DOCUMENTATION.md`](neuanfang-umzugshelfer/INPUT_VALIDATION_DOCUMENTATION.md) - Input Validation

## 📝 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe die [`LICENSE`](LICENSE)-Datei für weitere Details.

---

**Hinweis:** Diese App nutzt die neuesten WWDC 2025 Technologien und benötigt iOS 18.0+ sowie Xcode 16.0+ für die vollständige Funktionalität.