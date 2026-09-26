import SwiftUI

enum AppID: Int {
    case spritePencil = 1437835952
}

@main
struct Sprite_CutterApp: App {
    
    @State private var showingEvent = false
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CutterView()
            }
            .alert("Event Intro", isPresented: $showingEvent) {
                Button("OK", role: .close) { }
            } message: {
                Text("Now let's celebrate by dropping in a spritesheet and trying out the new features!")
            }
            .onOpenURL { url in
                if url.path().contains("spritecutter/appstoreevent") {
                    showingEvent = true
                }
            }
            .screenshotWindowSize()   // a no-op unless launched with -screenshotMode
            .screenshotModeStatus()   // a no-op unless launched with -screenshotMode
        }
        .defaultSize(width: 500, height: 650)
        #if os(macOS)
        // `.contentSize` only for a screenshot run, where `screenshotWindowSize()` has fixed the
        // content and the window has to take it.
        .windowResizability(ScreenshotMode.isActive ? .contentSize : .automatic)
        .restorationBehavior(ScreenshotMode.isActive ? .disabled : .automatic)
        #endif
        .commands {
            CommandGroup(after: .help) {
                Self.links()
            }
        }
    }
    
    @ViewBuilder
    static func links() -> some View {
        Link(destination: URL(string: "https://www.256arts.com/")!) {
            Label("Developer Website", systemImage: "safari")
        }
        Link(destination: URL(string: "https://www.256arts.com/joincommunity/")!) {
            Label("Join Community", systemImage: "bubble.left.and.bubble.right")
        }
        Link(destination: URL(string: "https://github.com/256Arts/Sprite-Cutter")!) {
            Label("Contribute on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
        }
    }
    
}
