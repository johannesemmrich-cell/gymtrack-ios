import SwiftUI

struct DeveloperFeedbackButton: View {
    let screen: String
    let feature: String
    let element: String

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: "hand.thumbsdown.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(6)
                .background(Circle().fill(Color.red.opacity(0.75)))
        }
        .accessibilityLabel("Feedback geben")
        .sheet(isPresented: $showSheet) {
            FeedbackSubmitSheet(screen: screen, feature: feature, element: element)
        }
    }
}

struct FeedbackSubmitSheet: View {
    let screen: String
    let feature: String
    let element: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var notes = ""
    @State private var priority: FeedbackPriority = .medium
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Kontext") {
                    LabeledContent("Screen", value: screen)
                    LabeledContent("Feature", value: feature)
                    if !element.isEmpty {
                        LabeledContent("Element", value: element)
                    }
                }

                Section("Notiz") {
                    TextEditor(text: $notes)
                        .focused($focused)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Feedback-Notiz")
                }

                Section("Priorität") {
                    Picker("Priorität", selection: $priority) {
                        ForEach(FeedbackPriority.allCases, id: \.self) { p in
                            Text("\(p.emoji) \(p.label)").tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Feedback senden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern", action: save)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { focused = true }
        }
    }

    private func save() {
        let entry = FeedbackEntry(
            screenContext: screen,
            featureContext: feature,
            elementContext: element,
            notes: notes,
            priority: priority
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

private struct DeveloperFeedbackOverlay: ViewModifier {
    let isActive: Bool
    let screen: String
    let feature: String
    let element: String

    func body(content: Content) -> some View {
        if isActive {
            content.overlay(alignment: .topTrailing) {
                DeveloperFeedbackButton(screen: screen, feature: feature, element: element)
                    .padding(6)
            }
        } else {
            content
        }
    }
}

extension View {
    /// Overlays a thumbs-down feedback button top-trailing on `self`, but only while
    /// developer mode is active — the button always reports where it was tapped from via
    /// `screen`/`feature`/`element`, so feedback triaging doesn't need extra digging.
    func developerFeedbackOverlay(isActive: Bool, screen: String, feature: String, element: String = "") -> some View {
        modifier(DeveloperFeedbackOverlay(isActive: isActive, screen: screen, feature: feature, element: element))
    }
}
