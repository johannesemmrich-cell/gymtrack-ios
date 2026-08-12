import SwiftUI
import SwiftData
import Charts

struct StatisticsTabView: View {
    @Query private var sessions: [WorkoutSession]
    @State private var selectedExerciseID: UUID?

    private var averageDuration: TimeInterval? {
        SessionStatistics.averageDuration(sessions)
    }

    private var averagePerWeek: Double? {
        SessionStatistics.averageSessionsPerWeek(sessions)
    }

    private var mostFrequentExercises: [ExerciseFrequency.Entry] {
        Array(ExerciseFrequency.mostFrequentExercises(from: sessions).prefix(5))
    }

    private var exercisesWithVolumeHistory: [Exercise] {
        TrainingVolume.exercisesWithVolumeHistory(sessions: sessions)
    }

    /// Looks the selection up by id on every access rather than holding the `Exercise` itself in
    /// `@State`, so a deleted exercise's id simply stops resolving instead of leaving a dangling
    /// SwiftData model reference around (e.g. after switching tabs post-deletion).
    private var selectedExercise: Exercise? {
        guard let selectedExerciseID else { return nil }
        return exercisesWithVolumeHistory.first { $0.id == selectedExerciseID }
    }

    private var volumeDataPoints: [TrainingVolume.DataPoint] {
        TrainingVolume.dataPoints(sessions: sessions, exercise: selectedExercise)
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
                    if !volumeDataPoints.isEmpty || selectedExerciseID != nil {
                        Section("Trainingsvolumen") {
                            if !exercisesWithVolumeHistory.isEmpty {
                                Picker("Übung", selection: $selectedExerciseID) {
                                    Text("Gesamt").tag(UUID?.none)
                                    ForEach(exercisesWithVolumeHistory, id: \.id) { exercise in
                                        Text(exercise.name).tag(UUID?.some(exercise.id))
                                    }
                                }
                            }
                            if volumeDataPoints.isEmpty {
                                Text("Für diese Auswahl noch keine Daten.")
                                    .foregroundStyle(.secondary)
                            } else {
                                VolumeChart(dataPoints: volumeDataPoints)
                                    .frame(height: 180)
                                    .padding(.vertical, 4)
                            }
                        }
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

private struct VolumeChart: View {
    let dataPoints: [TrainingVolume.DataPoint]

    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Datum", point.date),
                y: .value("Volumen", point.volume)
            )
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(.tint)
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("Datum", point.date),
                y: .value("Volumen", point.volume)
            )
            .foregroundStyle(.tint)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .accessibilityLabel("Trainingsvolumen über Zeit")
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        guard let first = dataPoints.first, let last = dataPoints.last else { return "" }
        let firstValue = Int(first.volume.rounded())
        let lastValue = Int(last.volume.rounded())
        let unit = dataPoints.count == 1 ? "Trainingseinheit" : "Trainingseinheiten"
        return "Von \(firstValue) auf \(lastValue) Kilogramm über \(dataPoints.count) \(unit)."
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
