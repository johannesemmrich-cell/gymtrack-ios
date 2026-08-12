import SwiftUI
import SwiftData

struct GymListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Gym.name) private var gyms: [Gym]

    @State private var isPresentingAddSheet = false
    @State private var gymToEdit: Gym?

    var body: some View {
        List {
            if gyms.isEmpty {
                ContentUnavailableView(
                    "Keine Gyms",
                    systemImage: "building.2",
                    description: Text("Füge dein erstes Gym hinzu, um Gewichte pro Gym zu verfolgen.")
                )
            } else {
                ForEach(gyms) { gym in
                    Button {
                        GymActivation.activate(gym, among: gyms)
                        try? modelContext.save()
                    } label: {
                        GymRow(gym: gym)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(gym.name)
                    .swipeActions(edge: .trailing) {
                        Button("Löschen", role: .destructive) {
                            let remaining = gyms.filter { $0.id != gym.id }
                            GymActivation.promoteReplacement(afterDeleting: gym, remaining: remaining)
                            modelContext.delete(gym)
                            try? modelContext.save()
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button("Bearbeiten") {
                            gymToEdit = gym
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("Gyms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddSheet = true
                } label: {
                    Label("Gym hinzufügen", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            GymFormView()
        }
        .sheet(item: $gymToEdit) { gym in
            GymFormView(gymToEdit: gym)
        }
    }
}

private struct GymRow: View {
    let gym: Gym

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(gym.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                if let note = gym.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if gym.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(gym.isActive ? [.isSelected] : [])
        .accessibilityHint(gym.isActive ? "Aktives Gym" : "Antippen, um dieses Gym zu aktivieren")
    }
}
