# Xcode-Konfiguration für CloudKit Container-ID Externalisierung

## Übersicht
Nach der Implementierung der CloudKit Container-ID Externalisierung müssen die neuen Dateien zum Xcode-Projekt hinzugefügt werden.

## Neue Dateien

### 1. Config.plist
**Pfad:** `neuanfang-umzugshelfer/Resources/Config.plist`
**Typ:** Property List (plist)
**Ziel-Gruppe:** Resources

### 2. ConfigurationManager.swift
**Pfad:** `neuanfang-umzugshelfer/Services/ConfigurationManager.swift`
**Typ:** Swift Source
**Ziel-Gruppe:** Services

## Schritte in Xcode

### 1. Config.plist hinzufügen
1. Öffne das Xcode-Projekt
2. Rechtsklick auf den `Resources` Ordner
3. Wähle "Add Files to 'neuanfang-umzugshelfer'"
4. Navigiere zu `neuanfang-umzugshelfer/Resources/Config.plist`
5. Stelle sicher, dass "Add to target: neuanfang-umzugshelfer" angehakt ist
6. Klicke "Add"

### 2. ConfigurationManager.swift hinzufügen
1. Rechtsklick auf den `Services` Ordner
2. Wähle "Add Files to 'neuanfang-umzugshelfer'"
3. Navigiere zu `neuanfang-umzugshelfer/Services/ConfigurationManager.swift`
4. Stelle sicher, dass "Add to target: neuanfang-umzugshelfer" angehakt ist
5. Klicke "Add"

### 3. Build Settings überprüfen
1. Wähle das Projekt in der Navigator
2. Gehe zu "Build Settings"
3. Suche nach "Bundle Resources"
4. Stelle sicher, dass `Config.plist` in der Liste der Bundle-Ressourcen erscheint

### 4. CloudKit Konfiguration
1. Gehe zu "Signing & Capabilities"
2. Stelle sicher, dass CloudKit aktiviert ist
3. Überprüfe, dass der Container "iCloud.com.neuanfang.umzugshelfer" konfiguriert ist

## Validierung

### Build-Test
1. Führe einen Clean Build aus (`Cmd + Shift + K`, dann `Cmd + B`)
2. Überprüfe, dass keine Compilerfehler auftreten
3. Teste die App im Simulator

### Konfiguration testen
```swift
// Teste in einer View oder im App-Delegate:
let config = ConfigurationManager.shared
print("CloudKit Container ID: \(config.cloudKitContainerIdentifier)")
print("Environment: \(config.cloudKitEnvironment)")
```

## Troubleshooting

### Config.plist nicht gefunden
- Überprüfe, dass die Datei im Bundle enthalten ist
- Rechtsklick auf Config.plist → "Show in Finder"
- Stelle sicher, dass "Target Membership" für neuanfang-umzugshelfer aktiviert ist

### Compiler-Fehler
- Überprüfe, dass ConfigurationManager.swift korrekt importiert wurde
- Stelle sicher, dass alle Import-Statements vorhanden sind
- Clean und Rebuild

### CloudKit Funktionalität
- Teste CloudKit-Verbindung nach der Migration
- Überprüfe, dass keine hardcodierten Container-IDs mehr vorhanden sind
- Validiere, dass die Konfiguration korrekt geladen wird

## Geänderte Dateien

### CloudKitService.swift
- Container-Initialisierung verwendet jetzt ConfigurationManager
- Zeile 22: `private let container: CKContainer`
- Zeile 54-57: Konfiguration aus ConfigurationManager

### PersistenceController.swift
- CloudKit-Konfiguration verwendet ConfigurationManager
- Zeile 76-78: Container-ID aus Konfiguration
- Zeile 467-469: Container-Status-Check mit Konfiguration

## Sicherheitshinweise

- Die Container-ID ist öffentlich und kann in Config.plist bleiben
- Keine sensitiven API-Keys in Config.plist speichern
- Für Production vs. Development verschiedene Container verwenden

## Nächste Schritte

1. Dateien zu Xcode-Projekt hinzufügen
2. Build testen
3. Funktionalität validieren
4. CloudKit-Synchronisation testen
5. Unit-Tests für ConfigurationManager erstellen