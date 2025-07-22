# 📦 neuanfang: Umzugshelfer - Dein smarter Umzugsbegleiter

"neuanfang: Umzugshelfer" ist eine intelligente iOS-Anwendung, die entwickelt wurde, um den Umzugsprozess zu vereinfachen und zu organisieren. Von der Verwaltung einzelner Gegenstände in Kisten bis zur Planung des gesamten Umzugs bietet diese App eine umfassende Lösung für einen stressfreien Neuanfang.

## ✨ Features

*   **Raumverwaltung:** Organisiere deine Umzugsgüter raumbasiert.
*   **Kistenverwaltung mit QR/NFC:** Erfasse Kisten, weise sie Räumen zu und identifiziere sie schnell per QR-Code oder NFC-Tag.
*   **Gegenstandsverwaltung mit Kamera-Integration:** Füge Gegenstände zu Kisten hinzu, mache Fotos mit KI-Objekterkennung und erhalte Vorschläge für Kategorisierung und Zerbrechlichkeit.
*   **Umzugs-Timeline:** Behalte den Überblick über wichtige Termine und Phasen deines Umzugs.
*   **Datenexport:** Exportiere deine Umzugsdaten als CSV oder PDF für eine einfache Dokumentation.
*   **Kollaborationsfunktionen:** Teile deinen Umzug mit Familie und Freunden und arbeite gemeinsam an der Organisation.
*   **Liquid Glass Design System:** Eine einzigartige, visuell ansprechende Benutzeroberfläche, die ein immersives Erlebnis bietet.
*   **Core Data & CloudKit Integration:** Sichere und synchronisiere deine Daten nahtlos über iCloud.

## 🚀 Technologien

*   **SwiftUI:** Modernes UI-Framework für iOS-Anwendungen.
*   **Core Data:** Persistenz-Framework für die lokale Datenspeicherung.
*   **CloudKit:** Apples Framework für die Synchronisierung von Daten über iCloud.
*   **AVFoundation:** Für die Kamera-Integration und Fotoaufnahme.
*   **Vision Framework:** Für die KI-Objekterkennung in Bildern.
*   **Core NFC:** Für das Lesen und Schreiben von NFC-Tags.
*   **Core Image:** Für die Bildverarbeitung und -verbesserung.
*   **XCTest:** Für Unit- und Integrationstests.

## 🎨 Liquid Glass Design System

Das Projekt verwendet ein proprietäres "Liquid Glass Design System" für eine einzigartige Ästhetik. Es ist wichtig, die bereitgestellten Modifier zu verwenden, um die Konsistenz des Designs zu gewährleisten:

```swift
// Basis-Stile
.liquidGlass(.floating)    // Für Cards und Panels
.liquidGlass(.toolbar)     // Für Navigation
.liquidGlass(.overlay)     // Für Modals
.liquidGlass(.dynamic)     // Adaptiv

// Tiefe hinzufügen
.glassDepth(.elevated)     // Leicht erhöht
.glassDepth(.floating)     // Schwebend
.glassDepth(.modal)        // Höchste Ebene

// Interaktivität
.interactiveGlass()        // Für tappbare Elemente
```

## 📁 Projektstruktur

```
neuanfang-umzugshelfer/
├── App/                          # App Lifecycle
├── Models/
│   ├── CoreData/                 # Entities + PersistenceController
│   └── ViewModels/               # Observable ViewModels
├── Views/
│   ├── LiquidGlass/              # Design System (NICHT ÄNDERN)
│   ├── Rooms/                    # Raum-Views
│   ├── Boxes/                    # Kisten-Views
│   ├── Items/                    # Gegenstände-Views
│   ├── Timeline/                 # Timeline-Views
│   ├── Settings/                 # Einstellungen
│   └── Shared/                   # Wiederverwendbare Components
├── Services/                     # Business Logic
└── Resources/                    # Assets & Configs
```

## 🛠️ Setup und Installation

1.  **Xcode:** Stelle sicher, dass du Xcode 15.0 oder neuer installiert hast.
2.  **Klonen des Repositories:**
    ```bash
    git clone <repository-url>
    cd neuanfang-umzugshelfer
    ```
3.  **Abhängigkeiten:** Das Projekt verwendet keine externen Abhängigkeiten, die über Swift Package Manager oder CocoaPods verwaltet werden müssen. Alle notwendigen Frameworks sind Teil des iOS SDK.
4.  **Xcode-Projekt öffnen:**
    Öffne die Datei `neuanfang-umzugshelfer.xcodeproj` in Xcode.
5.  **Team und Bundle Identifier:**
    *   Wähle im Xcode-Projektnavigator das Projekt `neuanfang-umzugshelfer` aus.
    *   Gehe zum Tab "Signing & Capabilities".
    *   Wähle dein Entwicklungsteam aus.
    *   Stelle sicher, dass der Bundle Identifier eindeutig ist (z.B. `com.deinname.neuanfang-umzugshelfer`).
6.  **CloudKit-Container:**
    *   Im Tab "Signing & Capabilities" unter "iCloud" muss "CloudKit" aktiviert sein.
    *   Stelle sicher, dass ein CloudKit-Container für deine App ausgewählt oder erstellt wurde.
7.  **Berechtigungen:**
    *   Überprüfe unter "Signing & Capabilities", ob die Berechtigungen für "NFC Tag Reading" und "Camera Usage" korrekt konfiguriert sind, falls du diese Funktionen auf einem physischen Gerät testen möchtest.

## 🏃 App starten

1.  Wähle ein Simulator-Gerät oder ein angeschlossenes physisches Gerät in Xcode aus.
2.  Klicke auf den "Run"-Button (▶️) in Xcode oder drücke `Cmd + R`.

## 📝 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe die `LICENSE`-Datei für weitere Details.