# CLAUDE.md – GymTrack

Diese Datei wird bei jeder Session **zuerst** gelesen (zusammen mit `BACKLOG.md`), bevor irgendetwas anderes passiert.

## Projekt

Private iOS-Fitness-App (Krafttraining) für einen einzelnen Nutzer. SwiftUI + SwiftData + CloudKit-Sync, kein Server-Backend, keine Accounts, keine Paywall/Monetarisierung. Nur iPhone, iOS 17+, Swift 6, MVVM.

## Verbindlicher Workflow für JEDE Aufgabe (keine Ausnahmen, auch nicht für kleine Änderungen)

1. **Plan lesen/erstellen** – Aufgabe aus `BACKLOG.md` nehmen, bei Bedarf in Unterschritte zerlegen, kurz auflisten was sich ändert (Dateien, Datenmodell, UI). Aufgabe nach "In Arbeit" verschieben.
2. **Tests zuerst denken** – Unit-Tests (XCTest) für Business-Logik vor/parallel zur Implementierung schreiben (z. B. Gewichts-Vorschlagslogik, Gym-Umrechnung, Statistik-Berechnungen, Import/Export-Parsing). Für zentrale User-Flows (Plan erstellen, Workout loggen, Workout beenden) UI-Tests (XCUITest) ergänzen.
3. **Implementieren.**
4. **Build & alle Tests lokal ausführen** (`xcodegen generate` + `xcodebuild test ...`, siehe README). Fehler selbst beheben, bis Build und Tests grün sind.
5. **Unabhängiger Review-Pass** – separaten Subagenten mit frischem Kontext starten, der ausschließlich den Diff/die neuen Dateien gegen die ursprüngliche Aufgabenbeschreibung und gegen mögliche Bugs/Edge-Cases prüft (u. a. Klassiker wie "Aufwärmsatz löschen verschiebt Gewicht anderer Sätze" dürfen so nicht wieder passieren). Der Reviewer darf Änderungen ablehnen und Korrekturen verlangen.
6. **Edge Cases manuell durchdenken** und, wo sinnvoll, zusätzliche Tests dafür ergänzen (leere Listen, 0-Werte, sehr viele Sätze, Gym ohne Historie, Import einer beschädigten Datei etc.).
7. Erst wenn Build, alle Tests und der Review-Pass sauber sind: Backlog-Eintrag nach "Erledigt" verschieben, kurzer Changelog-Eintrag (was wurde gebaut, was wurde getestet).
8. Falls in Schritt 5 oder 6 Probleme auffallen: zurück zu Schritt 3, keine Abkürzungen.

Dieser Workflow gilt ausnahmslos für jede Aufgabe – keine Aufgabe gilt als fertig, nur weil sie kompiliert.

## Feste Regeln

- `BACKLOG.md` ist die alleinige Quelle der Wahrheit für offene Aufgaben, nicht der Chat-Verlauf.
- Sagt der Nutzer "schreib X ins Backlog" o. ä., wird es unter "Offen" eingetragen – mit kurzer Beschreibung, ohne dass der Nutzer das selbst in die Datei schreiben muss.
- Kein Third-Party-Dependency-Wildwuchs – nur per Swift Package Manager einbinden, und nur wenn wirklich nötig.
- Business-Logik (Statistik-Berechnung, Gewichts-Vorschlagslogik, Gym-Umrechnung) gehört in testbare ViewModel-/Service-Typen, nicht in Views versteckt.
- Barrierefreiheit (Dynamic Type, VoiceOver-Labels) von Anfang an mitdenken, so weit mit vertretbarem Aufwand möglich.
- Light- und Dark-Mode müssen funktionieren.
- Bedienung so schnell wie möglich – wenige Taps für die häufigsten Aktionen (Satz loggen, Plan starten, Workout beenden).

## Architektur

- `GymTrack/Models` – SwiftData `@Model`-Typen
- `GymTrack/ViewModels` – Business-Logik, unit-testbar
- `GymTrack/Views` – SwiftUI-Views, möglichst dünn
- `GymTrack/Persistence` – ModelContainer/-Configuration
- `GymTrackTests` – XCTest
- `GymTrackUITests` – XCUITest

## SwiftData + CloudKit – feste Einschränkungen (nicht versehentlich brechen)

- Keine `@Attribute(.unique)` – von CloudKit nicht unterstützt.
- Alle gespeicherten Properties brauchen einen Default-Wert oder müssen optional sein.
- To-many-Relationships als optionales Array deklarieren (`[X]? = []`).
- Enums werden als Raw-Value-String gespeichert (Computed Property für den typisierten Zugriff), nicht direkt als Codable-Enum – vermeidet bekannte Predicate-/Mirroring-Probleme.
