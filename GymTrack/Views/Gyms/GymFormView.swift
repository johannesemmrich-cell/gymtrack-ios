import SwiftUI

struct GymFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let gymToEdit: Gym?

    @State private var name: String
    @State private var note: String
    @State private var conversionFactorText: String

    init(gymToEdit: Gym? = nil) {
        self.gymToEdit = gymToEdit
        _name = State(initialValue: gymToEdit?.name ?? "")
        _note = State(initialValue: gymToEdit?.note ?? "")
        _conversionFactorText = State(initialValue: Self.formatted(gymToEdit?.weightConversionFactor ?? 1.0))
    }

    private static func formatted(_ factor: Double) -> String {
        factor == 1.0 ? "1" : String(factor)
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z. B. Frankfurt", text: $name)
                        .accessibilityLabel("Gym-Name")
                }
                Section("Notiz (optional)") {
                    TextField("z. B. Zugangscode 1234", text: $note, axis: .vertical)
                        .accessibilityLabel("Gym-Notiz")
                }
                Section {
                    HStack {
                        Text("Umrechnungsfaktor")
                        Spacer()
                        TextField("1", text: $conversionFactorText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Umrechnungsfaktor")
                    }
                } footer: {
                    Text("Nur nötig, wenn Geräte hier anders kalibriert sind als in deinen anderen Gyms – 1 bedeutet keine Umrechnung.")
                }
            }
            .navigationTitle(gymToEdit == nil ? "Neues Gym" : "Gym bearbeiten")
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
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedFactor = WeightInput.parse(conversionFactorText) ?? 1.0
        let conversionFactor = parsedFactor > 0 ? parsedFactor : 1.0

        if let gym = gymToEdit {
            gym.name = trimmedName
            gym.note = trimmedNote.isEmpty ? nil : trimmedNote
            gym.weightConversionFactor = conversionFactor
        } else {
            let gym = Gym(
                name: trimmedName,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                weightConversionFactor: conversionFactor
            )
            modelContext.insert(gym)
        }
        try? modelContext.save()
        dismiss()
    }
}
