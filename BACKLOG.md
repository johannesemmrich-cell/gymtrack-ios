# BACKLOG

Alleinige Quelle der Wahrheit für den Aufgabenstand. Workflow-Regeln siehe `CLAUDE.md`.

## Offen

- **Aktives Gym nach Löschung** – wenn das aktuell aktive Gym gelöscht wird, ist danach kein Gym mehr aktiv (kein Auto-Promote). Für V1 akzeptiert, aber relevant sobald Gewichts-Vorschlag/Workout-Logging vom aktiven Gym abhängen – dann entscheiden, ob automatisch ein anderes Gym aktiv werden soll.
- **Gewichts- & Wiederholungs-Vorschlag pro Übung+Gym** – Business-Logik: letztes Gewicht UND letzte Wiederholungszahl pro (Übung, Gym) aus der Satz-Historie ableiten, beim nächsten Training in diesem Gym automatisch vorschlagen (kein neues Datenmodell nötig, `SetEntry` hat `weight`/`reps`/`exercise`/`gym`/`session.startedAt` bereits). Unit-Tests für die Vorschlagslogik.
- **Gym-Umrechnungsfaktor** – optionaler Umrechnungsfaktor zwischen Gyms (pro Übung oder global einstellbar), damit Statistiken/PRs gym-übergreifend auf ein Referenz-Gym umgerechnet vergleichbar sind. Unit-Tests für die Umrechnung, inkl. Edge Case "Gym ohne Historie".
- **Übungsbibliothek** – vordefinierte Grundmenge an Standardübungen, durchsuchbar, eigene Übungen jederzeit ergänzbar.
- **Plan-Editor: freie Erstellung** – Übungen aus der Bibliothek hinzufügen, Drag & Drop-Neuanordnung, Sätze/Wiederholungen/Gewicht mit sinnvollen Default-Werten (letzte genutzte Werte oder 3×10) vorausgefüllt. Notizfeld pro Plan-Übung (`PlanExercise.note`) editierbar machen; permanente Ausrüstungs-Notiz (Sitz/Griff) pro Übung+Gym anzeigen/editierbar machen.
- **Vorlagen-basierte Pläne** – mitgelieferte Split-Vorlagen (z. B. Push/Pull/Legs, Ganzkörper) als Startpunkt, danach frei anpassbar.
- **Plan/Workout duplizieren** – bestehenden Plan oder vorheriges Training als Kopie übernehmen und nur Details ändern.
- **Import/Export von Plänen (JSON)** – Export über iOS Share Sheet, Import z. B. aus der Files-App, inkl. Validierung/Fehlermeldung bei beschädigter Datei. Unit-Tests fürs Parsing inkl. Edge Case "beschädigte Datei".
- **Workout starten & normale Sätze loggen** – Workout aus einem Plan starten, Sätze mit Gewicht/Wiederholungen loggen. Temporäre Notiz pro geloggtem Satz (`SetEntry.note`) editierbar machen; permanente Ausrüstungs-Notiz (Sitz/Griff) automatisch vorschlagen wie das Gewicht.
- **Aufwärmsatz-Logik** – Gewicht wird automatisch als gestaffelter Prozentsatz des ersten Arbeitssatzes vorgeschlagen (z. B. 50/70/85 %), frei überschreibbar. Hinzufügen/Entfernen eines Aufwärmsatzes darf **nie** das Gewicht anderer Sätze verändern (RepCount-Bugfix). Unit-Tests explizit für diesen Fall.
- **Supersets** – mehrere Übungen als Gruppe direkt hintereinander loggen, visuell klar gruppiert.
- **Dropsets** – mehrere Sätze derselben Übung direkt hintereinander mit abnehmendem Gewicht ohne Pause, als zusammengehörige Einheit erkennbar.
- **Workout beenden** – ein unaufdringlicher Hinweis bei nicht ausgefüllten Übungen/Sätzen ("X Übungen nicht ausgefüllt – entfernen?"), mit einem Tap erledigt. Nicht bestätigte/leere Einträge fließen nie in Statistiken/PRs ein.
- **Statistik: Trainingsdauer & Frequenz** – durchschnittliche Trainingsdauer, Trainingsfrequenz pro Woche (Durchschnitt).
- **Statistik: meistgemachte Übungen** – Häufigkeit pro Übung.
- **Statistik: Trainingsvolumen über Zeit** – pro Übung und gesamt.
- **Statistik: Personal Records / geschätztes 1RM** – gym-übergreifend vergleichbar via Umrechnungsfaktor. Unit-Tests für die 1RM-Formel inkl. Edge Cases (0 Wiederholungen, keine Historie).
- **Durchgängiges Design-Polishing** – SF Symbols, Light/Dark Mode, Dynamic Type & VoiceOver-Grundlagen über alle bis dahin gebauten Screens.

## In Arbeit

(noch leer)

## Erledigt

- **Gym-Verwaltung (UI)** – Gyms anlegen/bearbeiten/löschen (Name, optionale Notiz), ein Gym als aktuell aktiv markieren. *(2026-08-11)*
  - Gebaut: erste echte UI-Ticket des Projekts. `GymActivation` (ViewModels/) als pure, testbare Business-Logik ("genau ein Gym aktiv"); `GymListView` (Liste mit Tap-zum-Aktivieren, Swipe-Löschen, Swipe-Bearbeiten, Empty State) + `GymFormView` (Anlegen/Bearbeiten-Sheet, Name Pflicht, Notiz optional, getrimmt, leere Notiz wird zu `nil`); Einstellungen-Tab in `ContentView` verlinkt jetzt zu Gyms statt Platzhaltertext. `--uitesting`-Launch-Flag sorgt dafür, dass UI-Tests den In-Memory-Container statt des echten CloudKit-Stores benutzen (keine Verschmutzung echter Daten, keine Flakiness durch alte Testdaten).
  - Getestet: 6 neue Unit-Tests für `GymActivation` (Deaktivieren anderer, bereits-aktiv bleibt aktiv, einzelnes Gym, leere Liste, Ziel nicht in Liste, mehrere fälschlich aktive Gyms werden auf eins korrigiert) + 1 neuer XCUITest (Gym anlegen erscheint in der Liste). Gesamt 31 Unit-Tests + 2 UI-Tests grün.
  - Bug gefunden & behoben: Der neue UI-Test schlug erst fehl, weil `GymRow` per `.accessibilityElement(children: .combine)` (für VoiceOver) den Namen-Text in das Label des umschließenden Buttons verschmilzt – `app.staticTexts["Test-Gym"]` fand daher nichts. Auf `app.buttons[...]` umgestellt.
  - Unabhängiger Review-Pass: APPROVE. Reviewer fand zusätzlich, dass der kombinierte Button-Label bei Gyms **mit Notiz** zu `"Name, Notiz"` wird – künftige Tests, die nur nach dem Namen suchen, würden das nicht mehr finden. Behoben durch zusätzliche stabile `.accessibilityIdentifier(gym.name)` auf dem Button, unabhängig vom VoiceOver-Label. Danach erneut Build+Tests grün.
  - Bekannte, akzeptierte Lücke: Löschen des aktiven Gyms lässt kein Gym aktiv (kein Auto-Promote) – als eigener Backlog-Punkt unter "Offen" festgehalten.

- **Datenmodell-Erweiterung: Temporäre Erinnerungs-Notiz** – neue Entity für eine Notiz pro (Übung, Gym), die einmalig beim nächsten Training dieser Übung in genau diesem Gym angezeigt und danach automatisch nicht mehr angezeigt wird (Anzeige-/Konsum-Logik selbst ist Teil der späteren Workout-Logging-UI, hier nur das Datenmodell). *(2026-08-11)*
  - Gebaut: neue Entity `ExerciseGymReminder` (Exercise+Gym → `text`, `isConsumed`-Flag), cascade-delete auf beiden Seiten wie bei `ExerciseGymNote`. Das eigentliche "beim nächsten Training anzeigen und danach ausblenden" ist bewusst nicht Teil dieses Tickets – das ist Business-/UI-Logik einer späteren Workout-Logging-Aufgabe, hier nur die Datengrundlage (Text + Konsum-Status + Ziel).
  - Getestet: 5 neue XCTest-Fälle (Defaults, Cascade-Delete bei Exercise-Löschung, Cascade-Delete bei Gym-Löschung, Geschwister-Isolation zwischen zwei Gyms, mehrere gleichzeitig offene Reminder für dieselbe Übung+Gym-Kombination möglich da keine Unique-Constraint). Gesamt 25 Unit-Tests + 1 UI-Test grün.
  - Unabhängiger Review-Pass: APPROVE, keine Findings. Reviewer hat den Cascade-Fix durch eine Mutationsprobe verifiziert (Inverse entfernt → Crash reproduziert → zurückgesetzt → wieder grün) und gegen `ExerciseGymNote` auf Konsistenz geprüft.

- **Datenmodell-Erweiterung: Notizen** – dauerhafte Ausrüstungs-Notiz pro Übung+Gym (z. B. Sitzposition, Griff), immer automatisch abrufbar wie das Gewicht; zusätzlich temporäre Notizfelder pro Plan-Übung (`PlanExercise.note`) und pro geloggtem Satz (`SetEntry.note`). *(2026-08-11)*
  - Gebaut: neue Entity `ExerciseGymNote` (Exercise+Gym → permanente Notiz), cascade-delete auf beiden Seiten (Notiz ohne Übung oder Gym ist bedeutungslos); `note`-Feld auf `PlanExercise` und `SetEntry` für temporäre, instanzgebundene Notizen. Kein neues Datenmodell für "Gewicht+Wiederholungen merken" nötig – dafür reicht die vorhandene Satz-Historie, betrifft nur die Business-Logik einer späteren Ticket-Umsetzung (siehe "Gewichts- & Wiederholungs-Vorschlag pro Übung+Gym" unter Offen).
  - Getestet: 6 neue XCTest-Fälle (Defaults/Settability für beide Notiz-Felder, Cascade-Delete bei Exercise-Löschung, Cascade-Delete bei Gym-Löschung, Geschwister-Isolation zwischen zwei Gyms). Gesamt 20 Unit-Tests + 1 UI-Test grün, inkl. der bestehenden `testSchemaIsCloudKitCompatible`, die die neue Entity automatisch mit abdeckt.
  - Unabhängiger Review-Pass: APPROVE, keine Findings.

- **Datenmodell (SwiftData)** – Gym, Exercise, TrainingPlan, PlanExercise, WorkoutSession, SetEntry, PersonalRecord inkl. Relationships/Delete-Rules, CloudKit-kompatibel; Persistence-Layer + minimaler App-Einstieg. *(2026-08-11)*
  - Gebaut: 7 SwiftData-`@Model`-Typen mit korrekten Cascade/Nullify-Delete-Rules (TrainingPlan→PlanExercise und WorkoutSession→SetEntry cascadieren, Gym/Exercise-Rückreferenzen nullifizieren statt zu löschen), Enum-Persistenz über Raw-Value-Strings (`MuscleGroup`, `SetType`) mit Fallback auf Default bei unbekanntem Rohwert, `PersistenceController` (echter CloudKit-Container + In-Memory-Variante für Tests), minimaler `GymTrackApp`/`ContentView`-Einstieg mit Tab-Skeleton.
  - Getestet: 14 XCTest-Unit-Tests (Defaults/0-Werte, Enum-Rundtrip inkl. unbekannter Rohwerte, Cascade-Delete für Plan→PlanExercise und Session→SetEntry, Nullify bei Exercise-Löschung, 50-Sätze-Stresstest, explizite CloudKit-Schema-Validierung mit aktiviertem `cloudKitDatabase`) + 1 XCUITest (App-Start zeigt TabBar). Build & Tests laufen grün auf iPhone 17 Simulator (iOS 26.5).
  - Bug gefunden & behoben: Erster Testlauf crashte beim App-Start, weil `Exercise`/`Gym` für mehrere Relationships keine explizite Inverse hatten (SwiftData+CloudKit-Pflicht). Behoben durch `@Relationship(inverse:)`-Rückreferenzen auf beiden Seiten; Regressionstest `testSchemaIsCloudKitCompatible` verhindert, dass das unbemerkt wieder passiert (der reine In-Memory-Container ohne CloudKit hätte den Fehler nicht gefunden).
  - Unabhängiger Review-Pass (frischer Subagent): APPROVE, keine blockierenden Findings. Reviewer hat den Inverse-Fix live durch eine Mutationsprobe verifiziert (Inverse entfernt → exakt derselbe Crash reproduziert → zurückgesetzt → wieder grün).
