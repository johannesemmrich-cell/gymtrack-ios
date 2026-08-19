import Foundation
import CryptoKit

/// Checks the developer-mode password against a hardcoded SHA-256 hash — the password
/// itself never appears in source or storage.
enum DeveloperPasswordCheck {
    private static let passwordHash = "5187f60ecb928fbbdfd417d75bda193f441dce05a2309f7494770a584f59e27e"

    static func matches(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let digest = SHA256.hash(data: Data(trimmed.utf8))
        let hex = digest.compactMap { String(format: "%02x", $0) }.joined()
        return hex == passwordHash
    }
}
