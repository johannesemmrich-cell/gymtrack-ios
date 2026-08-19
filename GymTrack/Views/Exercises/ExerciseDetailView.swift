import SwiftUI
import SwiftData

/// Per-exercise long-term goal (target weight and/or target reps) plus a live progress
/// visualization derived from the exercise's own completed set history. Pushed (not modal) since
/// it's a screen to check back on repeatedly, not a one-shot form — fields autosave on change
/// like `WorkoutSessionView`'s `SetRow`, no separate "Fertig" button needed.
struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [WorkoutSession]

    @State private var goal: ExerciseGoal?
    @State private var targetWeightText: String = ""
    @State private var targetRepsText: String = ""

    private var weightProgress: GoalMetricProgress? {
        guard let target = goal?.targetWeight else { return nil }
        return GoalProgress.weightProgress(for: exercise, in: sessions, target: target)
    }

    private var repsProgress: GoalMetricProgress? {
        guard let target = goal?.targetReps else { return nil }
        return GoalProgress.repsProgress(for: exercise, in: sessions, target: target)
    }

    var body: some View {
        Form {
            Section("Langfristiges Ziel") {
                HStack {
                    Text("Zielgewicht (kg)")
                    Spacer()
                    TextField("optional", text: $targetWeightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("Zielgewicht")
                        .accessibilityLabel("Zielgewicht")
                        .onChange(of: targetWeightText) { _, newValue in
                            let parsed = WeightInput.parse(newValue)
                            goal?.targetWeight = (parsed ?? 0) > 0 ? parsed : nil
                            save()
                        }
                }
                HStack {
                    Text("Ziel-Wiederholungen")
                    Spacer()
                    TextField("optional", text: $targetRepsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("Ziel-Wiederholungen")
                        .accessibilityLabel("Ziel-Wiederholungen")
                        .onChange(of: targetRepsText) { _, newValue in
                            let parsed = Int(newValue)
                            goal?.targetReps = (parsed ?? 0) > 0 ? parsed : nil
                            save()
                        }
                }
            }

            if let weightProgress {
                Section("Fortschritt Gewicht") {
                    GoalProgressRow(progress: weightProgress) { "\($0.formatted()) kg" }
                }
                .accessibilityIdentifier("Fortschritt Gewicht")
            }

            if let repsProgress {
                Section("Fortschritt Wiederholungen") {
                    GoalProgressRow(progress: repsProgress) { "\(Int($0)) Wdh." }
                }
                .accessibilityIdentifier("Fortschritt Wiederholungen")
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadInitialState)
    }

    private func loadInitialState() {
        let existing = ExerciseGoalStore.findOrCreate(exercise: exercise, in: modelContext)
        goal = existing
        targetWeightText = existing.targetWeight.map { $0.formatted() } ?? ""
        targetRepsText = existing.targetReps.map(String.init) ?? ""
    }

    private func save() {
        goal?.updatedAt = .now
        try? modelContext.save()
    }
}

private struct GoalProgressRow: View {
    let progress: GoalMetricProgress
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: progress.fraction)
                .tint(progress.isAchieved ? .green : .accentColor)
            HStack {
                Text(progress.current.map { "Aktuell: \(format($0))" } ?? "Noch keine protokollierten Sätze")
                Spacer()
                if progress.isAchieved {
                    Label("Ziel erreicht", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("Noch \(format(progress.remaining))")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
        .accessibilityElement(children: .combine)
    }
}
