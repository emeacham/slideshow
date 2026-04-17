// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import WebKit
import SwiftUI

// AVFoundation does not decode VP8/VP9, so WebM playback uses WKWebView's
// HTML5 video stack. The video autoplays immediately; onFinish fires via a
// JS message handler when the video reaches its natural end.
struct VideoPlayerView: NSViewRepresentable {
    let url: URL
    let onFinish: () -> Void

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var onFinish: () -> Void = {}
        var currentURL: URL?

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            onFinish()
        }
    }

    // WKUserContentController holds message handlers strongly, which would
    // create a retain cycle through the view hierarchy. A weak proxy breaks it.
    private final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
        weak var coordinator: Coordinator?
        init(_ coordinator: Coordinator) { self.coordinator = coordinator }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            coordinator?.userContentController(userContentController, didReceive: message)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(
            WeakMessageHandler(context.coordinator),
            name: "videoEnded"
        )
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.onFinish = onFinish
        guard context.coordinator.currentURL != url else { return }
        context.coordinator.currentURL = url

        let encodedName = url.lastPathComponent
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            ?? url.lastPathComponent

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
        video { width: 100%; height: 100%; object-fit: contain; display: block; }
        </style>
        </head>
        <body>
        <video autoplay playsinline
               onended="window.webkit.messageHandlers.videoEnded.postMessage('')">
          <source src="\(encodedName)" type="video/webm">
        </video>
        </body>
        </html>
        """

        // baseURL is the video's parent directory so the relative src resolves.
        nsView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
    }
}
