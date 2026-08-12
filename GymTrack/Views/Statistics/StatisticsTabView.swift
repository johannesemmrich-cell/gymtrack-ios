import SwiftUI
import SwiftData

struct StatisticsTabView: View {
    @Query private var sessions: [WorkoutSession]

    private var averageDuration: TimeInterval? {
        SessionStatistics.averageDuration(sessions)
    }

    private var averagePerWeek: Double? {
        SessionStatistics.averageSessionsPerWeek(sessions)
    }

    private var mostFrequentExercises: [ExerciseFrequency.Entry] {
        Array(ExerciseFrequency.mostFrequentExercises(from: sessions).prefix(5))
    }

    var body: some View {
        NavigationStack {
            List {
                if averageDuration == nil {
                    ContentUnavailableView(
                        "Noch keine Statistik",
                        systemImage: "chart.bar",
                        description: Text("Schließe dein erstes Training ab, um hier Statistiken zu sehen.")
                    )
                } else {
                    Section("Übersicht") {
                        StatRow(title: "Ø Trainingsdauer", value: formattedDuration)
                        StatRow(title: "Ø Trainings / Woche", value: formattedFrequency)
                    }
                    Section("Häufigste Übungen") {
                        ForEach(mostFrequentExercises, id: \.exercise.id) { entry in
                            StatRow(
                                title: entry.exercise.name,
                                value: "\(entry.sessionCount)×"
                            )
                        }
                    }
                }
            }
            .navigationTitle("Statistik")
        }
    }

    private var formattedDuration: String {
        guard let averageDuration else { return "–" }
        let minutes = Int((averageDuration / 60).rounded())
        return "\(minutes) Min"
    }

    private var formattedFrequency: String {
        guard let averagePerWeek else { return "–" }
        return averagePerWeek.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
