// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import Foundation

@MainActor
final class DebugLog: ObservableObject {
    static let shared = DebugLog()

    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let category: String
        let message: String

        var formatted: String {
            let t = Self.formatter.string(from: timestamp)
            return "[\(t)] [\(category)] \(message)"
        }

        private static let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm:ss.SSS"
            return f
        }()
    }

    @Published private(set) var entries: [Entry] = []

    private init() {}

    func log(_ category: String, _ message: String) {
        let entry = Entry(timestamp: Date(), category: category, message: message)
        entries.append(entry)
        // Also print to stdout so it shows in Xcode console / terminal
        print(entry.formatted)
    }

    func clear() {
        entries.removeAll()
    }

    var text: String {
        entries.map(\.formatted).joined(separator: "\n")
    }
}
