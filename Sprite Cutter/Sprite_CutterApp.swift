//
//  Sprite_CutterApp.swift
//  Sprite Cutter
//
//  Created by 256 Arts Developer on 2021-04-11.
//

import SwiftUI

@main
struct Sprite_CutterApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CutterView()
            }
        }
        .defaultSize(CGSize(width: 480, height: 700))
    }
}
