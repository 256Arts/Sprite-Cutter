import XCTest

/// Drives the app through the screens that become App Store screenshots and attaches each one to the
/// result bundle, where the shared `screenshots` runner collects them.
///
/// One test rather than one per screen: the shots are a walk through a single launch, and splitting
/// them would pay the launch every time. This app is one screen, so the walk is short — a loaded
/// spritesheet, then the drop target it starts from. Nothing is tapped along the way, which is why
/// there is none of the click-retry machinery a navigating walk needs on Mac Catalyst.
@MainActor
final class ScreenshotTests: XCTestCase {
    
    private var app: XCUIApplication!
    
    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        launch(arguments: ["-screenshotMode"])
        // The seeded sheet is the only image in the app, and it arrives with the launch rather than
        // after one — so its presence is what says the seed landed.
        let spritesheet = app.images["Spritesheet"]
        XCTAssertTrue(spritesheet.waitForExistence(timeout: 60),
                      "seeded content never appeared\n\(app.debugDescription)")
        // 112x80 of 16x16 sprites. A different number here means the sheet came back at the wrong
        // scale, which the shot would show as the wrong sprite size rather than as a missing image.
        XCTAssertEqual(app.textFields["Columns"].value as? String, "7",
                       "the demo sheet did not divide into 7 columns — is the asset still single scale?")
        settle()
        capture("01-spritesheet")
        
        // Relaunched rather than cleared: the Clear button is iOS-only, and passing the argument
        // keeps the Mac window pinned to the size the shot before it used.
        launch(arguments: ["-screenshotMode", "-screenshotEmptyState"])
        XCTAssertTrue(app.staticTexts["Drop spritesheet here"].waitForExistence(timeout: 30),
                      "the drop target never appeared\n\(app.debugDescription)")
        settle()
        capture("02-drop")
    }
    
    // MARK: - Driving
    
    private func launch(arguments: [String]) {
        app.terminate()
        app.launchArguments = arguments
        app.launch()
        bringToFront()
    }
    
    /// Makes the app's window key before photographing it.
    ///
    /// A Mac window that is not frontmost comes back `Disabled` in the element tree. Nothing steals
    /// focus on a simulator, so this is a Mac-only concern.
    private func bringToFront() {
        #if os(macOS)
        app.activate()
        #endif
    }
    
    /// Animations have no element to wait on, so the shots pause instead.
    private func settle(seconds: TimeInterval = 2) {
        Thread.sleep(forTimeInterval: seconds)
    }
    
    // MARK: - Capturing
    
    private func capture(_ name: String) {
        #if os(macOS) || targetEnvironment(macCatalyst) || os(visionOS)
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
        attach(XCTAttachment(screenshot: XCUIScreen.main.screenshot()), named: name)
        #endif
    }
    
    private func attach(_ attachment: XCTAttachment, named name: String) {
        attachment.name = name
        attachment.lifetime = .keepAlways // attachments on a passing test are discarded otherwise
        add(attachment)
    }
    
    #if os(macOS) || targetEnvironment(macCatalyst) || os(visionOS)
    
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
