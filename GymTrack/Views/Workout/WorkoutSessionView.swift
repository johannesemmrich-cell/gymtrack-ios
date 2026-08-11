import SwiftUI

struct WorkoutSessionView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext

    @State private var setToEdit: SetEntry?

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

    var body: some View {
        List {
            ForEach(groupedSets, id: \.exercise.id) { entry in
                Section(entry.exercise.name) {
                    ForEach(entry.items) { set in
                        Button {
                            setToEdit = set
                        } label: {
                            SetRow(set: set)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        delete(sets: entry.items, at: offsets)
                    }

                    Button {
                        addSet(for: entry.exercise, basedOn: entry.items.last)
                    } label: {
                        Label("Satz hinzufügen", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle(session.planName ?? "Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Beenden") { endWorkout() }
            }
        }
        .sheet(item: $setToEdit) { set in
            SetEditView(set: set)
        }
    }

    private func addSet(for exercise: Exercise, basedOn lastSet: SetEntry?) {
        let nextOrder = ((session.sets ?? []).map(\.order).max() ?? -1) + 1
        let newSet = SetEntry(
            order: nextOrder,
            setType: .normal,
            reps: lastSet?.reps ?? 10,
            weight: lastSet?.weight ?? 0,
            exercise: exercise,
            gym: session.gym,
            session: session
        )
        modelContext.insert(newSet)
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
            Text("\(set.weight.formatted()) kg × \(set.reps)")
            Spacer()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
