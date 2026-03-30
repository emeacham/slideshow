// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI
import SlideshowCore

// SwiftUI animation and transition values for each transition type.
// Kept in the app layer so SlideshowCore stays free of framework dependencies.
extension TransitionType {

    var swiftUITransition: AnyTransition {
        switch self {
        case .none:  return .identity
        case .fade:  return .opacity
        case .slide: return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .zoom:  return .scale(scale: 0.85).combined(with: .opacity)
        }
    }

    var animation: Animation {
        switch self {
        case .none:  return .linear(duration: 0)
        case .fade:  return .easeInOut(duration: 0.45)
        case .slide: return .easeInOut(duration: 0.40)
        case .zoom:  return .spring(response: 0.4, dampingFraction: 0.8)
        }
    }
}
