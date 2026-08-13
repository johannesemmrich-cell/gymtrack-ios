import SwiftUI
import SwiftData

struct TrainingTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }) private var activeSessions: [WorkoutSession]
    @Query(sort: \TrainingPlan.updatedAt, order: .reverse) private var plans: [TrainingPlan]
    @Query(filter: #Predicate<Gym> { $0.isActive }) private var activeGyms: [Gym]
    @Query private var allSetEntries: [SetEntry]
    @Query private var allSessions: [WorkoutSession]

    private var activeSession: WorkoutSession? { activeSessions.first }
    private var activeGym: Gym? { activeGyms.first }

    private var lastRepeatableSession: WorkoutSession? {
        SessionStatistics.eligibleSessions(allSessions).max { $0.startedAt < $1.startedAt }
    }

    var body: some View {
        NavigationStack {
            if let activeSession {
                WorkoutSessionView(session: activeSession)
            } else {
                List {
                    if let lastRepeatableSession {
                        Section("Wiederholen") {
                            Button {
                                startWorkout(repeating: lastRepeatableSession)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Letztes Training wiederholen")
                                    Text(lastRepeatableSession.planName ?? repeatSubtitle(for: lastRepeatableSession))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityIdentifier("Letztes Training wiederholen")
                        }
                    }

                    if plans.isEmpty && lastRepeatableSession == nil {
                        ContentUnavailableView(
                            "Keine Pläne",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Erstelle zuerst einen Plan im Pläne-Tab.")
                        )
                    } else if !plans.isEmpty {
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

    private func startWorkout(repeating session: WorkoutSession) {
        let result = WorkoutRepetition.build(repeating: session, gym: activeGym)
        modelContext.insert(result.session)
        for set in result.sets {
            modelContext.insert(set)
        }
        try? modelContext.save()
    }

    private func repeatSubtitle(for session: WorkoutSession) -> String {
        "Training vom \(session.startedAt.formatted(date: .abbreviated, time: .omitted))"
    }
}
