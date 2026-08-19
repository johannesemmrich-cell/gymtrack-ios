import SwiftUI
import SwiftData

struct PlanEditorView: View {
    @Bindable var plan: TrainingPlan

    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query private var allPlanExercises: [PlanExercise]
    @Query(filter: #Predicate<Gym> { $0.isActive }) private var activeGyms: [Gym]
    @Query(sort: \Gym.name) private var gyms: [Gym]

    @State private var isPresentingExercisePicker = false
    @State private var planExerciseToEdit: PlanExercise?
    @State private var isGroupingMode = false
    @State private var selectedForGrouping: Set<UUID> = []

    private var sortedExercises: [PlanExercise] {
        (plan.exercises ?? []).sorted { $0.order < $1.order }
    }

    private var activeGym: Gym? { activeGyms.first }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Planname", text: $plan.name)
                    .accessibilityLabel("Planname")
            }

            if !gyms.isEmpty {
                Section("Gym") {
                    Picker("Gym", selection: $plan.gym) {
                        Text("Kein bestimmtes Gym").tag(Gym?.none)
                        ForEach(gyms) { gym in
                            Text(gym.name).tag(Gym?.some(gym))
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("Gym")
                    .accessibilityLabel("Gym")
                }
            }

            Section("Übungen") {
                if sortedExercises.isEmpty {
                    ContentUnavailableView(
                        "Keine Übungen",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Füge Übungen zu diesem Plan hinzu.")
                    )
                } else {
                    ForEach(sortedExercises) { planExercise in
                        Button {
                            if isGroupingMode {
                                toggleSelection(planExercise)
                            } else {
                                planExerciseToEdit = planExercise
                            }
                        } label: {
                            PlanExerciseRow(
                                planExercise: planExercise,
                                partnerNames: SupersetGrouping.partnerNames(of: planExercise, in: sortedExercises),
                                isGroupingMode: isGroupingMode,
                                isSelectedForGrouping: selectedForGrouping.contains(planExercise.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(planExercise.exercise?.name ?? "")
                        .swipeActions(edge: .trailing) {
                            if planExercise.supersetGroupID != nil {
                                Button("Superset auflösen") {
                                    SupersetGrouping.leave(planExercise, from: sortedExercises)
                                    plan.updatedAt = .now
                                    try? modelContext.save()
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .onDelete(perform: deletePlanExercises)
                    .onMove(perform: moveExercises)
                }

                Button {
                    isPresentingExercisePicker = true
                } label: {
                    Label("Übung hinzufügen", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Plan bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // Disabled while grouping — the two modes both drive the same row taps
                // (reorder/delete vs. select-for-grouping) and being able to enter both at
                // once would make it ambiguous which one a row tap responds to, plus both
                // buttons would confusingly read "Fertig" simultaneously.
                EditButton()
                    .disabled(isGroupingMode)
            }
            // Deliberately on .topBarLeading, not sharing .primaryAction with EditButton and
            // not on .bottomBar. Sharing .primaryAction previously pushed this button into a
            // toolbar-overflow state on some simulator widths (accessibility tree reported it
            // as existing, but XCUITest's synthesized tap resolved to an invalid {-1, -1} hit
            // point). .bottomBar was tried next but, inside this tab-hosted NavigationStack, it
            // visually overlapped the TabView's own tab bar closely enough that a synthesized
            // tap on "Gruppieren" actually landed on the "Statistik" tab button underneath it
            // (confirmed via a diagnostic dump that caught the app having navigated to the
            // Statistik tab after "tapping" Gruppieren). The leading side of the nav bar has
            // no such neighbor. Always present (not conditionally inserted) — SwiftUI is slow/
            // unreliable to materialize a ToolbarItem that only appears once a condition
            // becomes true; disabling it instead keeps the toolbar structure stable from the
            // first render.
            ToolbarItem(placement: .topBarLeading) {
                Button(isGroupingMode ? "Fertig" : "Gruppieren") {
                    if isGroupingMode {
                        commitGrouping()
                    }
                    isGroupingMode.toggle()
                }
                .disabled(
                    (!isGroupingMode && sortedExercises.count < 2)
                    || editMode?.wrappedValue.isEditing == true
                )
            }
        }
        .onChange(of: plan.name) { _, _ in
            plan.updatedAt = .now
        }
        // @Model's synthesized Equatable/Hashable compares by persistentModelID, so this can't
        // spuriously refire from the updatedAt write itself — same reasoning as the onChange
        // above, just on the gym relationship instead of the name.
        .onChange(of: plan.gym) { _, _ in
            plan.updatedAt = .now
        }
        .sheet(isPresented: $isPresentingExercisePicker) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .sheet(item: $planExerciseToEdit) { planExercise in
            PlanExerciseEditView(planExercise: planExercise, activeGym: activeGym)
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let suggestion = PlanExerciseDefaults.suggest(for: exercise, from: allPlanExercises)
        let planExercise = PlanExercise(
            order: sortedExercises.count,
            targetSets: suggestion.sets,
            targetReps: suggestion.reps,
            targetWeight: suggestion.weight,
            plan: plan,
            exercise: exercise
        )
        modelContext.insert(planExercise)
        plan.updatedAt = .now
        try? modelContext.save()
    }

    private func deletePlanExercises(at offsets: IndexSet) {
        let items = sortedExercises
        for index in offsets {
            // Leave the superset group before deleting — otherwise a deleted exercise's
            // former partner keeps a supersetGroupID shared with nobody (or with too few
            // remaining partners to still count as a superset), leaving its "Superset
            // auflösen" swipe action showing with nothing left to dissolve.
            SupersetGrouping.leave(items[index], from: items)
            modelContext.delete(items[index])
        }
        PlanExerciseOrdering.reindex(sortedExercises)
        plan.updatedAt = .now
        try? modelContext.save()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var items = sortedExercises
        items.move(fromOffsets: source, toOffset: destination)
        PlanExerciseOrdering.reindex(items)
        plan.updatedAt = .now
        try? modelContext.save()
    }

    private func toggleSelection(_ planExercise: PlanExercise) {
        if selectedForGrouping.contains(planExercise.id) {
            selectedForGrouping.remove(planExercise.id)
        } else {
            selectedForGrouping.insert(planExercise.id)
        }
    }

    private func commitGrouping() {
        let selected = sortedExercises.filter { selectedForGrouping.contains($0.id) }
        SupersetGrouping.group(selected, allPlanExercises: sortedExercises)
        selectedForGrouping.removeAll()
        plan.updatedAt = .now
        try? modelContext.save()
    }
}

private struct PlanExerciseRow: View {
    let planExercise: PlanExercise
    let partnerNames: [String]
    let isGroupingMode: Bool
    let isSelectedForGrouping: Bool

    var body: some View {
        HStack {
            if isGroupingMode {
                Image(systemName: isSelectedForGrouping ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelectedForGrouping ? Color.accentColor : Color.secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(planExercise.exercise?.name ?? "Unbekannte Übung")
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !partnerNames.isEmpty {
                    Text("🔗 Superset mit \(partnerNames.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isGroupingMode && isSelectedForGrouping ? .isSelected : [])
    }

    private var summary: String {
        let setsLabel = planExercise.isUnilateral
            ? "\(planExercise.targetSets)× \(planExercise.targetReps) Wdh. pro Seite"
            : "\(planExercise.targetSets)× \(planExercise.targetReps) Wdh."
        var parts = [setsLabel]
        if let weight = planExercise.targetWeight {
            parts.append("\(weight.formatted()) kg")
        }
        return parts.joined(separator: " · ")
    }
}
