import Foundation
import SwiftData

@Model
final class FeedbackEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date.now
    var screenContext: String = ""
    var featureContext: String = ""
    var elementContext: String = ""
    var notes: String = ""
    var priorityRawValue: String = FeedbackPriority.medium.rawValue
    var isResolved: Bool = false

    var priority: FeedbackPriority {
        get { FeedbackPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        screenContext: String = "",
        featureContext: String = "",
        elementContext: String = "",
        notes: String = "",
        priority: FeedbackPriority = .medium,
        isResolved: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.screenContext = screenContext
        self.featureContext = featureContext
        self.elementContext = elementContext
        self.notes = notes
        self.priorityRawValue = priority.rawValue
        self.isResolved = isResolved
    }
}
