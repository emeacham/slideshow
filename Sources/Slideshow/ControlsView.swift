// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI
import AppKit

struct ControlsView: View {
    @ObservedObject var viewModel: SlideshowViewModel
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 0) {
            counterLabel
                .frame(minWidth: 70, alignment: .leading)

            Spacer()

            transportControls

            Spacer()

            HStack(spacing: 4) {
                settingsButton
                fullscreenButton
            }
            .frame(minWidth: 70, alignment: .trailing)
        }
    }

    private var counterLabel: some View {
        Text(viewModel.hasImages ? "\(viewModel.currentIndex + 1) / \(viewModel.totalCount)" : "")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.8))
    }

    private var transportControls: some View {
        HStack(spacing: 20) {
            controlButton(systemImage: "backward.fill", size: .title3, action: viewModel.previous)
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(!viewModel.hasImages)

            controlButton(
                systemImage: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill",
                size: .title,
                action: viewModel.togglePlayPause
            )
            .keyboardShortcut(.space, modifiers: [])
            .disabled(!viewModel.hasImages)

            controlButton(systemImage: "forward.fill", size: .title3, action: viewModel.next)
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(!viewModel.hasImages)
        }
    }

    private var settingsButton: some View {
        controlButton(systemImage: "gearshape", size: .body) { showSettings = true }
            .keyboardShortcut(",", modifiers: .command)
    }

    private var fullscreenButton: some View {
        controlButton(systemImage: "arrow.up.left.and.arrow.down.right", size: .body) {
            NSApplication.shared.keyWindow?.toggleFullScreen(nil)
        }
        .keyboardShortcut("f", modifiers: [])
    }

    private func controlButton(systemImage: String, size: Font, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(size)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 2)
                .contentShape(Rectangle())
                .padding(8)
        }
        .buttonStyle(.plain)
    }
}
