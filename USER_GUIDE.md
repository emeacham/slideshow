# Slideshow — User Guide

Slideshow is a native macOS app for viewing a folder of images as a full-screen or windowed slideshow. It supports all common image formats including animated GIFs, offers four transition styles, and gives you full keyboard control.

---

## Installing the App

1. Open Terminal, navigate to the project folder, and run:

   ```bash
   ./build-app.sh release install
   ```

2. The first time you open the app, macOS will show a security warning because the app is not from the Mac App Store. To approve it:
   - **Right-click** `Slideshow.app` → **Open** → click **Open** in the dialog.
   - You only need to do this once.

3. After approving, you can open Slideshow from:
   - **Spotlight** — press **⌘Space**, type `Slideshow`, press **Return**
   - **Launchpad** — find it in the grid
   - **/Applications** — double-click `Slideshow.app`

---

## Getting Started

When you first open Slideshow, you'll see a welcome screen with an **Open Folder** button.

1. Click **Open Folder** (or press **⌘O**) to choose a folder of images.
2. Slideshow scans the folder for supported image files, sorts them by filename, and displays the first image.
3. Press **Space** or click the play button to start the slideshow.

> **Tip:** You can switch folders at any time using the **Open Folder** button in the toolbar (top-right corner of the window).

---

## Playback Controls

### On-screen controls

The control bar appears at the bottom of the window. It auto-hides after 3 seconds while a slideshow is playing and reappears whenever you move the mouse.

| Button | Action |
|--------|--------|
| ⏮ (backward) | Previous image |
| ▶ / ⏸ | Play / Pause |
| ⏭ (forward) | Next image |
| ⚙ (gear) | Open Settings |
| ⤢ (arrows) | Toggle fullscreen |

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| `Space` | Play / Pause |
| `←` Left Arrow | Previous image |
| `→` Right Arrow | Next image |
| `F` | Toggle fullscreen |
| `⌘O` | Open a new folder |
| `⌘,` | Open Settings |

> **Tip:** Keyboard shortcuts work whether the controls are visible or hidden. You can run a fullscreen slideshow with nothing on screen and still navigate with the arrow keys.

---

## Fullscreen Mode

Click the **⤢** button or press **F** to enter fullscreen. The window expands to fill the entire screen, hiding the menu bar and Dock.

- Move the mouse to show the controls overlay while in fullscreen.
- Press **F** again, or press **Esc**, or use the green traffic-light button to exit fullscreen.

The native macOS fullscreen button (green dot, top-left of the title bar) also works.

---

## Settings

Open Settings with **⌘,** or the gear icon in the control bar.

### Transition Style

Choose how images change from one to the next:

| Style | Description |
|-------|-------------|
| **None** | Instant cut — no animation |
| **Fade** | Smooth opacity crossfade (default) |
| **Slide** | New image slides in from the right; old image exits left |
| **Zoom** | New image scales up from the center with a spring bounce |

### Slide Duration

The number of seconds each image is displayed before the slideshow automatically advances. Range: **1 – 20 seconds** in 0.5-second steps.

- The current folder name is shown at the bottom of the Settings sheet for reference.
- Changes take effect immediately — if a slideshow is playing when you adjust the duration, the timer resets to the new value.

---

## Animated GIFs

Slideshow plays animated GIFs natively:

- When the slideshow reaches an animated GIF, the animation **loops continuously** until the slideshow advances to the next image.
- No settings are required — GIF animation is always on.
- The standard playback controls (pause, next, previous) work normally while a GIF is animating.

---

## Supported Image Formats

| Format | Extensions |
|--------|------------|
| JPEG | `.jpg`, `.jpeg` |
| PNG | `.png` |
| GIF (animated) | `.gif` |
| BMP | `.bmp` |
| TIFF | `.tiff`, `.tif` |
| HEIC / HEIF | `.heic`, `.heif` |
| WebP | `.webp` |

Files with other extensions (videos, PDFs, documents) are ignored. Hidden files (names starting with `.`) are also skipped automatically.

Images within the selected folder are sorted alphabetically by filename. Sub-folders are not scanned.

---

## Tips and Tricks

**Quickly browse images manually**
Pause the slideshow (Space) and use ← / → to step through images at your own pace.

**Use it as a photo frame**
Set a long slide duration (10–20 s), choose the Fade transition, and enter fullscreen. Move the mouse away — the controls disappear and the screen becomes a silent photo frame.

**Keyboard-only operation**
After opening a folder and pressing Space to play, you never need to touch the mouse. Arrow keys navigate, F toggles fullscreen, Space pauses.

**Rename files to control order**
Slideshow sorts by filename. Prefix filenames with numbers (`01_beach.jpg`, `02_sunset.jpg`) to set a specific sequence.

**Re-open the last folder quickly**
After the first use, ⌘O opens the file picker pre-focused on the last directory you visited.

---

## Troubleshooting

**The app won't open — "unidentified developer" warning**
Right-click the app icon → **Open** → click **Open**. This approves the ad-hoc signature permanently.

**No images appear after selecting a folder**
The folder may contain only unsupported file types (e.g., videos or RAW camera files). Try a folder with `.jpg`, `.png`, or `.heic` files.

**The slideshow skips very quickly**
Check Settings (⌘,) — the slide duration may be set to 1 second. Drag the slider to the right to increase it.

**Animated GIF doesn't animate**
Ensure the file extension is `.gif`. Some animated images saved as `.png` (APNG) are not currently supported.

**App is not found in Spotlight**
Spotlight indexes `/Applications`. Make sure you installed with `./build-app.sh release install`. If it still doesn't appear, open System Settings → Siri & Spotlight → Spotlight Privacy, and ensure `/Applications` is not excluded.
