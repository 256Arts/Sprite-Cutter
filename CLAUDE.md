# Sprite Cutter

A small SwiftUI app for cutting a sprite-sheet image into individual sprite files. Drop or import a spritesheet, set the sprite size / count / spacing, and export each sprite as a PNG. Also exposed as a Shortcuts / App Intent.

> **Duplicated logic:** The core cutting functionality here is also (intentionally) duplicated in the **Sprite Catalog** app. When changing cutting behavior (`Cutter.swift`, the App Intent, sizing math), keep the two apps in sync.

## Platforms

Built from one target with `#if` compilation conditions, not separate targets:
- `canImport(UIKit)` vs `AppKit` — image type is `UIImage` on iOS-family, `NSImage` on macOS.
- `targetEnvironment(macCatalyst)` — Catalyst gets a denser layout, an editable spacing `IntField`, and an explicit "Cut" button row; other platforms use a stepper + full-width button.
- `os(visionOS)` uses `.borderedProminent`; other non-Catalyst platforms use `.glassProminent`.

When editing UI or image code, check whether a change needs to be mirrored across these branches.

## Architecture

- `Cutter.swift` — **the core, platform-agnostic engine.** `Cutter` struct holds the source image, `spriteSize` (`PixelSize`), and `spacing`. Computes `spriteCounts` (cols × rows) bidirectionally — setting either the size or the count recomputes the other. `cut()` crops the image via `cgImage.cropping(to:)` row-by-row and returns an array of images. This is the logic shared with Sprite Catalog.
- `CutterView.swift` — main view + `DropDelegate`. Handles drag-and-drop, file import (`.fileImporter`), and export (`.fileExporter` writing `[ImageDocument]`). Exported sprites are named `Sprite 1`, `Sprite 2`, …
- `ImageDocument.swift` — `FileDocument` wrapper that serializes a single sprite to PNG.
- `IntField.swift` — reusable numeric `TextField` (numpad, defaults invalid input to `1`).
- `Sprite_CutterApp.swift` — `@main` app, window scene, menu/toolbar links, and an App Store event deep-link handler (`spritecutter/appstoreevent`).
- `App Intent/` — `CutSprites` (App Intent / Shortcuts action; reuses `Cutter`, caps input at 512×512px) and `SpriteCutterAppShortcutsProvider` (voice phrases).

## Key conventions

- All sprite-cutting math lives in `Cutter`; views and the App Intent are thin wrappers over it. Add new cutting features there so both UI and Shortcuts benefit (and remember to port to Sprite Catalog).
- `spriteCounts` is a computed property with a setter — editing column/row fields mutates `spriteSize`, and vice versa. Be careful with rounding when touching this.
- Build & run via Xcode (`Sprite Cutter.xcodeproj`).
