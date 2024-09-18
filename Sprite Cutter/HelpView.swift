//
//  HelpView.swift
//  Sprite Cutter
//
//  Created by 256 Arts Developer on 2021-04-12.
//

import SwiftUI
import StoreKit

enum AppID: Int {
    case spritePencil = 1437835952
}

struct HelpView: View {
    
    #if os(iOS)
    let appStoreVC: SKStoreProductViewController = {
        let vc = SKStoreProductViewController()
        vc.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: AppID.spritePencil.rawValue]) { (result, error) in
            print(error?.localizedDescription)
        }
        return vc
    }()
    #endif
    
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                #if os(iOS)
                Button {
                    #if targetEnvironment(macCatalyst)
                    openURL(URL(string: "https://apps.apple.com/app/sprite-pencil/id\(AppID.spritePencil.rawValue)")!)
                    #else
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        scene.windows.first?.rootViewController?.present(appStoreVC, animated: true)
                    }
                    #endif
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Try Sprite Pencil")
                                .foregroundColor(Color(UIColor.label))
                            Text("Create Pixel Art")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    } icon: {
                        Image(systemName: "arrow.down.app")
                            .imageScale(.large)
                            .foregroundColor(.accentColor)
                    }
                }
                #endif
                
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
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .imageScale(.large)
    }
}

#Preview {
    HelpView()
}
