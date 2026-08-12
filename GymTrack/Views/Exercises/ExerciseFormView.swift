import SwiftUI

struct ExerciseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// Called with the newly created exercise right before this view dismisses itself —
    /// lets a caller (e.g. the plan editor's exercise picker) immediately select it.
    var onCreate: ((Exercise) -> Void)?

    @State private var name: String = ""
    @State private var muscleGroup: MuscleGroup = .other

    init(onCreate: ((Exercise) -> Void)? = nil) {
        self.onCreate = onCreate
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z. B. Kabelzug seitlich", text: $name)
                        .accessibilityLabel("Übungsname")
                }
                Section("Muskelgruppe") {
                    Picker("Muskelgruppe", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    .accessibilityLabel("Muskelgruppe")
                }
            }
            .navigationTitle("Neue Übung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(!isNameValid)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let exercise = Exercise(name: trimmedName, muscleGroup: muscleGroup, isCustom: true)
        modelContext.insert(exercise)
        try? modelContext.save()
        onCreate?(exercise)
        dismiss()
    }
}
