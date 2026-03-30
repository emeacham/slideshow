// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI
import Combine
import AppKit
import SlideshowCore

@MainActor
final class SlideshowViewModel: ObservableObject {

    // Publishing the whole controller struct means SwiftUI re-renders on any
    // nested property change, and $viewModel.controller.someProperty bindings work.
    @Published var controller = SlideshowController()
    @Published var isPlaying = false
    @Published var selectedDirectory: URL?
    @Published var errorMessage: String?

    private var timer: AnyCancellable?

    // MARK: - Passthroughs

    var currentImageURL: URL? { controller.currentImageURL }
    var hasImages: Bool        { controller.hasImages }
    var currentIndex: Int      { controller.currentIndex }
    var totalCount: Int        { controller.totalCount }

    var transitionType: TransitionType {
        get { controller.transitionType }
        set { controller.transitionType = newValue }
    }

    var slideDelay: Double {
        get { controller.slideDelay }
        set {
            controller.slideDelay = newValue
            if isPlaying { restartTimer() }
        }
    }

    // MARK: - Directory loading

    func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Image Folder"
        panel.prompt = "Select"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadDirectory(url)
    }

    func loadDirectory(_ url: URL) {
        do {
            let urls = try ImageFileLoader.loadImages(from: url)
            withAnimation(controller.transitionType.animation) {
                controller.loadImages(urls)
            }
            selectedDirectory = url
            errorMessage = nil
            if isPlaying { restartTimer() }
        } catch {
            errorMessage = "Could not load images: \(error.localizedDescription)"
        }
    }

    // MARK: - Navigation

    func next() {
        withAnimation(controller.transitionType.animation) {
            controller.advance()
        }
    }

    func previous() {
        withAnimation(controller.transitionType.animation) {
            controller.goBack()
        }
    }

    // MARK: - Playback

    func play() {
        guard hasImages else { return }
        isPlaying = true
        scheduleTimer()
    }

    func pause() {
        isPlaying = false
        timer?.cancel()
        timer = nil
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    // MARK: - Private

    private func scheduleTimer() {
        timer?.cancel()
        timer = Timer.publish(every: controller.slideDelay, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.next() }
    }

    private func restartTimer() {
        guard isPlaying else { return }
        scheduleTimer()
    }
}
