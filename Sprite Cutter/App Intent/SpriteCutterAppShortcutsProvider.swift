import AppIntents

struct SpriteCutterAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CutSprites(),
            phrases: [
                "Cut sprites with \(.applicationName)",
                "Cut spritesheet with \(.applicationName)"
            ],
            shortTitle: "Cut Sprites",
            systemImageName: "scissors"
        )
    }
    static var shortcutTileColor: ShortcutTileColor = .orange
}
