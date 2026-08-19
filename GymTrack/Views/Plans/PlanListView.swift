import SwiftUI
import SwiftData

struct PlanListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(DeveloperModeStorage.key) private var isDeveloperModeActive = false
    @Query(sort: \TrainingPlan.updatedAt, order: .reverse) private var plans: [TrainingPlan]
    @Query(sort: \Gym.name) private var gyms: [Gym]
    @Query private var exercises: [Exercise]

    @State private var navigationPath = NavigationPath()
    @State private var isPresentingTemplatePicker = false
    @State private var isPresentingImporter = false
    @State private var isPresentingImportError = false
    @State private var importErrorMessage = ""
    // nil means "Alle" — both as an explicit user choice and as the not-yet-initialized
    // starting state; the .task below resolves the ambiguity once, on first appearance only.
    @State private var selectedGymID: UUID?
    @State private var hasInitializedGymFilter = false

    private var filteredPlans: [TrainingPlan] {
        PlanGymFiltering.filter(plans, byGymID: selectedGymID)
    }

    /// Looked up by id on every access rather than held directly, so a gym deleted elsewhere
    /// while selected here simply stops resolving instead of leaving a dangling reference
    /// around — same convention as `StatisticsTabView.selectedExercise`.
    private var selectedGym: Gym? {
        guard let selectedGymID else { return nil }
        return gyms.first { $0.id == selectedGymID }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if plans.isEmpty {
                    ContentUnavailableView(
                        "Keine Pläne",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Erstelle deinen ersten Trainingsplan.")
                    )
                } else if filteredPlans.isEmpty {
                    ContentUnavailableView(
                        "Keine Pläne für dieses Gym",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Wähle „Alle“ oder erstelle einen neuen Plan für dieses Gym.")
                    )
                } else {
                    ForEach(filteredPlans) { plan in
                        NavigationLink(value: plan) {
                            PlanRow(plan: plan)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Löschen", role: .destructive) {
                                modelContext.delete(plan)
                                try? modelContext.save()
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Duplizieren") {
                                duplicate(plan)
                            }
                            .tint(.blue)
                            if let exportURL = try? PlanExportImport.writeTempFile(for: plan) {
                                ShareLink(item: exportURL) {
                                    Label("Exportieren", systemImage: "square.and.arrow.up")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pläne")
            .developerFeedbackOverlay(isActive: isDeveloperModeActive, screen: "Pläne", feature: "Plan-Liste")
            .toolbar {
                // Always present (not conditionally inserted) even with zero gyms — disabling
                // instead keeps the toolbar structure stable from the first render. See the
                // identical reasoning on PlanEditorView's "Gruppieren" button.
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Gym", selection: $selectedGymID) {
                        Text("Alle").tag(UUID?.none)
                        ForEach(gyms) { gym in
                            Text(gym.name).tag(UUID?.some(gym.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(gyms.isEmpty)
                    .accessibilityIdentifier("Gym-Filter")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createPlan()
                    } label: {
                        Label("Plan hinzufügen", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingTemplatePicker = true
                    } label: {
                        Label("Aus Vorlage erstellen", systemImage: "square.stack")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingImporter = true
                    } label: {
                        Label("Plan importieren", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .task {
                guard !hasInitializedGymFilter else { return }
                hasInitializedGymFilter = true
                selectedGymID = gyms.first(where: \.isActive)?.id
            }
            .onChange(of: selectedGymID) { _, newValue in
                // "Alle" (nil) is a pure display filter and must never touch which gym is
                // active; picking an actual gym here is the whole point of this switcher, so
                // it activates it exactly like tapping it in Einstellungen → Gyms would.
                // Already-active is skipped so the .task-driven initial selection below (which
                // just mirrors the existing active gym) doesn't cause a redundant save on every
                // first appearance of this tab.
                guard let newValue, let gym = gyms.first(where: { $0.id == newValue }), !gym.isActive else { return }
                GymActivation.activate(gym, among: gyms)
                try? modelContext.save()
            }
            .onChange(of: gyms) { _, newGyms in
                // The selected gym may have just been deleted (e.g. in Einstellungen → Gyms).
                // Deleting the *active* gym there auto-promotes a replacement (GymActivation.
                // promoteReplacement) — follow that promotion rather than blindly falling back
                // to "Alle", so this filter doesn't silently diverge from the gym actually used
                // for weight suggestions/logging elsewhere. Falls back to nil only if no gym is
                // active anymore either (e.g. the last gym was just deleted).
                guard let selectedGymID, !newGyms.contains(where: { $0.id == selectedGymID }) else { return }
                self.selectedGymID = newGyms.first(where: \.isActive)?.id
            }
            .navigationDestination(for: TrainingPlan.self) { plan in
                PlanEditorView(plan: plan)
            }
            .sheet(isPresented: $isPresentingTemplatePicker) {
                PlanTemplatePickerView { template in
                    createPlan(from: template)
                }
            }
            .fileImporter(isPresented: $isPresentingImporter, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
            .alert("Import fehlgeschlagen", isPresented: $isPresentingImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage)
            }
        }
    }

    private func createPlan() {
        let plan = TrainingPlan(name: "Neuer Plan", gym: selectedGym)
        modelContext.insert(plan)
        try? modelContext.save()
        navigationPath.append(plan)
    }

    private func createPlan(from template: PlanTemplate) {
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: exercises)
        result.plan.gym = selectedGym
        modelContext.insert(result.plan)
        for planExercise in result.planExercises {
            modelContext.insert(planExercise)
        }
        try? modelContext.save()
        navigationPath.append(result.plan)
    }

    private func duplicate(_ plan: TrainingPlan) {
        let result = TrainingPlanDuplication.duplicate(plan)
        modelContext.insert(result.plan)
        for planExercise in result.planExercises {
            modelContext.insert(planExercise)
        }
        try? modelContext.save()
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else {
            presentImportError()
            return
        }

        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let export = try PlanExportImport.decode(data)
            let built = PlanExportImport.makePlan(from: export, availableExercises: exercises, availableGyms: gyms)
            modelContext.insert(built.plan)
            for planExercise in built.planExercises {
                modelContext.insert(planExercise)
            }
            try modelContext.save()
            navigationPath.append(built.plan)
        } catch {
            presentImportError()
        }
    }

    private func presentImportError() {
        importErrorMessage = "Die Datei ist beschädigt oder kein gültiger Plan-Export."
        isPresentingImportError = true
    }
}

private struct PlanRow: View {
    let plan: TrainingPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(plan.name)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        let exerciseCount = "\(plan.exercises?.count ?? 0) Übungen"
        guard let gymName = plan.gym?.name else { return exerciseCount }
        return "\(exerciseCount) · \(gymName)"
    }
}
