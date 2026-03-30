// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import Foundation

// Shared state accessible from both SwiftUI views and .commands{} closures,
// which don't participate in the SwiftUI environment.
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    @Published var showingCredits = false
    private init() {}
}
