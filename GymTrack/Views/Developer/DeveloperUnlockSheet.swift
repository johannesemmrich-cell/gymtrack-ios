import SwiftUI

struct DeveloperUnlockSheet: View {
    @Binding var isPresented: Bool
    @AppStorage(DeveloperModeStorage.key) private var isDeveloperModeActive = false

    @State private var password = ""
    @State private var error = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(isDeveloperModeActive
                         ? "Passwort eingeben, um den Entwicklermodus zu deaktivieren."
                         : "Passwort eingeben, um den Entwicklermodus zu aktivieren.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    SecureField("Passwort", text: $password)
                        .focused($focused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit(handleSubmit)
                }
                if !error.isEmpty {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Entwicklermodus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bestätigen", action: handleSubmit)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.fraction(0.4)])
    }

    private func handleSubmit() {
        guard DeveloperPasswordCheck.matches(password) else {
            error = "Falsches Passwort."
            password = ""
            return
        }
        isDeveloperModeActive.toggle()
        isPresented = false
    }
}
