import SwiftUI
import SwiftData

@main
struct GymTrackApp: App {
    let modelContainer: ModelContainer = {
        let container: ModelContainer
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            container = PersistenceController.makeInMemoryContainer()
            // Unlike the in-memory model container, UserDefaults persists across separate
            // --uitesting launches on the same simulator — without this, developer mode
            // left active by one test would silently leak into the next.
            UserDefaults.standard.removeObject(forKey: DeveloperModeStorage.key)
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
