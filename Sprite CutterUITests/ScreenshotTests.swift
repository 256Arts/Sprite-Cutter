import XCTest
#if canImport(UIKit)
import UIKit
#endif

/// Drives the app to the screen that becomes its App Store screenshot and attaches it to the result
/// bundle, where the shared `screenshots` runner collects it.
///
/// One shot per platform: the app is a single screen, and the only other state it has is the empty
/// drop target it starts from — which shows nothing of what the app does.
@MainActor
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    /// Whether the walk turned the device on its side, which the capture has to undo.
    ///
    /// Tracked here rather than read back from `XCUIDevice.shared.orientation`, which a simulator
    /// answers as portrait however the UI is laid out.
    private var isLandscape = false

    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["-screenshotMode"]
        app.launch()
        bringToFront(app)
        #if os(macOS)
        openWindowIfNeeded()
        #elseif os(iOS)
        turnToRequestedOrientation()
        #endif
        checkSeedIsThrowaway()

        // The seeded sheet is the only image in the app, and it arrives with the launch rather than
        // after one — so its presence is what says the seed landed.
        let spritesheet = app.images["Spritesheet"]
        guard waitFor(spritesheet, "the seeded spritesheet", shot: "01-spritesheet", timeout: 60) else { return }
        // 112x80 of 16x16 sprites. A different number here means the sheet came back at the wrong
        // scale, which the shot would show as the wrong sprite size rather than as a missing image.
        XCTAssertEqual(app.textFields["Columns"].value as? String, "7",
                       "the demo sheet did not divide into 7 columns — is the asset still single scale?")
        settle()
        capture(app, named: "01-spritesheet")
    }

    // MARK: - The seed

    /// What the app said it prepared, read out of the accessibility tree.
    ///
    /// The app hangs `ScreenshotMode.status` on its root view (`.screenshotModeStatus()`). A walk
    /// that cannot find it is running against a build that has not adopted that modifier, which is
    /// worth saying plainly rather than reporting as an empty seed.
    private var seedStatus: String {
        let label = app.descendants(matching: .any)["ScreenshotMode.Status"]
        guard label.waitForExistence(timeout: 30) else {
            return "no ScreenshotMode.Status element — add .screenshotModeStatus() to the app's root view"
        }
        // A SwiftUI `Text` reaches XCUITest as the element's *value* on macOS and as its *label* on
        // iOS, so take whichever is filled in rather than betting on one.
        if let value = label.value as? String, !value.isEmpty { return value }
        return label.label
    }

    /// Stops the walk when the app did not prepare a spritesheet to photograph.
    ///
    /// The walk that followed would otherwise photograph the empty drop target and fail on a missing
    /// image, which says nothing about why. Read the reason instead, before the first shot.
    private func checkSeedIsThrowaway() {
        let status = seedStatus
        print("SCREENSHOT MODE: \(status)")
        guard status.hasPrefix("ready") else {
            attach(XCTAttachment(string: app.debugDescription), named: "element-tree")
            return XCTFail("the app did not prepare a spritesheet, so there is nothing to photograph — \(status)")
        }
    }

    private static var platform: String {
        #if os(macOS)
        "macOS"
        #elseif os(visionOS)
        "visionOS"
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        #endif
    }

    /// Which simulator this was, for a failure read days after the run's own log is gone.
    private static var device: String {
        ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "this machine"
    }

    // MARK: - Driving

    #if os(iOS)
    /// Turns the device the way the runner asked (`IPAD_ORIENTATION`, landscape by default on iPad).
    ///
    /// After `launch()`, not before: a rotation set before the app is up is silently dropped, and
    /// the set comes back portrait. The runner checks every shot's shape, so that fails the run.
    private func turnToRequestedOrientation() {
        guard ProcessInfo.processInfo.environment["SCREENSHOT_ORIENTATION"] == "landscape" else { return }
        XCUIDevice.shared.orientation = .landscapeLeft
        isLandscape = true
        settle()
    }
    #endif

    /// The screenshot, turned the way the device is being held.
    ///
    /// `XCUIScreen.main.screenshot()` photographs the *physical* screen: a rotated device comes back
    /// as a portrait buffer carrying its quarter turn as metadata, which `XCTAttachment(screenshot:)`
    /// writes out content-on-its-side. Redrawing bakes the metadata into the pixels — `UIImage.size`
    /// is already the turned size and `draw(at:)` honours the orientation, so no manual rotation.
    private func upright(_ screenshot: XCUIScreenshot) -> XCTAttachment {
        #if os(iOS)
        guard isLandscape else { return XCTAttachment(screenshot: screenshot) }
        let image = screenshot.image
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale   // keep the pixel count the store checks against
        format.opaque = true
        return XCTAttachment(image: UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(at: .zero)
        })
        #else
        XCTAttachment(screenshot: screenshot)
        #endif
    }

    /// Waits for `element`, and on a miss fails with the platform, the device, what the walk was
    /// waiting for, and what the app reported it seeded — so a failure names itself instead of
    /// reading as "seeded content never appeared".
    private func waitFor(_ element: XCUIElement, _ description: String, shot: String, timeout: TimeInterval) -> Bool {
        guard element.waitForExistence(timeout: timeout) else {
            attach(XCTAttachment(string: app.debugDescription), named: "element-tree")
            XCTFail("""
                \(shot): never found \(description) in \(Int(timeout))s on \(Self.platform), \(Self.device).
                The app reported: \(seedStatus)
                """)
            return false
        }
        return true
    }
    
    /// Makes the app's window key before photographing it.
    ///
    /// A Mac window that is not frontmost comes back `Disabled` in the element tree. Nothing steals
    /// focus on a simulator, so this is a Mac-only concern.
    private func bringToFront(_ app: XCUIApplication) {
        #if os(macOS)
        app.activate()
        #endif
    }
    
    #if os(macOS)
    /// Opens a window when the launch came up without one.
    ///
    /// `XCUIApplication.launch()` launches a Mac app in the *background*, and AppKit gives a
    /// background launch no window — only a reopen (a Dock icon click) builds it, which a test
    /// runner cannot send. So the walk asks for the window itself, with the app's own New Window.
    /// Waiting first, so ⌘N cannot beat the launch's own window into the tree and open a second.
    private func openWindowIfNeeded() {
        if app.windows.firstMatch.waitForExistence(timeout: 10) { return }
        app.typeKey("n", modifierFlags: .command)
        XCTAssert(app.windows.firstMatch.waitForExistence(timeout: 15), "no window after ⌘N — the app launched with none")
    }
    #endif
    
    /// Animations have no element to wait on, so the shot pauses instead.
    private func settle(seconds: TimeInterval = 2) {
        Thread.sleep(forTimeInterval: seconds)
    }
    
    // MARK: - Capturing
    
    private func capture(_ app: XCUIApplication, named name: String) {
        // Every capture below photographs the whole screen, or the frontmost window — never this
        // app in particular. So an app that has lost the foreground yields another app's UI, filed
        // under this app's name, at the right size, with nothing to notice. The shared runner holds
        // a machine-wide lock so that cannot happen; this is the check that it held.
        XCTAssertEqual(app.state, .runningForeground,
                       "\(name): the app under test was not frontmost — another app has this device")
        #if os(macOS) || os(visionOS)
        // Both of these are photographed from outside the test: the Mac because only the shell has
        // Screen Recording, visionOS because it has no screen for `XCUIScreen` to return (the call
        // comes back 1x1) and its window alone is neither the store's size nor its framing.
        if requestHostCapture(named: name) { return }
        #if os(visionOS)
        // The handshake directory was unreachable — better a window at the wrong size than no shot.
        attach(XCTAttachment(screenshot: app.screenshot()), named: name)
        #endif
        #else
        // The simulator's screen already *is* the store's canvas, at the exact required pixel size.
        attach(upright(XCUIScreen.main.screenshot()), named: name)
        #endif
    }
    
    private func attach(_ attachment: XCTAttachment, named name: String) {
        attachment.name = name
        attachment.lifetime = .keepAlways // attachments on a passing test are discarded otherwise
        add(attachment)
    }
    
    #if os(macOS) || os(visionOS)
    
    /// Asks the shell running the tests to take the picture, and waits for it.
    ///
    /// The good capture is `screencapture -l`, which reads the window's own buffer: correctly masked
    /// to the rounded corners, with real alpha and the system's own shadow. (`XCUIElement.screenshot()`
    /// crops the *screen* to the window's frame, so it loses the shadow — drawn outside that frame —
    /// and leaves desktop inside the corners.) But `screencapture` needs Screen Recording, which the
    /// test runner has no grant for and the terminal running the script does. So the test drives the
    /// UI and the script takes the picture.
    ///
    /// They meet in a plain directory under /tmp, which works only because the runner is deliberately
    /// unsandboxed (UITests.entitlements): the app is sandboxed and the runner inherits that, and a
    /// sandboxed runner cannot write /tmp while its own container is unreadable to the script.
    /// (On the visionOS simulator the same path is the host's, which is what lets `simctl` answer.)
    private static let handshakeDirectory = URL(fileURLWithPath: "/tmp/app-store-screenshots")
    
    /// Returns whether the shot was taken. `false` means the handshake directory was unreachable, so
    /// the caller should fall back to whatever it can capture from in here.
    private func requestHostCapture(named name: String) -> Bool {
        let files = FileManager.default
        let handshake = Self.handshakeDirectory
        let done = handshake.appendingPathComponent("done-\(name)")
        try? files.removeItem(at: done)
        
        let request = handshake.appendingPathComponent("request-\(name)")
        guard files.createFile(atPath: request.path, contents: nil) else { return false }
        
        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if files.fileExists(atPath: done.path) { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("timed out waiting for the script to capture \(name) — is the runner watching \(handshake.path)?")
        return true // the runner is the one at fault; a fallback shot would only hide that
    }
    
    #endif
    
}
