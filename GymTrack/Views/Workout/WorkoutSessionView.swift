import SwiftUI

struct WorkoutSessionView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext

    @State private var isPresentingIncompleteAlert = false
    @State private var viewMode: ViewMode = .overview
    @State private var focusedExerciseIndex = 0

    enum ViewMode: Hashable {
        case overview
        case focused
    }

    private var incompleteSetCount: Int {
        WorkoutCompletion.incompleteSets(in: session).count
    }

    private var groupedSets: [(exercise: Exercise, items: [SetEntry])] {
        let sets = (session.sets ?? []).sorted { $0.order < $1.order }
        var order: [UUID] = []
        var exercisesByID: [UUID: Exercise] = [:]
        var setsByExerciseID: [UUID: [SetEntry]] = [:]

        for set in sets {
            guard let exercise = set.exercise else { continue }
            if exercisesByID[exercise.id] == nil {
                exercisesByID[exercise.id] = exercise
                order.append(exercise.id)
            }
            setsByExerciseID[exercise.id, default: []].append(set)
        }

        return order.compactMap { id in
            guard let exercise = exercisesByID[id], let items = setsByExerciseID[id] else { return nil }
            return (exercise, items)
        }
    }

    /// Names of the other exercises sharing this exercise's superset group, if any — every set
    /// for one exercise carries the same `supersetGroupID` (set once at session build time), so
    /// the first set's value stands in for the whole group.
    private func supersetPartnerNames(for entry: (exercise: Exercise, items: [SetEntry])) -> [String] {
        guard let groupID = entry.items.first?.supersetGroupID else { return [] }
        return groupedSets
            .filter { $0.exercise.id != entry.exercise.id && $0.items.first?.supersetGroupID == groupID }
            .map(\.exercise.name)
    }

    var body: some View {
        Group {
            switch viewMode {
            case .overview:
                overviewList
                    .transition(.opacity)
            case .focused:
                focusedExerciseView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewMode)
        .navigationTitle(session.planName ?? "Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if groupedSets.count > 1 {
                ToolbarItem(placement: .principal) {
                    Picker("Ansicht", selection: $viewMode.animation(.easeInOut(duration: 0.22))) {
                        Image(systemName: "list.bullet").tag(ViewMode.overview).accessibilityLabel("Gesamtansicht")
                        Image(systemName: "rectangle.portrait").tag(ViewMode.focused).accessibilityLabel("Übungsansicht")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .accessibilityIdentifier("Ansicht-Umschalter")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Beenden") { endWorkoutTapped() }
            }
        }
        .alert(
            "\(incompleteSetCount) \(incompleteSetCount == 1 ? "Satz" : "Sätze") nicht ausgefüllt",
            isPresented: $isPresentingIncompleteAlert
        ) {
            Button("Entfernen & Beenden", role: .destructive) {
                removeIncompleteSetsAndEnd()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Nicht ausgefüllte Sätze werden entfernt und fließen nicht in die Statistik ein.")
        }
    }

    private var overviewList: some View {
        List {
            ForEach(groupedSets, id: \.exercise.id) { entry in
                ExerciseSetsSection(
                    exercise: entry.exercise,
                    items: entry.items,
                    partnerNames: supersetPartnerNames(for: entry),
                    onAddWarmup: { addWarmupSet(for: entry.exercise, in: entry.items) },
                    onAddDropset: { addDropset(for: entry.exercise, in: entry.items) },
                    onAddSet: { addSet(for: entry.exercise, basedOn: entry.items.last) },
                    onDelete: { offsets in delete(sets: entry.items, at: offsets) },
                    onToggleCompleted: toggleCompleted
                )
            }
        }
    }

    /// Clamped to the currently valid range on every access rather than corrected reactively
    /// via `onChange` — the previous `onChange(of: groupedSets.count)` approach only ran while
    /// `focusedExerciseView` itself was mounted, so switching to Gesamtansicht, deleting the
    /// focused exercise's sets there, then switching back to Übungsansicht could land on a
    /// stale, now out-of-range index and show "Keine Übung" despite valid exercises remaining.
    private var safeFocusedExerciseIndex: Int {
        guard !groupedSets.isEmpty else { return 0 }
        return min(focusedExerciseIndex, groupedSets.count - 1)
    }

    private var focusedExerciseView: some View {
        VStack(spacing: 0) {
            if groupedSets.indices.contains(safeFocusedExerciseIndex) {
                let index = safeFocusedExerciseIndex
                let entry = groupedSets[index]
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { focusedExerciseIndex = index - 1 }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                    }
                    .disabled(index == 0)
                    .accessibilityLabel("Vorherige Übung")

                    Spacer()

                    VStack(spacing: 2) {
                        Text(entry.exercise.name)
                            .font(.title3.bold())
                        Text("Übung \(index + 1) von \(groupedSets.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { focusedExerciseIndex = index + 1 }
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                    }
                    .disabled(index == groupedSets.count - 1)
                    .accessibilityLabel("Nächste Übung")
                }
                .padding()
                .accessibilityIdentifier("Übungsansicht-Kopf")

                List {
                    ExerciseSetsSection(
                        exercise: entry.exercise,
                        items: entry.items,
                        partnerNames: supersetPartnerNames(for: entry),
                        onAddWarmup: { addWarmupSet(for: entry.exercise, in: entry.items) },
                        onAddDropset: { addDropset(for: entry.exercise, in: entry.items) },
                        onAddSet: { addSet(for: entry.exercise, basedOn: entry.items.last) },
                        onDelete: { offsets in delete(sets: entry.items, at: offsets) },
                        onToggleCompleted: toggleCompleted
                    )
                }
            } else {
                ContentUnavailableView(
                    "Keine Übung",
                    systemImage: "figure.strengthtraining.traditional"
                )
            }
        }
    }

    private func endWorkoutTapped() {
        if incompleteSetCount > 0 {
            isPresentingIncompleteAlert = true
        } else {
            endWorkout()
        }
    }

    private func removeIncompleteSetsAndEnd() {
        for set in WorkoutCompletion.incompleteSets(in: session) {
            modelContext.delete(set)
        }
        endWorkout()
    }

    private func addSet(for exercise: Exercise, basedOn lastSet: SetEntry?) {
        let nextOrder = ((session.sets ?? []).map(\.order).max() ?? -1) + 1
        let newSet = SetEntry(
            order: nextOrder,
            setType: .normal,
            reps: 0,
            weight: 0,
            supersetGroupID: lastSet?.supersetGroupID,
            suggestedWeight: lastSet?.effectiveWeight,
            suggestedReps: lastSet?.effectiveReps,
            // For a unilateral exercise, an extra manually-added set continues the alternating
            // pattern (opposite side from whatever came last) instead of dropping side-tracking.
            side: lastSet?.side?.opposite,
            exercise: exercise,
            gym: session.gym,
            session: session
        )
        modelContext.insert(newSet)
        try? modelContext.save()
    }

    private func addDropset(for exercise: Exercise, in exerciseSets: [SetEntry]) {
        // Dropsets are logged back-to-back right after the set they drop from, so — unlike
        // warmups, which must precede the working sets — appending at the end of this
        // exercise's own sets (same as addSet) already positions it correctly; no reordering.
        // Drops from the most recent non-warmup set, not a warmup — dropping from a warmup's
        // (much lighter) weight would produce a nonsensical suggestion if Dropsatz is tapped
        // before any working set has been logged yet.
        let lastSet = exerciseSets.last { $0.setType != .warmup } ?? exerciseSets.last
        let nextOrder = ((session.sets ?? []).map(\.order).max() ?? -1) + 1
        let newDropset = SetEntry(
            order: nextOrder,
            setType: .dropset,
            reps: 0,
            weight: 0,
            supersetGroupID: lastSet?.supersetGroupID,
            suggestedWeight: DropsetSuggestion.suggestedWeight(previousWeight: lastSet?.effectiveWeight ?? 0),
            suggestedReps: lastSet?.effectiveReps,
            // A dropset is a direct continuation of the specific set it drops from, so it
            // inherits that set's side (unlike a warmup, which stays side-less) — also keeps
            // a later manual "Satz hinzufügen" (which continues the alternating pattern from
            // whatever the last set's side was) from silently losing side-tracking.
            side: lastSet?.side,
            exercise: exercise,
            gym: session.gym,
            session: session
        )
        modelContext.insert(newDropset)
        try? modelContext.save()
    }

    private func addWarmupSet(for exercise: Exercise, in exerciseSets: [SetEntry]) {
        let firstWorkingSet = exerciseSets.first { $0.setType == .normal }
        let workingWeight = firstWorkingSet?.effectiveWeight ?? 0
        let existingWarmupCount = exerciseSets.filter { $0.setType == .warmup }.count
        let suggestion = WarmupSuggestion.suggestedWeights(workingWeight: workingWeight, count: existingWarmupCount + 1)
        let newWeight = suggestion.last ?? 0
        let reps = firstWorkingSet?.effectiveReps ?? 10

        let newWarmup = SetEntry(
            setType: .warmup,
            reps: 0,
            weight: 0,
            // Every set for one exercise shares the same supersetGroupID (set once at session
            // build time) — any existing sibling set's value is a safe source to copy from,
            // preferring a working set but falling back to whatever's there (e.g. an earlier
            // warmup) if this is the very first set logged for the exercise.
            supersetGroupID: firstWorkingSet?.supersetGroupID ?? exerciseSets.first?.supersetGroupID,
            suggestedWeight: newWeight,
            suggestedReps: reps,
            exercise: exercise,
            gym: session.gym,
            session: session
        )
        modelContext.insert(newWarmup)

        let allSets = (session.sets ?? [])
            .filter { $0 !== newWarmup }
            .sorted { $0.order < $1.order }
        let reordered = WarmupSetInsertion.insert(newWarmup, into: allSets, forExerciseID: exercise.id)
        SetEntryOrdering.reindex(reordered)

        try? modelContext.save()
    }

    private func delete(sets: [SetEntry], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sets[index])
        }
        try? modelContext.save()
    }

    private func toggleCompleted(_ set: SetEntry) {
        set.isCompleted.toggle()
        // From now on this row's completion is under the user's explicit control — further
        // weight/reps edits must not silently recompute over that decision.
        set.isCompletionManual = true
        try? modelContext.save()
    }

    private func endWorkout() {
        session.endedAt = .now
        try? modelContext.save()
    }
}

/// One exercise's worth of set rows plus its add-set controls — shared between the
/// Gesamtansicht (one section per exercise) and the Übungsansicht (a single instance for
/// whichever exercise is currently focused), so both stay in lockstep automatically.
private struct ExerciseSetsSection: View {
    let exercise: Exercise
    let items: [SetEntry]
    let partnerNames: [String]
    let onAddWarmup: () -> Void
    let onAddDropset: () -> Void
    let onAddSet: () -> Void
    let onDelete: (IndexSet) -> Void
    let onToggleCompleted: (SetEntry) -> Void

    var body: some View {
        Section {
            ForEach(items) { set in
                // Deliberately no row-level .accessibilityIdentifier here — SwiftUI applies an
                // identifier set on a composite child like this to every descendant
                // accessibility element it contains, which clobbered each field's own
                // more-specific identifier ("Satz N Gewicht" etc.) below. The weight field's
                // identifier stands in as the row's address for swipe actions instead.
                SetRow(set: set, kennung: SetKennung.label(for: set, in: items))
                    .swipeActions(edge: .leading) {
                        // A quick manual override for cases the weight-and-reps auto-completion
                        // rule doesn't fit (e.g. a genuine 0 kg bodyweight set).
                        Button(set.isCompleted ? "Nicht erledigt" : "Erledigt") {
                            onToggleCompleted(set)
                        }
                        .tint(set.isCompleted ? .gray : .green)
                    }
            }
            .onDelete(perform: onDelete)

            HStack {
                Button(action: onAddWarmup) {
                    Label("Aufwärmsatz", systemImage: "flame")
                }
                .buttonStyle(.borderless)
                Button(action: onAddDropset) {
                    Label("Dropsatz", systemImage: "arrow.down.to.line")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button(action: onAddSet) {
                    Label("Satz hinzufügen", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }
        } header: {
            if partnerNames.isEmpty {
                Text(exercise.name)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                    Text("🔗 Superset mit \(partnerNames.joined(separator: ", "))")
                        .textCase(nil)
                }
            }
        }
    }
}

/// One set, fully inline-editable: leading Kennung (A/D/Nummer), Gewicht, Wdh., Notiz — no
/// sheet. Ghost values (ungespeicherter Vorschlag aus Historie oder Aufwärm-/Dropsatz-
/// Berechnung) zeigen sich rein über den TextField-Placeholder, der von iOS bereits gedimmt
/// dargestellt wird. Wird Gewicht UND Wdh. real eingetragen, gilt der Satz automatisch als
/// erledigt (`SetCompletion`).
private struct SetRow: View {
    @Bindable var set: SetEntry
    let kennung: String

    @Environment(\.modelContext) private var modelContext
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    // Tracks whether the weight field has ever been touched, independent of the resulting
    // value — `set.weight == 0` alone can't tell "still showing the ghost placeholder" apart
    // from "user deliberately typed 0" (e.g. a real bodyweight set), so the ghost-to-real
    // autofill below must gate on this instead of on the value.
    @State private var weightManuallyEdited = false

    var body: some View {
        HStack(spacing: 8) {
            Text(kennung)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 18, alignment: .leading)
                .accessibilityIdentifier("Satz \(set.order) Kennung")
                .accessibilityLabel(kennungDescription)

            TextField(weightPlaceholder, text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 40)
                .accessibilityIdentifier("Satz \(set.order) Gewicht")
                .accessibilityLabel("\(kennungDescription), Gewicht")
                .onChange(of: weightText) { _, newValue in
                    weightManuallyEdited = true
                    set.weight = WeightInput.parse(newValue) ?? 0
                    updateCompletion()
                }

            Text("kg ×")
                .font(.caption2)
                .foregroundStyle(.secondary)

            TextField(repsPlaceholder, text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 30)
                .accessibilityIdentifier("Satz \(set.order) Wdh")
                .accessibilityLabel("\(kennungDescription), Wiederholungen")
                .onChange(of: repsText) { _, newValue in
                    let parsedReps = Int(newValue) ?? 0
                    set.reps = parsedReps
                    // Ghost-to-real autofill: only the moment reps first becomes real while
                    // weight has never been touched — never overwrites a weight the user
                    // already typed themselves, even if that was an explicit "0".
                    if parsedReps > 0, !weightManuallyEdited, let suggested = set.suggestedWeight {
                        weightManuallyEdited = true
                        set.weight = suggested
                        weightText = String(suggested)
                    }
                    updateCompletion()
                }

            TextField("Notiz", text: noteBinding)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("Satz \(set.order) Notiz")
                .accessibilityLabel("\(kennungDescription), Notiz")

            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(set.isCompleted ? Color.green : Color.secondary)
                .animation(.spring(duration: 0.25), value: set.isCompleted)
                .accessibilityLabel("\(kennungDescription), \(set.isCompleted ? "erledigt" : "nicht erledigt")")
        }
        .onAppear {
            weightText = set.weight == 0 ? "" : String(set.weight)
            repsText = set.reps == 0 ? "" : String(set.reps)
            weightManuallyEdited = set.weight != 0
        }
    }

    private var kennungDescription: String {
        switch set.setType {
        case .warmup: return "Aufwärmsatz"
        case .dropset: return "Dropsatz"
        case .normal:
            // The compact Kennung ("1 L") is fine to read visually, but VoiceOver should hear
            // the spelled-out side ("Links"/"Rechts"), not just the abbreviation letter.
            guard let side = set.side else { return "Satz \(kennung)" }
            return "Satz \(kennung), \(side.fullLabel)"
        }
    }

    private var weightPlaceholder: String {
        guard let suggested = set.suggestedWeight else { return "0" }
        return String(suggested)
    }

    private var repsPlaceholder: String {
        guard let suggested = set.suggestedReps else { return "0" }
        return String(suggested)
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { set.note ?? "" },
            set: {
                set.note = $0.isEmpty ? nil : $0
                try? modelContext.save()
            }
        )
    }

    private func updateCompletion() {
        // A manual swipe override (see WorkoutSessionView.toggleCompleted) takes itself out of
        // the auto-completion rule's hands until the user manually toggles it again — an
        // unrelated field edit (e.g. fixing a typo) must never silently revert their decision.
        guard !set.isCompletionManual else { return }
        set.isCompleted = SetCompletion.isComplete(weight: set.weight, reps: set.reps)
        try? modelContext.save()
    }
}
