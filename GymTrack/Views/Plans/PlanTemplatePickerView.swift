import SwiftUI

struct PlanTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (PlanTemplate) -> Void

    var body: some View {
        NavigationStack {
            List(PlanTemplateLibrary.all) { template in
                Button {
                    onSelect(template)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .foregroundStyle(.primary)
                        Text("\(template.exercises.count) Übungen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier(template.name)
            }
            .navigationTitle("Vorlage wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
