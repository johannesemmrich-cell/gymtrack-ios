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
        ExerciseSearch.grouped(exercises: exercises, query: searchText)
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
                            // Value-less NavigationLink deliberately, not NavigationLink(value:)
                            // + .navigationDestination(for:) — that pairing never fired a single
                            // push here in practice (confirmed via screen recordings across
                            // several otherwise-plausible fixes), regardless of which view owned
                            // the .navigationDestination. This screen is itself reached via a
                            // value-less NavigationLink from SettingsView; this form is the one
                            // proven to work for a further push from there.
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseRow(exercise: exercise)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Löschen", role: .destructive) {
                                    delete(exercise)
                                }
                            }
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

    private func delete(_ exercise: Exercise) {
        modelContext.delete(exercise)
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
    }
}
