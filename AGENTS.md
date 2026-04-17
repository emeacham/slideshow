# AGENTS.md — Slideshow

AI agent guidance for the **Slideshow** native macOS image slideshow app (SwiftUI + Swift Package Manager).

---

## Quick Build & Test

```bash
# Build a release .app bundle
./build-app.sh release

# Run unit tests (< 100 ms, no UI)
swift test
```

Always run `swift test` after modifying any file in `Sources/SlideshowCore/` or `Tests/`.

---

## Architecture at a Glance

The project is split into two targets to keep logic pure and testable:

| Target | Path | Role |
|--------|------|------|
| `SlideshowCore` | `Sources/SlideshowCore/` | Pure Swift library — no SwiftUI, no AppKit, no timers. Fully unit-tested. |
| `Slideshow` | `Sources/Slideshow/` | SwiftUI executable. Imports `SlideshowCore`. |

### Key files

| File | Purpose |
|------|---------|
| `SlideshowCore/ImageFileLoader.swift` | Scans a directory for supported image URLs. Add new formats here. |
| `SlideshowCore/SlideshowController.swift` | Pure value-type state machine — navigation, index, transition, delay. |
| `SlideshowCore/TransitionType.swift` | Enum of transition styles (none/fade/slide/zoom). Codable + Equatable. |
| `Slideshow/SlideshowViewModel.swift` | `@MainActor ObservableObject` — timer, NSOpenPanel, directory loading, drag-drop routing. |
| `Slideshow/ContentView.swift` | Root view — welcome screen ↔ slideshow, drag-and-drop handler, toolbar. |
| `Slideshow/SlideshowView.swift` | Full-screen image display with auto-hiding controls overlay. |
| `Slideshow/AsyncImageView.swift` | `NSViewRepresentable` wrapping `NSImageView` (GIF-aware, WebP-aware). |
| `Slideshow/VideoPlayerView.swift` | `NSViewRepresentable` wrapping `WKWebView` for WebM playback (AVFoundation does not support VP8/VP9). |
| `Slideshow/AppState.swift` | Singleton shared state (credits sheet visibility) for `.commands{}` access. |

---

## Supported Formats

### Images
`jpg` · `jpeg` · `png` · `gif` (animated) · `bmp` · `tiff` · `tif` · `heic` · `heif` · `webp`

### Video
`webm` (VP8/VP9, macOS 11+)

All formats are defined via `ImageFileLoader`. Video extensions live in `ImageFileLoader.videoExtensions` and are automatically unioned into `supportedExtensions`. `SlideshowView` dispatches to `VideoPlayerView` (AVKit) for video and `AsyncImageView` (NSImageView) for everything else.

---

## Common Tasks

### Adding a new image format

1. Add the lowercase extension string to `ImageFileLoader.supportedExtensions` in `Sources/SlideshowCore/ImageFileLoader.swift`
2. Add an `XCTAssertTrue(ext.contains("…"))` line in `ImageFileLoaderTests.testSupportedExtensionsContainsCommonFormats`
3. Update the format list in `README.md`

### Adding a new video format

1. Add the lowercase extension to `ImageFileLoader.videoExtensions` — it is automatically included in `supportedExtensions` via `Set.union`
2. Confirm WebKit/HTML5 video can decode the codec; add a `<source type="…">` in `VideoPlayerView.updateNSView` if a different MIME type is required
3. Add assertions in `ImageFileLoaderTests.testVideoExtensionsContainsWebM` (or add a new test) and update `README.md`

> **Note:** AVFoundation does not support VP8/VP9, so `VideoPlayerView` uses `WKWebView` with an HTML5 `<video>` element and `loadHTMLString(_:baseURL:)` so the local file is accessible. Do not use AVKit for WebM or other VP8/VP9 content.

### Adding a new transition type

1. Add a case to `TransitionType` in `Sources/SlideshowCore/TransitionType.swift`
2. Add `swiftUITransition` and `animation` cases in `Sources/Slideshow/TransitionType+SwiftUI.swift`
3. Add a test case in `Tests/SlideshowTests/TransitionTypeTests.swift`

### Drag-and-drop behaviour

Drop handling lives in `ContentView.onDrop(of: [UTType.fileURL], …)`. It delegates to `SlideshowViewModel.loadURL(_ url: URL)`, which:
- **Directory dropped** → calls `loadDirectory(_:)` to load all images in the folder
- **Image file dropped** → loads the parent directory, then navigates to the specific dropped image

The visual drag indicator (accent-colored border + icon swap in `WelcomeView`) is driven by the `isDragTargeted` binding produced by `.onDrop`.

---

## Code Conventions

- **License header**: every `.swift` file starts with the three-line GPL-3 header present in existing files.
- **Pure core**: `SlideshowCore` must not import `SwiftUI`, `AppKit`, or any other UI framework.
- **`@MainActor`**: all `SlideshowViewModel` methods run on the main actor; call `DispatchQueue.main.async` when dispatching from `NSItemProvider` callbacks.
- **`withAnimation`**: wrap all `SlideshowController` mutations in `withAnimation(controller.transitionType.animation)` so transitions apply.
- **No force-unwraps** in production paths; use `guard let` or `if let`.
- **Test coverage**: pure logic in `SlideshowCore` must have corresponding unit tests in `Tests/SlideshowTests/`.

---

## Tests

```
Tests/SlideshowTests/
├── SlideshowControllerTests.swift   # 18 tests — navigation, wrap-around, index clamping
├── ImageFileLoaderTests.swift       #  8 tests — format filtering, sorting, hidden files
└── TransitionTypeTests.swift        #  6 tests — Codable, Identifiable, Equatable
```

Run with `swift test`. All 32 tests complete in < 100 ms with no UI or network access.

---

## Build Script

```bash
./build-app.sh [config] [install]
```

| Argument | Default | Description |
|----------|---------|-------------|
| `config` | `release` | `release` or `debug` |
| `install` | _(omitted)_ | Pass `install` to copy the bundle to `/Applications` |

The script: builds with SPM → assembles `Slideshow.app/Contents/` → ad-hoc signs → optionally installs.
