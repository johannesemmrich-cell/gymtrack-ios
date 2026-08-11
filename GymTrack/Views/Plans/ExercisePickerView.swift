import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    let onSelect: (Exercise) -> Void

    private var groupedExercises: [(group: MuscleGroup, items: [Exercise])] {
        ExerciseSearch.grouped(exercises: exercises, query: searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises, id: \.group) { entry in
                    Section(entry.group.displayName) {
                        ForEach(entry.items) { exercise in
                            ExercisePickerRow(exercise: exercise, onSelect: onSelect, dismiss: dismiss)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Übung suchen")
            .navigationTitle("Übung auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

private struct ExercisePickerRow: View {
    let exercise: Exercise
    let onSelect: (Exercise) -> Void
    let dismiss: DismissAction

    var body: some View {
        Button {
            onSelect(exercise)
            dismiss()
        } label: {
            Text(exercise.name)
                .foregroundStyle(.primary)
        }
        .accessibilityIdentifier(exercise.name)
    }
}
