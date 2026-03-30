// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Slideshow")
                .font(.title.bold())

            Text("Version 1.0")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack(spacing: 6) {
                Text("Created by")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Ed Meacham")
                    .font(.headline)
                Link("edmeacham.com", destination: URL(string: "https://edmeacham.com")!)
                    .font(.callout)
            }

            Divider()

            Text("GNU General Public License v3")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Close") { dismiss() }
                .keyboardShortcut(.defaultAction)
                .padding(.top, 4)
        }
        .padding(32)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
    }
}
