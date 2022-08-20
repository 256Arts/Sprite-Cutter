//
//  HelpView.swift
//  Sprite Cutter
//
//  Created by Jayden Irwin on 2021-04-12.
//

import SwiftUI
import StoreKit

enum AppID: Int {
    case spritePencil = 1437835952
    case spriteFonts = 1554027877
}

struct HelpView: View {
    
    let appStoreVC: SKStoreProductViewController = {
        let vc = SKStoreProductViewController()
        vc.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: AppID.spritePencil.rawValue]) { (result, error) in
            print(error?.localizedDescription)
        }
        return vc
    }()
    let appStoreVC2: SKStoreProductViewController = {
        let vc = SKStoreProductViewController()
        vc.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: AppID.spriteFonts.rawValue]) { (result, error) in
            print(error?.localizedDescription)
        }
        return vc
    }()
    
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
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
                Button {
                    #if targetEnvironment(macCatalyst)
                    openURL(URL(string: "https://apps.apple.com/app/sprite-fonts/id\(AppID.spriteFonts.rawValue)")!)
                    #else
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        scene.windows.first?.rootViewController?.present(appStoreVC2, animated: true)
                    }
                    #endif
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Try Sprite Fonts")
                                .foregroundColor(Color(UIColor.label))
                            Text("Install Pixel Fonts")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    } icon: {
                        Image(systemName: "arrow.down.app")
                            .imageScale(.large)
                            .foregroundColor(.accentColor)
                    }
                }
                Link("Developer Website", destination: URL(string: "https://www.jaydenirwin.com/")!)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Help")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .imageScale(.large)
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
