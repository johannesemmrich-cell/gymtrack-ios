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

            Text("Einstellungen")
                .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    ContentView()
}
