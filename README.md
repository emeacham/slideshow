# Slideshow

A native macOS image slideshow app built with SwiftUI and Swift Package Manager.

## Requirements

| Tool | Version |
|------|---------|
| macOS | 13.0 Ventura or later |
| Swift | 5.9 or later |
| Xcode | 15+ (optional — SPM works from the terminal) |

---

## Quick Start

### Option A — Terminal

```bash
# 1. Clone / navigate to the project
cd /path/to/slideshow

# 2. Build a release .app bundle and launch it
./build-app.sh release
open Slideshow.app
```

### Option B — Xcode

```bash
open Package.swift   # Xcode opens the SPM package as a full project
```

Press **⌘R** to build and run.

---

## Installing to /Applications (Spotlight support)

```bash
./build-app.sh release install
```

After installation, press **⌘Space** and type `Slideshow` — the app will appear in Spotlight results.

**First-launch security prompt:** macOS Gatekeeper will warn that the app is from an unidentified developer (ad-hoc signed, no Apple Developer account required). Right-click the app → **Open** → **Open** to approve it permanently.

---

## Build Script Reference

```bash
./build-app.sh [config] [install]
```

| Argument | Default | Description |
|----------|---------|-------------|
| `config` | `release` | `release` or `debug` |
| `install` | _(omitted)_ | Pass `install` to copy to `/Applications` |

Examples:

```bash
./build-app.sh                    # release build, Slideshow.app in project root
./build-app.sh debug              # debug build
./build-app.sh release install    # release build + install to /Applications
```

The script:
1. Runs `swift build -c [config]`
2. Assembles `Slideshow.app/Contents/` with the binary and `Info.plist`
3. Ad-hoc signs with `codesign --sign -`
4. Optionally copies to `/Applications`

---

## Running Tests

```bash
swift test
```

32 unit tests cover the pure-logic core (navigation, file loading, transition types). All tests run in < 100 ms with no UI setup.

```
Test Suite 'SlideshowTests' — 32 tests
  SlideshowControllerTests  (18)  — navigation, wrap-around, index clamping
  ImageFileLoaderTests       (8)  — format filtering, sorting, hidden files
  TransitionTypeTests        (6)  — codable, identifiable, equatable
```

---

## Project Structure

```
slideshow/
├── Package.swift                    # SPM manifest
├── Resources/
│   └── Info.plist                   # macOS app bundle metadata
├── build-app.sh                     # builds + assembles Slideshow.app
│
├── Sources/
│   ├── SlideshowCore/               # ← pure logic, no SwiftUI, fully testable
│   │   ├── TransitionType.swift     #   enum: None / Fade / Slide / Zoom
│   │   ├── SlideshowController.swift#   value-type state machine (struct)
│   │   └── ImageFileLoader.swift    #   scans a directory for image URLs
│   │
│   └── Slideshow/                   # ← SwiftUI executable
│       ├── SlideshowApp.swift       #   @main entry point
│       ├── SlideshowViewModel.swift #   @MainActor ObservableObject, timer, NSOpenPanel
│       ├── TransitionType+SwiftUI.swift # SwiftUI animations/transitions on core enum
│       ├── ContentView.swift        #   root: welcome screen ↔ slideshow
│       ├── SlideshowView.swift      #   image + controls overlay, auto-hide logic
│       ├── AsyncImageView.swift     #   NSViewRepresentable wrapping NSImageView (GIF-aware)
│       ├── ControlsView.swift       #   transport bar with keyboard shortcuts
│       └── SettingsView.swift       #   transition style + slide duration sheet
│
└── Tests/
    └── SlideshowTests/
        ├── SlideshowControllerTests.swift
        ├── ImageFileLoaderTests.swift
        └── TransitionTypeTests.swift
```

### Architecture: Two-Target Split

`SlideshowCore` is a pure Swift library — no SwiftUI, no AppKit, no timers. All navigation logic lives in `SlideshowController`, a plain `struct` with `mutating func` methods. This makes it trivially testable without mocks.

`Slideshow` is the SwiftUI executable. `SlideshowViewModel` wraps `@Published var controller = SlideshowController()`. SwiftUI can synthesize `Binding` values through struct keypaths, so `$viewModel.controller.transitionType` "just works" as a two-way binding in `SettingsView`.

SwiftUI-specific behavior (animation curves, `AnyTransition`) is added via `extension TransitionType` in `TransitionType+SwiftUI.swift` — the core enum stays framework-free.

---

## Development Workflow

### Adding a new transition type

1. Add a case to `TransitionType` in `Sources/SlideshowCore/TransitionType.swift`
2. Add the `swiftUITransition` and `animation` cases in `Sources/Slideshow/TransitionType+SwiftUI.swift`
3. Add a test case in `Tests/SlideshowTests/TransitionTypeTests.swift`

### Adding a supported image format

1. Add the extension string to `ImageFileLoader.supportedExtensions` in `Sources/SlideshowCore/ImageFileLoader.swift`
2. Add it to the test in `ImageFileLoaderTests.testSupportedExtensionsContainsCommonFormats`

### Rebuilding the .app after code changes

```bash
./build-app.sh release install   # rebuild + update /Applications
```

---

## Supported Image Formats

`jpg` · `jpeg` · `png` · `gif` (animated) · `bmp` · `tiff` · `tif` · `heic` · `heif` · `webp`

Animated GIFs loop continuously until the slideshow advances to the next image.
