import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TrainingTabView()
                .tabItem { Label("Training", systemImage: "dumbbell.fill") }

            PlanListView()
                .tabItem { Label("Pläne", systemImage: "list.bullet.rectangle") }

            StatisticsTabView()
                .tabItem { Label("Statistik", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
        }
    }
}

private struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    GymListView()
                } label: {
                    Label("Gyms", systemImage: "building.2")
                }
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    Label("Übungen", systemImage: "figure.strengthtraining.traditional")
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    ContentView()
}
