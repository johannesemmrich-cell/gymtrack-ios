import SwiftUI
import SwiftData

struct PlanListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingPlan.updatedAt, order: .reverse) private var plans: [TrainingPlan]
    @Query private var exercises: [Exercise]

    @State private var navigationPath = NavigationPath()
    @State private var isPresentingTemplatePicker = false

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
                        }
                    }
                }
            }
            .navigationTitle("Pläne")
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
            }
            .navigationDestination(for: TrainingPlan.self) { plan in
                PlanEditorView(plan: plan)
            }
            .sheet(isPresented: $isPresentingTemplatePicker) {
                PlanTemplatePickerView { template in
                    createPlan(from: template)
                }
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
