import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var isPresentingAddSheet = false

    private var filteredExercises: [Exercise] {
        ExerciseSearch.filter(exercises: exercises, query: searchText)
    }

    private var groupedExercises: [(group: MuscleGroup, items: [Exercise])] {
        let groups = Dictionary(grouping: filteredExercises, by: \.muscleGroup)
        return MuscleGroup.allCases.compactMap { group in
            guard let items = groups[group], !items.isEmpty else { return nil }
            return (group, items.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        List {
            if exercises.isEmpty {
                ContentUnavailableView(
                    "Keine Übungen",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Füge eine eigene Übung hinzu.")
                )
            } else if filteredExercises.isEmpty {
                ContentUnavailableView(
                    "Keine Treffer",
                    systemImage: "magnifyingglass",
                    description: Text("Keine Übung gefunden für \"\(searchText)\".")
                )
            } else {
                ForEach(groupedExercises, id: \.group) { entry in
                    Section(entry.group.displayName) {
                        ForEach(entry.items) { exercise in
                            ExerciseRow(exercise: exercise)
                        }
                        .onDelete { offsets in
                            delete(items: entry.items, at: offsets)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Übung suchen")
        .navigationTitle("Übungen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddSheet = true
                } label: {
                    Label("Übung hinzufügen", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            ExerciseFormView()
        }
    }

    private func delete(items: [Exercise], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack {
            Text(exercise.name)
            Spacer()
            if exercise.isCustom {
                Text("Eigene")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(exercise.name)
    }
}
