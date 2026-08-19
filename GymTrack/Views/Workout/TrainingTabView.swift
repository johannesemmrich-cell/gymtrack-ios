import SwiftUI
import SwiftData

struct TrainingTabView: View {
    @AppStorage(DeveloperModeStorage.key) private var isDeveloperModeActive = false
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }) private var activeSessions: [WorkoutSession]
    @Query(sort: \TrainingPlan.updatedAt, order: .reverse) private var plans: [TrainingPlan]
    @Query(filter: #Predicate<Gym> { $0.isActive }) private var activeGyms: [Gym]
    @Query private var allSetEntries: [SetEntry]
    @Query private var allSessions: [WorkoutSession]

    @State private var navigationPath = NavigationPath()

    private var activeSession: WorkoutSession? { activeSessions.first }
    private var activeGym: Gym? { activeGyms.first }

    private var lastRepeatableSession: WorkoutSession? {
        SessionStatistics.eligibleSessions(allSessions).max { $0.startedAt < $1.startedAt }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            if let activeSession {
                WorkoutSessionView(session: activeSession)
                    .developerFeedbackOverlay(isActive: isDeveloperModeActive, screen: "Training", feature: "Aktives Workout")
            } else {
                List {
                    if let lastRepeatableSession {
                        Section("Wiederholen") {
                            NavigationLink(value: lastRepeatableSession) {
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
                                NavigationLink(value: plan) {
                                    Text(plan.name)
                                }
                                .accessibilityIdentifier(plan.name)
                            }
                        }
                    }
                }
                .navigationTitle("Training")
                .developerFeedbackOverlay(isActive: isDeveloperModeActive, screen: "Training", feature: "Plan-Auswahl")
                .navigationDestination(for: TrainingPlan.self) { plan in
                    PlanStartView(
                        source: .plan(plan),
                        gym: activeGym,
                        setHistory: allSetEntries,
                        onStarted: { _ in navigationPath = NavigationPath() }
                    )
                }
                .navigationDestination(for: WorkoutSession.self) { session in
                    PlanStartView(
                        source: .repeatSession(session),
                        gym: activeGym,
                        setHistory: allSetEntries,
                        onStarted: { _ in navigationPath = NavigationPath() }
                    )
                }
            }
        }
    }

    private func repeatSubtitle(for session: WorkoutSession) -> String {
        "Training vom \(session.startedAt.formatted(date: .abbreviated, time: .omitted))"
    }
}
