import AppKit

/// Monitors the system clipboard for changes, persists history, and provides re-copy.
final class ClipboardManager {

    // MARK: - Constants

    static let shared = ClipboardManager()
    private let maxItems = 25
    private let userDefaultsKey = "clipboardHistory"
    private let pollInterval: TimeInterval = 0.5

    // MARK: - State

    private(set) var items: [ClipboardItem] = []
    private var lastChangeCount: Int
    private var timer: Timer?

    /// Called whenever the items array changes. The menu controller hooks into this.
    var onUpdate: (() -> Void)?

    // MARK: - Init

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        loadItems()
    }

    // MARK: - Polling

    /// Start monitoring the clipboard.
    func startMonitoring() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        // Make sure the timer fires even when menus are open
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    /// Stop monitoring the clipboard.
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard let copiedString = pasteboard.string(forType: .string),
              !copiedString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Deduplicate: skip if it matches the most recent item
        if let mostRecent = items.first, mostRecent.text == copiedString {
            return
        }

        // Remove any older duplicate of the same text (move it to top instead)
        items.removeAll { $0.text == copiedString }

        let newItem = ClipboardItem(text: copiedString)
        items.insert(newItem, at: 0)

        // Cap at max items
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        saveItems()
        onUpdate?()
    }

    // MARK: - Re-copy

    /// Copy a history item back onto the system clipboard.
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        // Update changeCount so we don't re-detect our own paste
        lastChangeCount = pasteboard.changeCount
    }

    // MARK: - Clear

    /// Clear all clipboard history.
    func clearAll() {
        items.removeAll()
        saveItems()
        onUpdate?()
    }

    // MARK: - Persistence

    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Popy: Failed to save clipboard history: \(error)")
        }
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Popy: Failed to load clipboard history: \(error)")
            items = []
        }
    }
}
