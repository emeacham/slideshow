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

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var onFinish: () -> Void = {}
        var currentURL: URL?

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? String else { return }
            switch message.name {
            case "videoEnded":
                DebugLog.shared.log("VIDEO", "ended event fired")
                onFinish()
            case "videoError":
                DebugLog.shared.log("VIDEO-ERR", body)
            case "jsLog":
                DebugLog.shared.log("JS", body)
            default:
                break
            }
        }

        // WKNavigationDelegate — catch load failures
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DebugLog.shared.log("WK-NAV", "didFail: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DebugLog.shared.log("WK-NAV", "provisionalFail: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DebugLog.shared.log("WK-NAV", "didFinish load")
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

        let proxy = WeakMessageHandler(context.coordinator)
        config.userContentController.add(proxy, name: "videoEnded")
        config.userContentController.add(proxy, name: "videoError")
        config.userContentController.add(proxy, name: "jsLog")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.onFinish = onFinish
        guard context.coordinator.currentURL != url else { return }
        context.coordinator.currentURL = url

        let log = DebugLog.shared

        // Log file metadata
        let path = url.path
        let fm = FileManager.default
        let exists = fm.fileExists(atPath: path)
        let readable = fm.isReadableFile(atPath: path)
        log.log("FILE", "path: \(path)")
        log.log("FILE", "exists: \(exists), readable: \(readable)")

        if let attrs = try? fm.attributesOfItem(atPath: path) {
            let size = (attrs[.size] as? Int64) ?? 0
            let type = (attrs[.type] as? FileAttributeType)?.rawValue ?? "unknown"
            log.log("FILE", "size: \(size) bytes, type: \(type)")
        }

        let baseURL = url.deletingLastPathComponent()
        log.log("WK-LOAD", "baseURL: \(baseURL.path)")

        let encodedName = url.lastPathComponent
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            ?? url.lastPathComponent
        log.log("WK-LOAD", "src filename (encoded): \(encodedName)")

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
        <video id="v" autoplay playsinline>
          <source src="\(encodedName)" type="video/webm">
        </video>
        <script>
        var v = document.getElementById('v');

        function post(name, msg) {
            window.webkit.messageHandlers[name].postMessage(msg);
        }

        v.addEventListener('ended', function() { post('videoEnded', 'ended'); });

        v.addEventListener('error', function(e) {
            var src = v.currentSrc || '(none)';
            var code = v.error ? v.error.code : '?';
            var msg = v.error ? v.error.message : '(no message)';
            post('videoError', 'MediaError code=' + code + ' msg=' + msg + ' src=' + src);
        });

        v.addEventListener('loadstart', function() { post('jsLog', 'loadstart'); });
        v.addEventListener('loadedmetadata', function() {
            post('jsLog', 'loadedmetadata dur=' + v.duration + ' w=' + v.videoWidth + ' h=' + v.videoHeight);
        });
        v.addEventListener('canplay', function() { post('jsLog', 'canplay'); });
        v.addEventListener('playing', function() { post('jsLog', 'playing'); });
        v.addEventListener('stalled', function() { post('jsLog', 'stalled'); });
        v.addEventListener('waiting', function() { post('jsLog', 'waiting'); });
        v.addEventListener('suspend', function() { post('jsLog', 'suspend'); });

        // Also capture <source> element errors
        var src = v.querySelector('source');
        if (src) {
            src.addEventListener('error', function(e) {
                post('videoError', 'source-error: failed to load ' + src.src);
            });
        }

        post('jsLog', 'script init, currentSrc=' + (v.currentSrc || '(empty)') + ' networkState=' + v.networkState + ' readyState=' + v.readyState);
        </script>
        </body>
        </html>
        """

        nsView.loadHTMLString(html, baseURL: baseURL)
    }
}
