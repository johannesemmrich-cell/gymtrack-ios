import SwiftUI

struct GymFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let gymToEdit: Gym?

    @State private var name: String
    @State private var note: String

    init(gymToEdit: Gym? = nil) {
        self.gymToEdit = gymToEdit
        _name = State(initialValue: gymToEdit?.name ?? "")
        _note = State(initialValue: gymToEdit?.note ?? "")
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

        if let gym = gymToEdit {
            gym.name = trimmedName
            gym.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            let gym = Gym(name: trimmedName, note: trimmedNote.isEmpty ? nil : trimmedNote)
            modelContext.insert(gym)
        }
        try? modelContext.save()
        dismiss()
    }
}
