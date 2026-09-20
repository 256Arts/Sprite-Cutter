import SwiftUI

/// Deterministic demo state for App Store screenshots, switched on by the `-screenshotMode` launch
/// argument the UI test passes.
///
/// The app persists nothing, so there is no store to seed and nothing on the machine to disturb —
/// what a fresh launch is missing is only a spritesheet. Handing the cutter one is the whole seed.
enum ScreenshotMode {
    
    /// Whether this launch is a screenshot run. Read by `CutterView`, to arrive with a spritesheet
    /// already loaded, and by `pinWindowLayout()`.
    static let isActive = ProcessInfo.processInfo.arguments.contains("-screenshotMode")
    
    /// A spritesheet for the cutter to arrive holding, so the shot shows the app doing its job
    /// instead of its "Drop spritesheet here" empty state. `nil` outside a screenshot run.
    ///
    /// 112x80 of 16x16 sprites, so it divides exactly at the cutter's own default sprite size and
    /// the counts read 7 by 5 without the walk having to type anything. The art is Gentle Cat
    /// Studios', released CC0. Stored single-scale, so `size` is the sheet's size in pixels — which
    /// is what `Cutter` measures in.
    static let demoSpritesheet: UIImage? = isActive ? UIImage(named: "Demo Spritesheet") : nil

    // MARK: - Saying what happened

    /// What this launch prepared, in one line, for the walk and for the shared runner.
    ///
    /// A failed walk otherwise reports only "seeded content never appeared", which is equally true
    /// of a demo asset that never loaded and a screen that never opened. The walk reads this out of
    /// the accessibility tree before its first shot and prints it on any miss.
    ///
    /// Computed rather than set by whoever loads the sheet first, so it is already true on the first
    /// frame — the overlay that shows it is built before `CutterView`'s state is.
    static var status: String {
        guard let image = demoSpritesheet else {
            return "REFUSED — no \"Demo Spritesheet\" asset in the bundle"
        }
        let width = Int(image.size.width), height = Int(image.size.height)
        return "ready — no persistent store to seed; loaded a \(width)x\(height) demo spritesheet (\(width / 16)x\(height / 16) sprites)"
    }

    /// Pins the Mac window to the scene's own `defaultSize`.
    ///
    /// The runner clears the app's saved `NSWindow Frame` defaults before a Mac run, but `defaults`
    /// resolves a sandboxed app's domain to its container, and this app is sandboxed — so it finds
    /// nothing to clear and the window comes back at whatever size it was last dragged to. Asking
    /// for the geometry from inside the app is then the only deterministic option.
    @MainActor
    static func pinWindowLayout() {
        guard isActive else { return }
        #if targetEnvironment(macCatalyst)
        let frame = CGRect(x: 0, y: 0, width: 500, height: 650) // the scene's own `defaultSize`
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.requestGeometryUpdate(.Mac(systemFrame: frame))
        }
        #endif
    }

}

extension View {

    /// Carries `ScreenshotMode.status` into the accessibility tree, where the walk reads it.
    ///
    /// Nothing on a normal launch; on a screenshot run, a one-point transparent label — present to
    /// XCUITest, invisible in the shot. It is how the walk can tell a seed that never ran from a
    /// screen that never opened, neither of which the app can report any other way: a simulator
    /// app's `print` does not reach the build log, and there is no file path both the app and the
    /// runner can write.
    @ViewBuilder
    func screenshotModeStatus() -> some View {
        if ScreenshotMode.isActive {
            overlay(alignment: .topLeading) {
                Text(ScreenshotMode.status)
                    .font(.system(size: 1))
                    .opacity(0.001)
                    .accessibilityIdentifier("ScreenshotMode.Status")
                    .allowsHitTesting(false)
            }
        } else {
            self
        }
    }

}
