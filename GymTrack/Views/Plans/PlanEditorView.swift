import SwiftUI
import SwiftData

struct PlanEditorView: View {
    @Bindable var plan: TrainingPlan

    @Environment(\.modelContext) private var modelContext
    @Query private var allPlanExercises: [PlanExercise]
    @Query(filter: #Predicate<Gym> { $0.isActive }) private var activeGyms: [Gym]

    @State private var isPresentingExercisePicker = false
    @State private var planExerciseToEdit: PlanExercise?

    private var sortedExercises: [PlanExercise] {
        (plan.exercises ?? []).sorted { $0.order < $1.order }
    }

    private var activeGym: Gym? { activeGyms.first }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Planname", text: $plan.name)
                    .accessibilityLabel("Planname")
            }

            Section("Übungen") {
                if sortedExercises.isEmpty {
                    ContentUnavailableView(
                        "Keine Übungen",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Füge Übungen zu diesem Plan hinzu.")
                    )
                } else {
                    ForEach(sortedExercises) { planExercise in
                        Button {
                            planExerciseToEdit = planExercise
                        } label: {
                            PlanExerciseRow(planExercise: planExercise)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(planExercise.exercise?.name ?? "")
                    }
                    .onDelete(perform: deletePlanExercises)
                    .onMove(perform: moveExercises)
                }

                Button {
                    isPresentingExercisePicker = true
                } label: {
                    Label("Übung hinzufügen", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Plan bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
        .onChange(of: plan.name) { _, _ in
            plan.updatedAt = .now
        }
        .sheet(isPresented: $isPresentingExercisePicker) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .sheet(item: $planExerciseToEdit) { planExercise in
            PlanExerciseEditView(planExercise: planExercise, activeGym: activeGym)
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let suggestion = PlanExerciseDefaults.suggest(for: exercise, from: allPlanExercises)
        let planExercise = PlanExercise(
            order: sortedExercises.count,
            targetSets: suggestion.sets,
            targetReps: suggestion.reps,
            targetWeight: suggestion.weight,
            plan: plan,
            exercise: exercise
        )
        modelContext.insert(planExercise)
        plan.updatedAt = .now
        try? modelContext.save()
    }

    private func deletePlanExercises(at offsets: IndexSet) {
        let items = sortedExercises
        for index in offsets {
            modelContext.delete(items[index])
        }
        PlanExerciseOrdering.reindex(sortedExercises)
        plan.updatedAt = .now
        try? modelContext.save()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var items = sortedExercises
        items.move(fromOffsets: source, toOffset: destination)
        PlanExerciseOrdering.reindex(items)
        plan.updatedAt = .now
        try? modelContext.save()
    }
}

private struct PlanExerciseRow: View {
    let planExercise: PlanExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(planExercise.exercise?.name ?? "Unbekannte Übung")
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        var parts = ["\(planExercise.targetSets)× \(planExercise.targetReps) Wdh."]
        if let weight = planExercise.targetWeight {
            parts.append("\(weight.formatted()) kg")
        }
        return parts.joined(separator: " · ")
    }
}
