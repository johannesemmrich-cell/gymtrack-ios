import SwiftUI
import SwiftData

@main
struct GymTrackApp: App {
    let modelContainer: ModelContainer = {
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            return PersistenceController.makeInMemoryContainer()
        }
        return PersistenceController.makeContainer()
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
