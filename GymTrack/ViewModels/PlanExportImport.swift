import Foundation

/// Codable snapshot of a plan for JSON export/import. Exercises are referenced by name only
/// (never by id), since a plan exported from one device/install has no meaningful shared
/// identity for `Exercise` rows on another — matching by name is the same approach already
/// used by `PlanTemplateApplication` for bundled templates.
struct PlanExport: Codable {
    struct ExerciseEntry: Codable {
        let exerciseName: String
        let order: Int
        let targetSets: Int
        let targetReps: Int
        let targetWeight: Double?
        let note: String?
    }

    let name: String
    let note: String?
    let exercises: [ExerciseEntry]
}

enum PlanImportError: Error, Equatable {
    case corruptedFile
}

enum PlanExportImport {
    static func export(_ plan: TrainingPlan) -> PlanExport {
        let sortedExercises = (plan.exercises ?? []).sorted { $0.order < $1.order }
        let entries = sortedExercises.compactMap { planExercise -> PlanExport.ExerciseEntry? in
            guard let exercise = planExercise.exercise else { return nil }
            return PlanExport.ExerciseEntry(
                exerciseName: exercise.name,
                order: planExercise.order,
                targetSets: planExercise.targetSets,
                targetReps: planExercise.targetReps,
                targetWeight: planExercise.targetWeight,
                note: planExercise.note
            )
        }
        return PlanExport(name: plan.name, note: plan.note, exercises: entries)
    }

    static func encode(_ export: PlanExport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    /// Wraps every decode failure (malformed JSON, wrong shape, wrong type) as one
    /// user-facing `.corruptedFile` case rather than exposing raw `DecodingError` variants.
    static func decode(_ data: Data) throws -> PlanExport {
        do {
            return try JSONDecoder().decode(PlanExport.self, from: data)
        } catch {
            throw PlanImportError.corruptedFile
        }
    }

    /// Matches each export entry to an existing `Exercise` by name. Entries with no match
    /// (exercise renamed/deleted since the file was exported) are skipped rather than
    /// crashing or creating a duplicate exercise — same convention as `PlanTemplateApplication`.
    static func makePlan(from export: PlanExport, availableExercises: [Exercise]) -> (plan: TrainingPlan, planExercises: [PlanExercise]) {
        let exercisesByName = Dictionary(availableExercises.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        let plan = TrainingPlan(name: export.name, note: export.note)

        var planExercises: [PlanExercise] = []
        for entry in export.exercises.sorted(by: { $0.order < $1.order }) {
            guard let exercise = exercisesByName[entry.exerciseName] else { continue }
            planExercises.append(PlanExercise(
                order: planExercises.count,
                targetSets: entry.targetSets,
                targetReps: entry.targetReps,
                targetWeight: entry.targetWeight,
                note: entry.note,
                plan: plan,
                exercise: exercise
            ))
        }

        return (plan, planExercises)
    }

    /// Writes the plan's export JSON to a temp file so it can be handed to `ShareLink` as a
    /// named `.json` file. Side-effecting (disk I/O), unlike the rest of this enum.
    static func writeTempFile(for plan: TrainingPlan) throws -> URL {
        let data = try encode(export(plan))
        let trimmedName = plan.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = (trimmedName.isEmpty ? "Plan" : trimmedName).replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeName).json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
