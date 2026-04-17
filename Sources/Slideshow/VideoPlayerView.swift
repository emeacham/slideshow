// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import WebKit
import SwiftUI

// AVFoundation does not decode VP8/VP9, so WebM playback uses WKWebView's
// HTML5 video stack. The video autoplays immediately; onFinish fires via a
// JS message handler when the video reaches its natural end.
//
// loadHTMLString cannot access file:// URLs (sandbox restriction), so we
// write a small HTML file next to the video and use loadFileURL with
// allowingReadAccessTo: pointing at the parent directory.
struct VideoPlayerView: NSViewRepresentable {
    let url: URL
    let onFinish: () -> Void

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var onFinish: () -> Void = {}
        var currentURL: URL?
        var tempHTMLURL: URL?

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

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DebugLog.shared.log("WK-NAV", "didFail: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DebugLog.shared.log("WK-NAV", "provisionalFail: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DebugLog.shared.log("WK-NAV", "didFinish load")
        }

        func cleanupTempFile() {
            if let url = tempHTMLURL {
                try? FileManager.default.removeItem(at: url)
                tempHTMLURL = nil
            }
        }

        deinit { cleanupTempFile() }
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
        context.coordinator.cleanupTempFile()

        let log = DebugLog.shared
        let path = url.path
        let fm = FileManager.default

        log.log("FILE", "path: \(path)")
        log.log("FILE", "exists: \(fm.fileExists(atPath: path)), readable: \(fm.isReadableFile(atPath: path))")
        if let attrs = try? fm.attributesOfItem(atPath: path) {
            let size = (attrs[.size] as? Int64) ?? 0
            log.log("FILE", "size: \(size) bytes, type: \((attrs[.type] as? FileAttributeType)?.rawValue ?? "unknown")")
        }

        let parentDir = url.deletingLastPathComponent()
        let filename = url.lastPathComponent

        log.log("WK-LOAD", "parentDir: \(parentDir.path)")
        log.log("WK-LOAD", "filename: \(filename)")

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
          <source src="\(filename)" type="video/webm">
        </video>
        <script>
        var v = document.getElementById('v');

        function post(name, msg) {
            window.webkit.messageHandlers[name].postMessage(msg);
        }

        v.addEventListener('ended', function() { post('videoEnded', 'ended'); });

        v.addEventListener('error', function(e) {
            var code = v.error ? v.error.code : '?';
            var msg = v.error ? v.error.message : '(no message)';
            post('videoError', 'MediaError code=' + code + ' msg=' + msg + ' src=' + v.currentSrc);
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

        // Write HTML to a temp file in the same directory so loadFileURL
        // can grant read access to sibling files (the video).
        let tempName = ".slideshow-player-\(UUID().uuidString).html"
        let tempURL = parentDir.appendingPathComponent(tempName)
        do {
            try html.write(to: tempURL, atomically: true, encoding: .utf8)
            context.coordinator.tempHTMLURL = tempURL
            log.log("WK-LOAD", "loading temp HTML: \(tempURL.lastPathComponent)")
            nsView.loadFileURL(tempURL, allowingReadAccessTo: parentDir)
        } catch {
            log.log("WK-LOAD-ERR", "failed to write temp HTML: \(error.localizedDescription)")
        }
    }
}
