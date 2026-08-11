import SwiftUI
import SwiftData

struct TrainingTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }) private var activeSessions: [WorkoutSession]
    @Query(sort: \TrainingPlan.updatedAt, order: .reverse) private var plans: [TrainingPlan]
    @Query(filter: #Predicate<Gym> { $0.isActive }) private var activeGyms: [Gym]
    @Query private var allSetEntries: [SetEntry]

    private var activeSession: WorkoutSession? { activeSessions.first }
    private var activeGym: Gym? { activeGyms.first }

    var body: some View {
        NavigationStack {
            if let activeSession {
                WorkoutSessionView(session: activeSession)
            } else {
                List {
                    if plans.isEmpty {
                        ContentUnavailableView(
                            "Keine Pläne",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Erstelle zuerst einen Plan im Pläne-Tab.")
                        )
                    } else {
                        Section("Plan starten") {
                            ForEach(plans) { plan in
                                Button {
                                    startWorkout(from: plan)
                                } label: {
                                    Text(plan.name)
                                }
                                .accessibilityIdentifier(plan.name)
                            }
                        }
                    }
                }
                .navigationTitle("Training")
            }
        }
    }

    private func startWorkout(from plan: TrainingPlan) {
        let result = WorkoutSessionBuilder.build(from: plan, gym: activeGym, setHistory: allSetEntries)
        modelContext.insert(result.session)
        for set in result.sets {
            modelContext.insert(set)
        }
        try? modelContext.save()
    }
}
