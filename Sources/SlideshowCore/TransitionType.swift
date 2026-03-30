// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import Foundation

public enum TransitionType: String, CaseIterable, Identifiable, Codable, Equatable {
    case none  = "None"
    case fade  = "Fade"
    case slide = "Slide"
    case zoom  = "Zoom"

    public var id: String { rawValue }
    public var displayName: String { rawValue }
}
