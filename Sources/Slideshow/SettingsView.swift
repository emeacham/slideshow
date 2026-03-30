// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI
import SlideshowCore

struct SettingsView: View {
    @ObservedObject var viewModel: SlideshowViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Slideshow Settings")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            Form {
                Section("Transition") {
                    Picker("Style", selection: $viewModel.controller.transitionType) {
                        ForEach(TransitionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Timing") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Slide Duration")
                            Spacer()
                            Text("\(viewModel.slideDelay, specifier: "%.1f") seconds")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: Binding(get: { viewModel.slideDelay }, set: { viewModel.slideDelay = $0 }),
                            in: 1...20,
                            step: 0.5
                        )
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                if let dir = viewModel.selectedDirectory {
                    Text(dir.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }
}
