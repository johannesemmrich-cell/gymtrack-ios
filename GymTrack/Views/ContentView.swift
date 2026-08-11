import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Workouts")
                .tabItem { Label("Training", systemImage: "dumbbell.fill") }

            Text("Pläne")
                .tabItem { Label("Pläne", systemImage: "list.bullet.rectangle") }

            Text("Statistiken")
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
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    ContentView()
}
