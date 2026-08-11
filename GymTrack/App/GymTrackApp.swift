import SwiftUI
import SwiftData

@main
struct GymTrackApp: App {
    let modelContainer: ModelContainer = {
        let container: ModelContainer
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            container = PersistenceController.makeInMemoryContainer()
        } else {
            container = PersistenceController.makeContainer()
        }
        ExerciseSeeder.seedIfNeeded(context: ModelContext(container))
        return container
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
