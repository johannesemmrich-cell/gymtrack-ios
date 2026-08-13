import Foundation

/// A bundled split template offered as a starting point when creating a new plan — matched
/// against the user's actual exercise library by name at application time (see
/// `PlanTemplateApplication`), never referencing `Exercise` objects directly.
struct PlanTemplate: Identifiable {
    struct ExerciseEntry {
        let exerciseName: String
        let targetSets: Int
        let targetReps: Int
    }

    let id: String
    let name: String
    let exercises: [ExerciseEntry]
}

enum PlanTemplateLibrary {
    static let all: [PlanTemplate] = [
        PlanTemplate(id: "push", name: "Push", exercises: [
            .init(exerciseName: "Bankdrücken", targetSets: 4, targetReps: 8),
            .init(exerciseName: "Schrägbankdrücken", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Schulterdrücken", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Trizepsdrücken am Kabel", targetSets: 3, targetReps: 12),
            .init(exerciseName: "Seitheben", targetSets: 3, targetReps: 12)
        ]),
        PlanTemplate(id: "pull", name: "Pull", exercises: [
            .init(exerciseName: "Klimmzüge", targetSets: 4, targetReps: 8),
            .init(exerciseName: "Latzug", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Rudern vorgebeugt", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Face Pulls", targetSets: 3, targetReps: 15),
            .init(exerciseName: "Bizepscurls", targetSets: 3, targetReps: 12)
        ]),
        PlanTemplate(id: "legs", name: "Legs", exercises: [
            .init(exerciseName: "Kniebeugen", targetSets: 4, targetReps: 8),
            .init(exerciseName: "Beinpresse", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Beinstrecker", targetSets: 3, targetReps: 12),
            .init(exerciseName: "Beinbeuger", targetSets: 3, targetReps: 12),
            .init(exerciseName: "Wadenheben", targetSets: 4, targetReps: 15)
        ]),
        PlanTemplate(id: "fullBody", name: "Ganzkörper", exercises: [
            .init(exerciseName: "Kniebeugen", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Bankdrücken", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Rudern vorgebeugt", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Schulterdrücken", targetSets: 3, targetReps: 10),
            .init(exerciseName: "Crunches", targetSets: 3, targetReps: 15)
        ])
    ]
}
