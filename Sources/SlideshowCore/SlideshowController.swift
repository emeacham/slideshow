// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import Foundation

// Pure value type — no timers, no UI framework, fully unit-testable.
public struct SlideshowController: Equatable {

    public var imageURLs: [URL]
    public var currentIndex: Int
    public var transitionType: TransitionType
    public var slideDelay: Double

    public init(
        imageURLs: [URL] = [],
        currentIndex: Int = 0,
        transitionType: TransitionType = .fade,
        slideDelay: Double = 3.0
    ) {
        self.imageURLs = imageURLs
        self.currentIndex = imageURLs.isEmpty ? 0 : max(0, min(currentIndex, imageURLs.count - 1))
        self.transitionType = transitionType
        self.slideDelay = slideDelay
    }

    public var hasImages: Bool { !imageURLs.isEmpty }
    public var totalCount: Int { imageURLs.count }

    public var currentImageURL: URL? {
        guard hasImages, imageURLs.indices.contains(currentIndex) else { return nil }
        return imageURLs[currentIndex]
    }

    public mutating func loadImages(_ urls: [URL]) {
        imageURLs = urls
        currentIndex = 0
    }

    public mutating func advance() {
        guard hasImages else { return }
        currentIndex = (currentIndex + 1) % imageURLs.count
    }

    public mutating func goBack() {
        guard hasImages else { return }
        currentIndex = (currentIndex - 1 + imageURLs.count) % imageURLs.count
    }

    public mutating func goToIndex(_ index: Int) {
        guard imageURLs.indices.contains(index) else { return }
        currentIndex = index
    }
}
