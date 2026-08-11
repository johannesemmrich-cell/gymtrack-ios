# GymTrack

Private Fitness/Gym-App für Krafttraining: Trainingspläne erstellen, Workouts loggen, Statistiken einsehen. Kein Server-Backend, keine Accounts, keine Paywall/Monetarisierung – alle Features sind für V1 frei nutzbar.

## Tech-Stack

- SwiftUI, Swift 6, iOS 17+ (nur iPhone, kein iPad-/Watch-Layout in V1)
- SwiftData mit CloudKit-Sync (private Datenbank)
- Architektur: MVVM (`Models` / `ViewModels` / `Views` / `Persistence`)
- XCTest (Unit-Tests) + XCUITest (UI-Tests) für die Kern-Flows
- Projekt-Generierung über [XcodeGen](https://github.com/yonaskolb/XcodeGen): `project.yml` ist die Quelle der Wahrheit, `GymTrack.xcodeproj` wird generiert und ist **nicht** eingecheckt (siehe `.gitignore`)

## Projekt öffnen

```bash
brew install xcodegen   # falls noch nicht installiert
cd GymTrack
xcodegen generate
open GymTrack.xcodeproj
```

Nach jeder Änderung an `project.yml` (neue Dateien werden davon i. d. R. nicht berührt, XcodeGen liest Ordner automatisch ein) reicht erneutes `xcodegen generate`.

## Einmalige manuelle Xcode-Einrichtung (nicht automatisierbar)

Diese Schritte sind an deinen persönlichen Apple-Developer-Account gebunden und müssen einmalig manuell in Xcode gemacht werden – das kann Claude Code nicht für dich erledigen:

1. Projekt in Xcode öffnen → Target **GymTrack** → Tab **Signing & Capabilities**.
2. Unter **Team** dein Apple-Developer-Team auswählen (behebt die anfänglichen Signing-Fehler).
3. Prüfen, dass die Capability **iCloud** aktiv ist, das Häkchen bei **CloudKit** gesetzt ist und der Container `iCloud.com.johannes.gymtrack` ausgewählt bzw. angelegt ist. Er ist in `GymTrack/GymTrack.entitlements` bereits vorbereitet, muss aber einmalig gegen deinen Account bestätigt werden.
4. `com.johannes.gymtrack` ist aktuell ein Platzhalter-Bundle-Identifier. Bei einer späteren Umbenennung muss der iCloud-Container-Identifier in den Entitlements (und `project.yml`) mit angepasst werden.

Zusätzlich braucht die lokale Kommandozeile die volle Xcode-Installation als aktives Dev-Tool (nicht nur die Command Line Tools):

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Tests ausführen

```bash
xcodegen generate
xcodebuild test -project GymTrack.xcodeproj -scheme GymTrack -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Workflow

Der verbindliche Entwicklungs-Workflow für jede Aufgabe steht in [`CLAUDE.md`](CLAUDE.md). Offene, laufende und erledigte Aufgaben stehen in [`BACKLOG.md`](BACKLOG.md) – diese Datei ist die alleinige Quelle der Wahrheit für den Aufgabenstand, nicht der Chat-Verlauf.
