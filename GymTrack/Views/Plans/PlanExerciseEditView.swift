import SwiftUI
import SwiftData

struct PlanExerciseEditView: View {
    @Bindable var planExercise: PlanExercise
    let activeGym: Gym?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var equipmentNote: String = ""
    @State private var weightText: String = ""
    @State private var conversionFactorText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(planExercise.exercise?.name ?? "Übung") {
                    Stepper("Sätze: \(planExercise.targetSets)", value: $planExercise.targetSets, in: 1...20)
                    Stepper("Wiederholungen: \(planExercise.targetReps)", value: $planExercise.targetReps, in: 1...100)
                    HStack {
                        Text("Gewicht (kg)")
                        Spacer()
                        TextField("optional", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Zielgewicht")
                            .onChange(of: weightText) { _, newValue in
                                planExercise.targetWeight = WeightInput.parse(newValue)
                            }
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
                        HStack {
                            Text("Umrechnungsfaktor")
                            Spacer()
                            TextField("Gym-Standard", text: $conversionFactorText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .accessibilityLabel("Umrechnungsfaktor für diese Übung")
                        }
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
            .onAppear(perform: loadInitialState)
        }
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { planExercise.note ?? "" },
            set: { planExercise.note = $0.isEmpty ? nil : $0 }
        )
    }

    private func loadInitialState() {
        weightText = planExercise.targetWeight.map { String($0) } ?? ""
        guard let activeGym, let exercise = planExercise.exercise else { return }
        let note = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: activeGym, in: modelContext)
        equipmentNote = note.note
        conversionFactorText = note.conversionFactor.map { String($0) } ?? ""
    }

    private func save() {
        planExercise.updatedAt = .now
        if let activeGym, let exercise = planExercise.exercise {
            let note = ExerciseGymNoteStore.findOrCreate(exercise: exercise, gym: activeGym, in: modelContext)
            note.note = equipmentNote
            // A factor <= 0 is never meaningful — treat it the same as leaving the field empty
            // (clear the override, inherit the gym's global factor) rather than persisting it.
            note.conversionFactor = WeightInput.parse(conversionFactorText).flatMap { $0 > 0 ? $0 : nil }
            note.updatedAt = .now
        }
        try? modelContext.save()
        dismiss()
    }
}
