import SwiftUI
import SwiftData

struct PlanListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(DeveloperModeStorage.key) private var isDeveloperModeActive = false
    @Query(sort: \TrainingPlan.updatedAt, order: .reverse) private var plans: [TrainingPlan]
    @Query private var exercises: [Exercise]

    @State private var navigationPath = NavigationPath()
    @State private var isPresentingTemplatePicker = false
    @State private var isPresentingImporter = false
    @State private var isPresentingImportError = false
    @State private var importErrorMessage = ""

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if plans.isEmpty {
                    ContentUnavailableView(
                        "Keine Pläne",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Erstelle deinen ersten Trainingsplan.")
                    )
                } else {
                    ForEach(plans) { plan in
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
        let plan = TrainingPlan(name: "Neuer Plan")
        modelContext.insert(plan)
        try? modelContext.save()
        navigationPath.append(plan)
    }

    private func createPlan(from template: PlanTemplate) {
        let result = PlanTemplateApplication.makePlan(from: template, availableExercises: exercises)
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
            let built = PlanExportImport.makePlan(from: export, availableExercises: exercises)
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
            Text("\(plan.exercises?.count ?? 0) Übungen")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
