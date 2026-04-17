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

## Usage

### Opening images

- Click **Open Folder** (⌘O) in the toolbar to pick a folder of images
- **Drag and drop** a folder or an individual image file onto the window — a directory loads all images in it; an image file loads its parent folder and jumps to that image

### Playback controls

| Action | Shortcut |
|--------|----------|
| Play / Pause | Space |
| Next image | → |
| Previous image | ← |
| Toggle fullscreen | F |
| Open folder | ⌘O |
| Settings | ⌘, |
| Debug log | ⌘D |

### Settings

Open **Settings** (⌘,) to choose a transition style (None / Fade / Slide / Zoom) and adjust the slide duration.

### Debug log

Press **⌘D** or click the ladybug button in the toolbar to open the debug log overlay. It shows file metadata, video player events, and any errors — useful for diagnosing why a file isn't loading. Press **Copy** to paste the full log to the clipboard.

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

35 unit tests cover the pure-logic core (navigation, file loading, transition types). All tests run in < 100 ms with no UI setup.

```
Test Suite 'SlideshowTests' — 35 tests
  SlideshowControllerTests  (18)  — navigation, wrap-around, index clamping
  ImageFileLoaderTests      (11)  — format filtering, sorting, hidden files, video extensions
  TransitionTypeTests        (6)  — codable, identifiable, equatable
```

---

## Project Structure

```
slideshow/
├── Package.swift                      # SPM manifest
├── Resources/
│   └── Info.plist                     # macOS app bundle metadata
├── build-app.sh                       # builds + assembles Slideshow.app
│
├── Sources/
│   ├── SlideshowCore/                 # ← pure logic, no SwiftUI, fully testable
│   │   ├── TransitionType.swift       #   enum: None / Fade / Slide / Zoom
│   │   ├── SlideshowController.swift  #   value-type state machine (struct)
│   │   └── ImageFileLoader.swift      #   scans a directory for image/video URLs
│   │
│   └── Slideshow/                     # ← SwiftUI executable
│       ├── SlideshowApp.swift         #   @main entry point
│       ├── AppState.swift             #   shared singleton for menu commands
│       ├── SlideshowViewModel.swift   #   @MainActor ObservableObject, timer, file loading
│       ├── TransitionType+SwiftUI.swift #  SwiftUI animations/transitions on core enum
│       ├── ContentView.swift          #   root: welcome screen ↔ slideshow, drag-and-drop
│       ├── SlideshowView.swift        #   image/video display + controls overlay
│       ├── AsyncImageView.swift       #   NSImageView wrapper (GIF-aware, WebP-aware)
│       ├── VideoPlayerView.swift      #   WKWebView wrapper for WebM video playback
│       ├── DebugLog.swift             #   in-app debug log singleton + overlay
│       ├── ControlsView.swift         #   transport bar with keyboard shortcuts
│       ├── SettingsView.swift         #   transition style + slide duration sheet
│       └── CreditsView.swift          #   credits sheet
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

1. Add the lowercase extension to `ImageFileLoader.supportedExtensions` in `Sources/SlideshowCore/ImageFileLoader.swift`
2. Add an assertion to `ImageFileLoaderTests.testSupportedExtensionsContainsCommonFormats`
3. Update the format list in this README

### Adding a supported video format

1. Add the lowercase extension to `ImageFileLoader.videoExtensions` — it is automatically included in `supportedExtensions` via `Set.union`
2. Confirm WebKit/HTML5 video can decode the codec; add a `<source type="…">` in `VideoPlayerView` if a different MIME type is required
3. Add assertions in `ImageFileLoaderTests` and update this README

> **Note:** AVFoundation does not support VP8/VP9. `VideoPlayerView` uses `WKWebView` with `loadFileURL(_:allowingReadAccessTo:)` — do not use AVKit for VP8/VP9 content. `loadHTMLString` cannot be used either as it sandboxes `file://` access.

### Rebuilding the .app after code changes

```bash
./build-app.sh release install   # rebuild + update /Applications
```

---

## Supported Formats

### Images
`jpg` · `jpeg` · `png` · `gif` (animated) · `bmp` · `tiff` · `tif` · `heic` · `heif` · `webp`

Animated GIFs loop continuously until the slideshow advances to the next image.

### Video
`webm` (VP8 / VP9)

WebM files play via `WKWebView`'s HTML5 video stack. When the slideshow is in play mode, the next slide loads automatically when the video finishes (the video's natural duration overrides the slide-delay timer for that slide).
