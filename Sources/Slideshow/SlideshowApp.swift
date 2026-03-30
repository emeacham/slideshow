// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI

@main
struct SlideshowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 640, minHeight: 480)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Credits…") {
                    AppState.shared.showingCredits = true
                }
            }
        }
    }
}
