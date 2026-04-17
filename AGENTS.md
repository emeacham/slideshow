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
| `Slideshow/AppState.swift` | Singleton shared state (credits sheet visibility) for `.commands{}` access. |

---

## Supported Image Formats

`jpg` · `jpeg` · `png` · `gif` (animated) · `bmp` · `tiff` · `tif` · `heic` · `heif` · `webp`

Defined in `ImageFileLoader.supportedExtensions`. The test `testSupportedExtensionsContainsCommonFormats` must be updated alongside any format changes.

---

## Common Tasks

### Adding a new image format

1. Add the lowercase extension string to `ImageFileLoader.supportedExtensions` in `Sources/SlideshowCore/ImageFileLoader.swift`
2. Add an `XCTAssertTrue(ext.contains("…"))` line in `ImageFileLoaderTests.testSupportedExtensionsContainsCommonFormats`
3. Update the format list in `README.md`

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
