import SwiftUI
import SwiftData
import UIKit

struct DeveloperModeView: View {
    @AppStorage(DeveloperModeStorage.key) private var isDeveloperModeActive = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeedbackEntry.timestamp, order: .reverse) private var feedbackEntries: [FeedbackEntry]
    @Query(sort: \DevTodoItem.createdAt, order: .forward) private var todoItems: [DevTodoItem]

    @State private var showAddTodo = false
    @State private var showExitConfirm = false
    @State private var priorityFilter: FeedbackPriority?
    @State private var showOnlyOpen = true
    // Mirrors InProgressStore (raw UserDefaults, not observed by SwiftUI) in view state, so
    // toggling "Testen"/"Pause" actually re-renders which section a row belongs to instead of
    // only updating that row's own local appearance until some unrelated state change forces
    // the whole list to re-evaluate.
    @State private var inProgressIDs: Set<UUID> = InProgressStore.allIDs()

    private var filteredFeedback: [FeedbackEntry] {
        FeedbackFiltering.filter(feedbackEntries, priority: priorityFilter, onlyOpen: showOnlyOpen)
    }

    private var openTodoItems: [DevTodoItem] {
        todoItems.filter { !inProgressIDs.contains($0.id) && !$0.isCompleted }
    }

    private var inProgressTodoItems: [DevTodoItem] {
        todoItems.filter { inProgressIDs.contains($0.id) && !$0.isCompleted }
    }

    private var doneTodoItems: [DevTodoItem] {
        todoItems.filter(\.isCompleted)
    }

    var body: some View {
        List {
            Section {
                Label("Entwicklermodus aktiv", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            }

            if !inProgressTodoItems.isEmpty {
                Section {
                    ForEach(inProgressTodoItems) { item in
                        DevTodoRow(item: item, inProgressIDs: $inProgressIDs)
                    }
                } header: {
                    Label("In Arbeit", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.orange)
                }
            }

            Section("To-Do (\(openTodoItems.count))") {
                if todoItems.isEmpty {
                    Text("Noch keine Einträge.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if openTodoItems.isEmpty {
                    Text("Alles in Arbeit oder erledigt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(openTodoItems) { item in
                    DevTodoRow(item: item, inProgressIDs: $inProgressIDs)
                }
                .onDelete { offsets in
                    delete(items: openTodoItems, at: offsets)
                }
                Button {
                    showAddTodo = true
                } label: {
                    Label("Neues To-Do", systemImage: "plus.circle")
                }
            }

            if !doneTodoItems.isEmpty {
                Section("Erledigt (\(doneTodoItems.count))") {
                    ForEach(doneTodoItems) { item in
                        DevTodoRow(item: item, inProgressIDs: $inProgressIDs)
                    }
                    .onDelete { offsets in
                        delete(items: doneTodoItems, at: offsets)
                    }
                }
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FeedbackFilterChip(label: "Alle", color: .secondary, isSelected: priorityFilter == nil) {
                            priorityFilter = nil
                        }
                        ForEach(FeedbackPriority.allCases, id: \.self) { p in
                            FeedbackFilterChip(
                                label: "\(p.emoji) \(p.label)",
                                color: p.chipColor,
                                isSelected: priorityFilter == p
                            ) {
                                priorityFilter = (priorityFilter == p) ? nil : p
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Picker("Status", selection: $showOnlyOpen) {
                    Text("Offen (\(feedbackEntries.filter { !$0.isResolved }.count))").tag(true)
                    Text("Erledigt (\(feedbackEntries.filter(\.isResolved).count))").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Feedback (\(filteredFeedback.count))") {
                if filteredFeedback.isEmpty {
                    Text(feedbackEntries.isEmpty
                         ? "Noch kein Feedback. Tippe im Entwicklermodus auf 👎."
                         : "Kein Feedback für diesen Filter.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredFeedback) { entry in
                        HStack(spacing: 12) {
                            Button {
                                entry.isResolved.toggle()
                                try? modelContext.save()
                            } label: {
                                Image(systemName: entry.isResolved ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(entry.isResolved ? .green : .secondary)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(entry.isResolved ? "Als offen markieren" : "Als erledigt markieren")

                            NavigationLink {
                                FeedbackEntryDetailView(entry: entry)
                            } label: {
                                FeedbackEntryRow(entry: entry)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(filteredFeedback[index])
                        }
                        try? modelContext.save()
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showExitConfirm = true
                } label: {
                    Label("Entwicklermodus beenden", systemImage: "xmark.shield")
                }
            } footer: {
                Text("Feedback, To-Dos und alle anderen Daten bleiben erhalten.")
                    .font(.caption)
            }
        }
        .navigationTitle("Entwicklermodus")
        .listStyle(.insetGrouped)
        .toolbar {
            if !feedbackEntries.isEmpty || !todoItems.isEmpty {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
        .sheet(isPresented: $showAddTodo) {
            AddDevTodoSheet(isPresented: $showAddTodo)
        }
        .confirmationDialog(
            "Entwicklermodus beenden?",
            isPresented: $showExitConfirm,
            titleVisibility: .visible
        ) {
            Button("Beenden", role: .destructive) { isDeveloperModeActive = false }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle Feedback-Einträge, To-Dos und Einstellungen bleiben erhalten.")
        }
    }

    private func delete(items: [DevTodoItem], at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            inProgressIDs.remove(item.id)
            InProgressStore.setInProgress(item.id, false)
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

private extension FeedbackPriority {
    var chipColor: Color {
        switch self {
        // A plain `.red` (shared with `.high`) wouldn't visually outrank it, but a fixed dark
        // RGB literal fails contrast in Dark Mode (system colors like `.red` brighten there,
        // a hardcoded literal can't) — a dynamic UIColor keeps "more severe than high" in both.
        case .urgent:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1)
                    : UIColor(red: 0.6, green: 0, blue: 0, alpha: 1)
            })
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        case .testing: return .purple
        }
    }
}

private struct FeedbackFilterChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.15) : Color(.secondarySystemFill))
                        .overlay(Capsule().strokeBorder(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1))
                )
                .foregroundStyle(isSelected ? color : .secondary)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.18), value: isSelected)
    }
}

private struct DevTodoRow: View {
    @Bindable var item: DevTodoItem
    @Binding var inProgressIDs: Set<UUID>
    @Environment(\.modelContext) private var modelContext

    private var inProgress: Bool { inProgressIDs.contains(item.id) }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if item.isCompleted {
                    item.isCompleted = false
                } else {
                    item.isCompleted = true
                    inProgressIDs.remove(item.id)
                    InProgressStore.setInProgress(item.id, false)
                }
                try? modelContext.save()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : (inProgress ? "arrow.triangle.2.circlepath.circle.fill" : "circle"))
                    .foregroundStyle(item.isCompleted ? .green : (inProgress ? .orange : .secondary))
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "Als offen markieren" : "Als erledigt markieren")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                if inProgress && !item.isCompleted {
                    Text("In Arbeit")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            if !item.isCompleted {
                Button {
                    if inProgress {
                        inProgressIDs.remove(item.id)
                        InProgressStore.setInProgress(item.id, false)
                    } else {
                        inProgressIDs.insert(item.id)
                        InProgressStore.setInProgress(item.id, true)
                    }
                } label: {
                    Text(inProgress ? "Pause" : "Testen")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(inProgress ? Color.orange.opacity(0.15) : Color.blue.opacity(0.12))
                        )
                        .foregroundStyle(inProgress ? .orange : .blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct AddDevTodoSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Aufgabe") {
                    TextField("Titel", text: $title)
                        .focused($focused)
                }
            }
            .navigationTitle("Neues To-Do")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hinzufügen") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        modelContext.insert(DevTodoItem(title: trimmed))
                        try? modelContext.save()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.fraction(0.35)])
    }
}

private struct FeedbackEntryRow: View {
    let entry: FeedbackEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.screenContext)
                    .font(.caption.weight(.semibold))
                Text("›")
                    .foregroundStyle(.secondary)
                Text(entry.featureContext)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.priority.emoji)
            }
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(entry.timestamp, format: .dateTime.day().month().hour().minute())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

private struct FeedbackEntryDetailView: View {
    @Bindable var entry: FeedbackEntry

    var body: some View {
        Form {
            Section("Kontext") {
                LabeledContent("Screen", value: entry.screenContext)
                LabeledContent("Feature", value: entry.featureContext)
                if !entry.elementContext.isEmpty {
                    LabeledContent("Element", value: entry.elementContext)
                }
                LabeledContent("Zeit", value: entry.timestamp.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Notiz") {
                TextEditor(text: $entry.notes)
                    .frame(minHeight: 80)
            }

            Section("Priorität") {
                Picker("Priorität", selection: $entry.priority) {
                    ForEach(FeedbackPriority.allCases, id: \.self) { p in
                        Text("\(p.emoji) \(p.label)").tag(p)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle("Erledigt", isOn: $entry.isResolved)
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
}
