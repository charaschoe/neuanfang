# 📱 neuanfang: Umzugshelfer - Fortsetzungsanweisungen für neuen Agent

## 🎯 **Projektkontext & aktueller Status**

Du übernimmst die Weiterentwicklung einer Swift iOS 18.0+ Umzugshelfer-App namens "neuanfang: Umzugshelfer". Das Projekt ist bereits **60% fertiggestellt** mit einer soliden Grundarchitektur.

### 📋 **Was bereits implementiert ist:**

#### ✅ **Vollständig abgeschlossen:**
1. **Projekt-Setup & Konfiguration** - Xcode Projekt mit Bundle-ID, Assets, etc.
2. **Core Data + CloudKit Integration** - 3 Entitäten (Room, Box, Item) mit Sync
3. **Liquid Glass Design System** - 6 Stile, 4 Tiefenebenen, vollständig animiert
4. **App-Architektur (MVVM + Observable)** - Swift 6.0 mit strict concurrency
5. **Services komplett implementiert:**
   - `QRCodeService.swift` - QR-Generierung, PDF-Export, Validation
   - `NFCService.swift` - Tag-Lesen/Schreiben, NDEF-Format
   - `CameraService.swift` - HDR, AI-Objekterkennung, Kategorisierung
   - `CloudKitService.swift` - Sync, Sharing, Konfliktauflösung
6. **ViewModels erstellt:**
   - `RoomListViewModel.swift` - Vollständige Raumverwaltung
   - `BoxDetailViewModel.swift` - Kistenverwaltung mit QR/NFC
7. **Hauptnavigation & Tab-Structure** - ContentView, Onboarding

#### 🚧 **Teilweise implementiert:**
- **Räume-Verwaltung:** `RoomsListView.swift` erstellt, fehlen noch:
  - `AddRoomSheet.swift`
  - `RoomDetailView.swift` 
  - `FilterAndSortSheet.swift`
  - `StatisticsDetailSheet.swift`

### 🎨 **Design-System Nutzung (WICHTIG):**

Das Projekt nutzt ein proprietäres **Liquid Glass Design System**. Verwende IMMER diese Modifier:

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

### 📁 **Projektstruktur verstehen:**

```
neuanfang-umzugshelfer/
├── App/                          # App Lifecycle
│   └── neuanfang_umzugshelferApp.swift
├── Models/
│   ├── CoreData/                 # Entities + PersistenceController
│   └── ViewModels/               # Observable ViewModels
├── Views/
│   ├── LiquidGlass/              # Design System (NICHT ÄNDERN)
│   ├── Rooms/                    # Raum-Views (teilweise implementiert)
│   ├── Boxes/                    # Kisten-Views (TODO)
│   ├── Items/                    # Gegenstände-Views (TODO)
│   ├── Timeline/                 # Timeline-Views (TODO)
│   ├── Settings/                 # Einstellungen (TODO)
│   └── Shared/                   # Wiederverwendbare Components
├── Services/                     # Business Logic (VOLLSTÄNDIG)
└── Resources/                    # Assets & Configs
```

---

## 🎯 **DEINE AUFGABEN - Priorisierte Todo-Liste:**

### 🔥 **SOFORT (Hohe Priorität):**

#### **Task 8: Kisten-Verwaltung mit QR/NFC Integration entwickeln**
**Dateien zu erstellen:**
1. `Views/Boxes/BoxListView.swift` - Übersicht aller Kisten eines Raums
2. `Views/Boxes/BoxDetailView.swift` - Detailansicht einer Kiste mit QR/NFC
3. `Views/Boxes/AddBoxSheet.swift` - Neue Kiste hinzufügen
4. `Views/Boxes/QRCodeView.swift` - QR-Code anzeigen/teilen
5. `Views/Boxes/NFCWriterView.swift` - NFC-Tag beschreiben

**Wichtige Features:**
- Integration mit bereits erstelltem `BoxDetailViewModel`
- QR-Code Generierung über `QRCodeService`
- NFC-Tag Beschreibung über `NFCService`
- Liquid Glass Design durchgehend verwenden
- Box-zu-Raum Zuordnung über Core Data Relationships

#### **Task 9: Gegenstände-Verwaltung mit Kamera-Integration**
**Dateien zu erstellen:**
1. `Views/Items/ItemListView.swift` - Gegenstände einer Kiste
2. `Views/Items/ItemDetailView.swift` - Einzelner Gegenstand mit Foto
3. `Views/Items/AddItemSheet.swift` - Gegenstand hinzufügen mit Kamera
4. `Views/Items/PhotoCaptureView.swift` - Kamera-Integration
5. `Models/ViewModels/ItemViewModel.swift` - Item-Management

**Wichtige Features:**
- Integration mit `CameraService` für Fotos
- AI-Objekterkennung für automatische Kategorisierung
- Zerbrechlichkeits-Vorhersage
- Werteingabe mit Währungsformatierung
- Foto-Komprimierung und Thumbnail-Generierung

### 🔧 **MITTEL (Mittlere Priorität):**

#### **Task 13: Timeline und Umzugsplanung**
1. `Views/Timeline/TimelineView.swift` - Umzugs-Timeline mit Phasen
2. `Views/Timeline/TaskManagementView.swift` - Aufgabenverwaltung
3. `Models/ViewModels/TimelineViewModel.swift` - Timeline-Logik

#### **Task 17: Einstellungen und Datenexport**
1. `Views/Settings/SettingsView.swift` - Haupteinstellungen
2. `Views/Settings/DataExportView.swift` - CSV/PDF Export
3. `Views/Settings/CollaborationView.swift` - Teilen mit Familie

### 🎨 **SPÄTER (Niedrige Priorität):**

#### **Task 14: 3D Truck Loading Visualisierung (Metal 4)**
- Komplexe 3D-Visualisierung mit Metal Framework
- 3D-Modelle für Kisten und LKW
- Physik-Engine für optimale Beladung

#### **Task 15: Kollaborations- und Sharing-Features**
- CloudKit Sharing Integration
- Familienmitglieder einladen
- Echtzeit-Kollaboration

---

## 🚨 **WICHTIGE DEVELOPMENT-REGELN:**

### **1. Liquid Glass Design System verwenden:**
- **NIEMALS** standard SwiftUI-Styling verwenden
- **IMMER** `.liquidGlass()` Modifier einsetzen
- **NIEMALS** das LiquidGlass-System ändern

### **2. Core Data Relationships respektieren:**
```swift
// Existierende Beziehungen:
Room.boxes -> Set<Box>
Box.room -> Room
Box.items -> Set<Item>
Item.box -> Box
```

### **3. Bereits erstellte Services nutzen:**
- `QRCodeService.shared` für QR-Codes
- `NFCService()` für NFC-Tags  
- `CameraService()` für Fotos
- `CloudKitService.shared` für Sync

### **4. Error Handling Patterns:**
```swift
@Published var errorMessage: String?
@Published var isLoading = false

// In UI:
.alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
    Button("OK") { viewModel.errorMessage = nil }
} message: {
    Text(viewModel.errorMessage ?? "")
}
```

### **5. Navigation Patterns:**
- `NavigationStack` für iOS 16+
- `.sheet()` für Modals mit `.presentationDetents([.medium, .large])`
- `.navigationDestination()` für Navigation

### **6. Accessibility & Localization:**
- Deutsche Texte verwenden
- VoiceOver-Labels hinzufügen
- Dynamic Type unterstützen

---

## 📋 **Aktuelle Todo-Liste:**

```
[x] Projekt-Setup und Konfiguration erstellen
[x] Xcode Projekt-Struktur und Dependencies definieren  
[x] Core Data Model mit CloudKit Integration implementieren
[x] Liquid Glass Design System entwickeln
[x] App-Architektur (MVVM + Observable) aufbauen
[x] Hauptnavigation und Tab-Structure erstellen
[🚧] Räume-Verwaltung (Models, Views, ViewModels) implementieren
[ ] Kisten-Verwaltung mit QR/NFC Integration entwickeln
[ ] Gegenstände-Verwaltung mit Kamera-Integration erstellen
[x] QR-Code Service implementieren
[x] NFC Service für Tag-Lesen/Schreiben entwickeln
[x] CloudKit Synchronisationsservice erstellen
[ ] Timeline und Umzugsplanung implementieren
[ ] 3D Truck Loading Visualisierung (Metal 4) entwickeln
[ ] Kollaborations- und Sharing-Features erstellen
[ ] Erweiterte Suchfunktionen implementieren
[ ] Einstellungen und Datenexport entwickeln
[ ] Barrierefreiheit und Lokalisierung hinzufügen
[ ] Unit Tests und Integration Tests erstellen
[ ] Dokumentation und finale Optimierungen
```

---

## 🎯 **Nächste konkrete Schritte:**

1. **Schließe Räume-Verwaltung ab:**
   - Erstelle `Views/Rooms/AddRoomSheet.swift`
   - Erstelle `Views/Rooms/RoomDetailView.swift`
   - Vervollständige fehlende Sheet-Views

2. **Beginne mit Kisten-Verwaltung:**
   - Erstelle `Views/Boxes/` Verzeichnis
   - Implementiere `BoxListView.swift` als erstes
   - Verbinde mit bereits erstelltem `BoxDetailViewModel`

3. **Teste kontinuierlich:**
   - Verwende Preview-Provider für jede View
   - Teste Core Data Relationships
   - Prüfe Liquid Glass Design Konsistenz

**Viel Erfolg bei der Weiterentwicklung! Das Fundament ist solide - jetzt geht es um die User-Experience! 🚀**