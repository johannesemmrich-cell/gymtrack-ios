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
    @AppStorage(DeveloperModeStorage.key) private var isDeveloperModeActive = false
    @State private var versionTapCount = 0
    @State private var showDeveloperUnlock = false

    var body: some View {
        NavigationStack {
            List {
                Section {
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

                if isDeveloperModeActive {
                    Section {
                        NavigationLink {
                            DeveloperModeView()
                        } label: {
                            Label("Entwicklermodus", systemImage: "hammer.fill")
                        }
                    }
                }

                Section {
                    Button(action: handleVersionTap) {
                        HStack {
                            Spacer()
                            Text("GymTrack \(appVersion) (\(buildNumber))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if isDeveloperModeActive {
                                Text("DEV")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.red))
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("AppVersion")
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Einstellungen")
            .developerFeedbackOverlay(isActive: isDeveloperModeActive, screen: "Einstellungen", feature: "Einstellungen-Tab")
            .sheet(isPresented: $showDeveloperUnlock) {
                DeveloperUnlockSheet(isPresented: $showDeveloperUnlock)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }

    private func handleVersionTap() {
        versionTapCount += 1
        if versionTapCount >= 5 {
            versionTapCount = 0
            showDeveloperUnlock = true
        }
    }
}

#Preview {
    ContentView()
}
