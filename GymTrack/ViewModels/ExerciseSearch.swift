import Foundation

enum ExerciseSearch {
    static func filter(exercises: [Exercise], query: String) -> [Exercise] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return exercises }
        return exercises.filter {
            $0.name.range(of: trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    /// Filters then groups by muscle group, in `MuscleGroup.allCases` declaration order,
    /// omitting empty groups, with each group's exercises sorted by name.
    static func grouped(exercises: [Exercise], query: String) -> [(group: MuscleGroup, items: [Exercise])] {
        let filtered = filter(exercises: exercises, query: query)
        let groups = Dictionary(grouping: filtered, by: \.muscleGroup)
        return MuscleGroup.allCases.compactMap { group in
            guard let items = groups[group], !items.isEmpty else { return nil }
            return (group, items.sorted { $0.name < $1.name })
        }
    }
}
