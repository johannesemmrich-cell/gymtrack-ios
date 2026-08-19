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
        let isUnilateral: Bool
        let note: String?

        enum CodingKeys: String, CodingKey {
            case exerciseName, order, targetSets, targetReps, targetWeight, isUnilateral, note
        }

        init(
            exerciseName: String,
            order: Int,
            targetSets: Int,
            targetReps: Int,
            targetWeight: Double?,
            isUnilateral: Bool,
            note: String?
        ) {
            self.exerciseName = exerciseName
            self.order = order
            self.targetSets = targetSets
            self.targetReps = targetReps
            self.targetWeight = targetWeight
            self.isUnilateral = isUnilateral
            self.note = note
        }

        /// Custom decoding so a file exported before unilateral support existed (no
        /// `isUnilateral` key at all) still imports cleanly as bilateral, instead of the
        /// whole file failing to decode.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            exerciseName = try container.decode(String.self, forKey: .exerciseName)
            order = try container.decode(Int.self, forKey: .order)
            targetSets = try container.decode(Int.self, forKey: .targetSets)
            targetReps = try container.decode(Int.self, forKey: .targetReps)
            targetWeight = try container.decodeIfPresent(Double.self, forKey: .targetWeight)
            isUnilateral = try container.decodeIfPresent(Bool.self, forKey: .isUnilateral) ?? false
            note = try container.decodeIfPresent(String.self, forKey: .note)
        }
    }

    let name: String
    let note: String?
    /// Name of the gym this plan is for, if any — matched by name on import, same convention
    /// as `ExerciseEntry.exerciseName`. A plain optional stored property is enough for
    /// backward compatibility here (unlike `ExerciseEntry.isUnilateral`): Swift's synthesized
    /// Codable already decodes a missing key as nil for Optional properties, no custom decoder
    /// needed.
    let gymName: String?
    let exercises: [ExerciseEntry]

    init(name: String, note: String?, gymName: String? = nil, exercises: [ExerciseEntry]) {
        self.name = name
        self.note = note
        self.gymName = gymName
        self.exercises = exercises
    }
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
                isUnilateral: planExercise.isUnilateral,
                note: planExercise.note
            )
        }
        return PlanExport(name: plan.name, note: plan.note, gymName: plan.gym?.name, exercises: entries)
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
    static func makePlan(
        from export: PlanExport,
        availableExercises: [Exercise],
        availableGyms: [Gym] = []
    ) -> (plan: TrainingPlan, planExercises: [PlanExercise]) {
        let exercisesByName = Dictionary(availableExercises.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        // Unlike exercises, a gym with no name match is not an error — the plan is still fully
        // usable, just without a gym assignment (same as any plan that never had one).
        let gym = export.gymName.flatMap { name in availableGyms.first { $0.name == name } }
        let plan = TrainingPlan(name: export.name, note: export.note, gym: gym)

        var planExercises: [PlanExercise] = []
        for entry in export.exercises.sorted(by: { $0.order < $1.order }) {
            guard let exercise = exercisesByName[entry.exerciseName] else { continue }
            planExercises.append(PlanExercise(
                order: planExercises.count,
                targetSets: entry.targetSets,
                targetReps: entry.targetReps,
                targetWeight: entry.targetWeight,
                isUnilateral: entry.isUnilateral,
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
