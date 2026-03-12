import Foundation

/// A single clipboard history entry.
struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let timestamp: Date

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
    }

    /// Returns the text truncated to `maxLength` characters with ellipsis if needed.
    /// Newlines are collapsed to spaces and whitespace is trimmed before truncation.
    func truncatedText(maxLength: Int = 25) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= maxLength {
            return cleaned
        }
        return String(cleaned.prefix(maxLength)) + "..."
    }

    // MARK: - Formatting

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// Returns a human-readable relative timestamp like "2m ago", "1h ago".
    func relativeTimestamp() -> String {
        return Self.relativeFormatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
