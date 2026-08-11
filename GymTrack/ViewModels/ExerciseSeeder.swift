import Foundation
import SwiftData

enum ExerciseSeeder {
    static let defaultExercises: [(name: String, muscleGroup: MuscleGroup)] = [
        ("Bankdrücken", .chest),
        ("Schrägbankdrücken", .chest),
        ("Kurzhantel-Bankdrücken", .chest),
        ("Fliegende", .chest),
        ("Dips", .chest),
        ("Klimmzüge", .back),
        ("Latzug", .back),
        ("Rudern vorgebeugt", .back),
        ("Kabelrudern sitzend", .back),
        ("Kreuzheben", .back),
        ("Schulterdrücken", .shoulders),
        ("Seitheben", .shoulders),
        ("Frontheben", .shoulders),
        ("Face Pulls", .shoulders),
        ("Bizepscurls", .biceps),
        ("Hammercurls", .biceps),
        ("Scottcurls", .biceps),
        ("Trizepsdrücken am Kabel", .triceps),
        ("Trizeps-Kickback", .triceps),
        ("Enges Bankdrücken", .triceps),
        ("Kniebeugen", .legs),
        ("Beinpresse", .legs),
        ("Ausfallschritte", .legs),
        ("Beinstrecker", .legs),
        ("Beinbeuger", .legs),
        ("Hüftstoßen", .glutes),
        ("Wadenheben", .calves),
        ("Crunches", .abs),
        ("Plank", .abs),
        ("Beinheben hängend", .abs),
        ("Unterarmcurls", .forearms),
        ("Laufband", .cardio),
        ("Rudergerät", .cardio),
        ("Burpees", .fullBody)
    ]

    /// Idempotent: only inserts default exercises whose name doesn't already exist.
    /// Never touches or removes exercises the user already has, custom or not.
    static func seedIfNeeded(context: ModelContext) {
        let existingNames = Set((try? context.fetch(FetchDescriptor<Exercise>()))?.map(\.name) ?? [])
        for entry in defaultExercises where !existingNames.contains(entry.name) {
            context.insert(Exercise(name: entry.name, muscleGroup: entry.muscleGroup, isCustom: false))
        }
        try? context.save()
    }
}
