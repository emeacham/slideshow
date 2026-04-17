// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import AVKit
import SwiftUI

// Wraps AVPlayerView so WebM (and future video formats) play natively.
// The view always starts playback immediately; onFinish is called when
// the video reaches its end so the slideshow can auto-advance.
struct VideoPlayerView: NSViewRepresentable {
    let url: URL
    let onFinish: () -> Void

    final class Coordinator: NSObject {
        var player: AVPlayer?
        var endObserver: NSObjectProtocol?
        // Updated each render pass so the closure always has current state.
        var onFinish: () -> Void = {}

        deinit {
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onFinish = onFinish

        // Reuse the existing player when the URL hasn't changed.
        let currentURL = (coordinator.player?.currentItem?.asset as? AVURLAsset)?.url
        guard currentURL != url else { return }

        // Tear down the old player.
        if let obs = coordinator.endObserver {
            NotificationCenter.default.removeObserver(obs)
            coordinator.endObserver = nil
        }
        coordinator.player?.pause()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = false
        coordinator.player = player
        nsView.player = player

        coordinator.endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak coordinator] _ in
            coordinator?.onFinish()
        }

        player.play()
    }
}
