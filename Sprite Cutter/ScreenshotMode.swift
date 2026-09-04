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
    
    /// Whether this launch should arrive empty, for the shot of the drop target.
    ///
    /// Asked for with a second argument rather than by dropping `-screenshotMode`, so that shot is
    /// still taken with the Mac window pinned to the same size as the one before it.
    private static let isEmptyState = ProcessInfo.processInfo.arguments.contains("-screenshotEmptyState")
    
    /// A spritesheet for the cutter to arrive holding, so the shot shows the app doing its job
    /// instead of its "Drop spritesheet here" empty state. `nil` outside a screenshot run.
    ///
    /// 112x80 of 16x16 sprites, so it divides exactly at the cutter's own default sprite size and
    /// the counts read 7 by 5 without the walk having to type anything. The art is Gentle Cat
    /// Studios', released CC0. Stored single-scale, so `size` is the sheet's size in pixels — which
    /// is what `Cutter` measures in.
    static var demoSpritesheet: UIImage? {
        guard isActive, !isEmptyState else { return nil }
        return UIImage(named: "Demo Spritesheet")
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
