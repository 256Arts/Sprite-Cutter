//
//  Sprite_CutterApp.swift
//  Sprite Cutter
//
//  Created by 256 Arts Developer on 2021-04-11.
//

import SwiftUI

enum AppID: Int {
    case spritePencil = 1437835952
}

@main
struct Sprite_CutterApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CutterView()
            }
        }
        .defaultSize(width: 500, height: 650)
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
