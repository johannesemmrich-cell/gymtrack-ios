import Foundation

enum ExerciseSearch {
    static func filter(exercises: [Exercise], query: String) -> [Exercise] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return exercises }
        return exercises.filter {
            $0.name.range(of: trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}
