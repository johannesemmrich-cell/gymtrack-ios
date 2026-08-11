import SwiftUI

struct SetEditView: View {
    @Bindable var set: SetEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var equipmentNote: String = ""
    @State private var weightText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(set.exercise?.name ?? "Satz") {
                    Stepper("Wiederholungen: \(set.reps)", value: $set.reps, in: 0...100)
                    HStack {
                        Text("Gewicht (kg)")
                        Spacer()
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Satz-Gewicht")
                            .onChange(of: weightText) { _, newValue in
                                set.weight = WeightInput.parse(newValue) ?? 0
                            }
                    }
                    Toggle("Erledigt", isOn: $set.isCompleted)
                        .accessibilityLabel("Satz erledigt")
                }

                Section("Notiz") {
                    TextField("z. B. Griff eng", text: noteBinding, axis: .vertical)
                        .accessibilityLabel("Satz-Notiz")
                }

                if let gym = set.gym {
                    Section("Ausrüstung in \(gym.name)") {
                        TextField("z. B. Sitz Stufe 4", text: $equipmentNote, axis: .vertical)
                            .accessibilityLabel("Ausrüstungs-Notiz")
                    }
                }
            }
            .navigationTitle("Satz bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { save() }
                }
            }
            .onAppear(perform: loadInitialState)
        }
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { set.note ?? "" },
            set: { set.note = $0.isEmpty ? nil : $0 }
        )
    }

    private func loadInitialState() {
        weightText = set.weight == 0 ? "" : String(set.weight)
        guard let gym = set.gym, let exercise = set.exercise else { return }
        let note = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: gym, in: modelContext)
        equipmentNote = note.note
    }

    private func save() {
        if let gym = set.gym, let exercise = set.exercise {
            let note = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: gym, in: modelContext)
            note.note = equipmentNote
            note.updatedAt = .now
        }
        try? modelContext.save()
        dismiss()
    }
}
