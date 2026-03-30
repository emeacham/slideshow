// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import AppKit
import SwiftUI

// Wraps NSImageView so animated GIFs play natively (NSImageView.animates = true
// loops all frames automatically). A Coordinator cancels any in-flight load
// when the URL changes, preventing stale images from appearing.
struct AsyncImageView: NSViewRepresentable {
    let url: URL

    final class Coordinator {
        var currentTask: Task<Void, Never>?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.animates = true
        view.imageScaling = .scaleProportionallyUpOrDown
        view.imageAlignment = .alignCenter
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        context.coordinator.currentTask?.cancel()
        nsView.image = nil

        let localURL = url
        context.coordinator.currentTask = Task {
            let data = await Task.detached(priority: .userInitiated) {
                try? Data(contentsOf: localURL)
            }.value

            guard !Task.isCancelled, let data else { return }
            let image = NSImage(data: data)

            await MainActor.run {
                guard !Task.isCancelled else { return }
                nsView.image = image
                nsView.animates = true
            }
        }
    }
}
