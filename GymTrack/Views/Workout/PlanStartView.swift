import SwiftUI
import SwiftData

enum WorkoutStartSource {
    case plan(TrainingPlan)
    case repeatSession(WorkoutSession)
}

/// Read-only Gesamtansicht of what's about to be logged — the plan's (or the repeated
/// session's) exercises and sets, with any known weight/reps shown only as a ghost hint.
/// Nothing is written to the model context until "Training starten" is tapped, so backing
/// out of this screen leaves no trace.
///
/// The preview is computed purely from already-persisted data (`plan.exercises`, or the
/// source session's own completed sets) rather than by pre-building real `SetEntry` objects
/// — holding freshly created, not-yet-inserted, relationship-linked model objects in `@State`
/// across multiple render passes (as a screen the user might sit on for a while would need)
/// was found to corrupt SwiftUI's rendering of this screen. `WorkoutSessionBuilder`/
/// `WorkoutRepetition` still build the real objects, but only inside `start()`, immediately
/// followed by insertion — the same synchronous build-then-insert pattern already proven safe
/// everywhere else in the app.
struct PlanStartView: View {
    let source: WorkoutStartSource
    let gym: Gym?
    let setHistory: [SetEntry]
    let onStarted: (WorkoutSession) -> Void

    @Environment(\.modelContext) private var modelContext

    fileprivate struct PreviewRow: Identifiable {
        let id = UUID()
        let kennung: String
        let suggestedWeight: Double?
        let suggestedReps: Int?
    }

    private struct PreviewGroup: Identifiable {
        let id: UUID
        let exerciseName: String
        let rows: [PreviewRow]
    }

    private var title: String {
        switch source {
        case .plan(let plan): return plan.name
        case .repeatSession(let session): return session.planName ?? "Training"
        }
    }

    private var previewGroups: [PreviewGroup] {
        switch source {
        case .plan(let plan):
            return planPreviewGroups(for: plan)
        case .repeatSession(let session):
            return repeatPreviewGroups(for: session)
        }
    }

    private func planPreviewGroups(for plan: TrainingPlan) -> [PreviewGroup] {
        let planExercises = (plan.exercises ?? []).sorted { $0.order < $1.order }
        return planExercises.compactMap { planExercise -> PreviewGroup? in
            guard let exercise = planExercise.exercise else { return nil }
            let suggestion = gym.flatMap { SetSuggestion.suggest(for: exercise, gym: $0, from: setHistory) }
            let suggestedWeight = suggestion?.weight ?? planExercise.targetWeight
            let suggestedReps = suggestion?.reps ?? planExercise.targetReps
            // Same shared sequence WorkoutSessionBuilder builds its real sets from, so the
            // preview can never silently drift out of sync with what "Training starten"
            // actually creates.
            let sides = UnilateralSetPlan.sides(targetSets: planExercise.targetSets, isUnilateral: planExercise.isUnilateral)
            var countBySide: [ExerciseSide?: Int] = [:]
            let rows = sides.map { side -> PreviewRow in
                let nextIndex = (countBySide[side] ?? 0) + 1
                countBySide[side] = nextIndex
                let kennung = side.map { "\(nextIndex) \($0.shortLabel)" } ?? "\(nextIndex)"
                return PreviewRow(kennung: kennung, suggestedWeight: suggestedWeight, suggestedReps: suggestedReps)
            }
            return PreviewGroup(id: exercise.id, exerciseName: exercise.name, rows: rows)
        }
    }

    private func repeatPreviewGroups(for session: WorkoutSession) -> [PreviewGroup] {
        let sourceSets = (session.sets ?? []).filter(\.isCompleted).sorted { $0.order < $1.order }
        var order: [UUID] = []
        var namesByExerciseID: [UUID: String] = [:]
        var setsByExerciseID: [UUID: [SetEntry]] = [:]
        for set in sourceSets {
            guard let exercise = set.exercise else { continue }
            if namesByExerciseID[exercise.id] == nil {
                namesByExerciseID[exercise.id] = exercise.name
                order.append(exercise.id)
            }
            setsByExerciseID[exercise.id, default: []].append(set)
        }
        return order.compactMap { id in
            guard let name = namesByExerciseID[id], let sets = setsByExerciseID[id] else { return nil }
            let labels = SetKennung.labels(for: sets)
            let rows = sets.map { set in
                PreviewRow(kennung: labels[set.id] ?? "", suggestedWeight: set.weight, suggestedReps: set.reps)
            }
            return PreviewGroup(id: id, exerciseName: name, rows: rows)
        }
    }

    var body: some View {
        List {
            if previewGroups.isEmpty {
                ContentUnavailableView(
                    "Keine Übungen",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Dieser Plan hat noch keine Übungen.")
                )
            } else {
                ForEach(previewGroups) { group in
                    Section(group.exerciseName) {
                        ForEach(group.rows) { row in
                            PlanStartSetRow(row: row)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: start) {
                Text("Training starten")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .disabled(previewGroups.isEmpty)
            .accessibilityIdentifier("Training starten")
        }
    }

    private func start() {
        let result: (session: WorkoutSession, sets: [SetEntry])
        switch source {
        case .plan(let plan):
            result = WorkoutSessionBuilder.build(from: plan, gym: gym, setHistory: setHistory)
        case .repeatSession(let session):
            result = WorkoutRepetition.build(repeating: session, gym: gym)
        }
        modelContext.insert(result.session)
        for set in result.sets {
            modelContext.insert(set)
        }
        try? modelContext.save()
        onStarted(result.session)
    }
}

private struct PlanStartSetRow: View {
    fileprivate let row: PlanStartView.PreviewRow

    var body: some View {
        HStack(spacing: 12) {
            Text(row.kennung)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 18, alignment: .leading)
            Text(weightText)
                .foregroundStyle(.secondary)
            Text("×")
                .foregroundStyle(.secondary)
            Text(repsText)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var weightText: String {
        guard let weight = row.suggestedWeight else { return "– kg" }
        return "\(weight.formatted()) kg"
    }

    private var repsText: String {
        guard let reps = row.suggestedReps else { return "–" }
        return "\(reps)"
    }
}
