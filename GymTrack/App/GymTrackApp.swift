import SwiftUI
import SwiftData

@main
struct GymTrackApp: App {
    let modelContainer: ModelContainer = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
