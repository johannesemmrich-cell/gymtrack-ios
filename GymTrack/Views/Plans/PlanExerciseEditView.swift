import SwiftUI
import SwiftData

struct PlanExerciseEditView: View {
    @Bindable var planExercise: PlanExercise
    let activeGym: Gym?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var equipmentNote: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(planExercise.exercise?.name ?? "Übung") {
                    Stepper("Sätze: \(planExercise.targetSets)", value: $planExercise.targetSets, in: 1...20)
                    Stepper("Wiederholungen: \(planExercise.targetReps)", value: $planExercise.targetReps, in: 1...100)
                    HStack {
                        Text("Gewicht (kg)")
                        Spacer()
                        TextField("optional", text: weightBinding)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Zielgewicht")
                    }
                }

                Section("Notiz für diesen Plan") {
                    TextField("z. B. Flachbank statt Schrägbank", text: noteBinding, axis: .vertical)
                        .accessibilityLabel("Plan-Notiz")
                }

                if let activeGym {
                    Section("Ausrüstung in \(activeGym.name)") {
                        TextField("z. B. Sitz Stufe 4", text: $equipmentNote, axis: .vertical)
                            .accessibilityLabel("Ausrüstungs-Notiz")
                    }
                } else {
                    Section("Ausrüstung") {
                        Text("Kein aktives Gym ausgewählt.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Übung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { save() }
                }
            }
            .onAppear(perform: loadEquipmentNote)
        }
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { planExercise.note ?? "" },
            set: { planExercise.note = $0.isEmpty ? nil : $0 }
        )
    }

    private var weightBinding: Binding<String> {
        Binding(
            get: { planExercise.targetWeight.map { String($0) } ?? "" },
            set: { planExercise.targetWeight = Double($0.replacingOccurrences(of: ",", with: ".")) }
        )
    }

    private func loadEquipmentNote() {
        guard let activeGym, let exercise = planExercise.exercise else { return }
        let note = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: activeGym, in: modelContext)
        equipmentNote = note.note
    }

    private func save() {
        planExercise.updatedAt = .now
        if let activeGym, let exercise = planExercise.exercise {
            let note = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: activeGym, in: modelContext)
            note.note = equipmentNote
            note.updatedAt = .now
        }
        try? modelContext.save()
        dismiss()
    }
}
