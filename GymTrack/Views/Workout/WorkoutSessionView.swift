import SwiftUI

struct WorkoutSessionView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext

    @State private var setToEdit: SetEntry?
    @State private var isPresentingIncompleteAlert = false

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
        List {
            ForEach(groupedSets, id: \.exercise.id) { entry in
                Section {
                    ForEach(entry.items) { set in
                        Button {
                            setToEdit = set
                        } label: {
                            SetRow(set: set)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("Satz \(set.order)")
                    }
                    .onDelete { offsets in
                        delete(sets: entry.items, at: offsets)
                    }

                    HStack {
                        Button {
                            addWarmupSet(for: entry.exercise, in: entry.items)
                        } label: {
                            Label("Aufwärmsatz", systemImage: "flame")
                        }
                        .buttonStyle(.borderless)
                        Button {
                            addDropset(for: entry.exercise, in: entry.items)
                        } label: {
                            Label("Dropsatz", systemImage: "arrow.down.to.line")
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                        Button {
                            addSet(for: entry.exercise, basedOn: entry.items.last)
                        } label: {
                            Label("Satz hinzufügen", systemImage: "plus")
                        }
                        .buttonStyle(.borderless)
                    }
                } header: {
                    let partnerNames = supersetPartnerNames(for: entry)
                    if partnerNames.isEmpty {
                        Text(entry.exercise.name)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.exercise.name)
                            Text("🔗 Superset mit \(partnerNames.joined(separator: ", "))")
                                .textCase(nil)
                        }
                    }
                }
            }
        }
        .navigationTitle(session.planName ?? "Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Beenden") { endWorkoutTapped() }
            }
        }
        .sheet(item: $setToEdit) { set in
            SetEditView(set: set)
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
            reps: lastSet?.reps ?? 10,
            weight: lastSet?.weight ?? 0,
            supersetGroupID: lastSet?.supersetGroupID,
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
            reps: lastSet?.reps ?? 10,
            weight: DropsetSuggestion.suggestedWeight(previousWeight: lastSet?.weight ?? 0),
            supersetGroupID: lastSet?.supersetGroupID,
            exercise: exercise,
            gym: session.gym,
            session: session
        )
        modelContext.insert(newDropset)
        try? modelContext.save()
    }

    private func addWarmupSet(for exercise: Exercise, in exerciseSets: [SetEntry]) {
        let firstWorkingSet = exerciseSets.first { $0.setType == .normal }
        let workingWeight = firstWorkingSet?.weight ?? 0
        let existingWarmupCount = exerciseSets.filter { $0.setType == .warmup }.count
        let suggestion = WarmupSuggestion.suggestedWeights(workingWeight: workingWeight, count: existingWarmupCount + 1)
        let newWeight = suggestion.last ?? 0
        let reps = firstWorkingSet?.reps ?? 10

        let newWarmup = SetEntry(
            setType: .warmup,
            reps: reps,
            weight: newWeight,
            // Every set for one exercise shares the same supersetGroupID (set once at session
            // build time) — any existing sibling set's value is a safe source to copy from,
            // preferring a working set but falling back to whatever's there (e.g. an earlier
            // warmup) if this is the very first set logged for the exercise.
            supersetGroupID: firstWorkingSet?.supersetGroupID ?? exerciseSets.first?.supersetGroupID,
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

    private func endWorkout() {
        session.endedAt = .now
        try? modelContext.save()
    }
}

private struct SetRow: View {
    let set: SetEntry

    var body: some View {
        HStack {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(set.isCompleted ? .green : .secondary)
            if set.setType == .warmup {
                Image(systemName: "flame")
                    .foregroundStyle(.orange)
            } else if set.setType == .dropset {
                Image(systemName: "arrow.down.to.line")
                    .foregroundStyle(.purple)
            }
            Text("\(set.weight.formatted()) kg × \(set.reps)")
            Spacer()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
