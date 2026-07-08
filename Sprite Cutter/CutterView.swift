//
//  CutterView.swift
//  Sprite Cutter
//
//  Created by 256 Arts Developer on 2021-04-11.
//

import SwiftUI

struct CutterView: View, DropDelegate {

    #if targetEnvironment(macCatalyst)
    let isCatalyst = true
    #else
    let isCatalyst = false
    #endif
    
    #if targetEnvironment(macCatalyst)
    @Environment(\.openURL) private var openURL
    #endif
    
    @State var cutter = Cutter()
    
    @State var showingImport = false
    @State var showingImportError = false
    @State var showingExport = false
    @State var showingExportError = false
    
    var body: some View {
        VStack {
            ZStack {
                Color.clear
                if let image = cutter.image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(Font.system(size: 100, weight: .medium))
                        Text("Drop spritesheet here")
                            .bold()
                    }
                        .foregroundStyle(.secondary)
                        .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
                }
            }
            .onTapGesture {
                showingImport = true
            }
            .onDrop(of: [.image], delegate: self)
            #if targetEnvironment(macCatalyst)
            Divider()
            #endif
            VStack {
                HStack {
                    Text("Sprite Size:")
                        .font(Font.system(size: isCatalyst ? 13 : 18, weight: isCatalyst ? .regular : .bold))
                        .foregroundStyle(isCatalyst ? Color.secondary : Color.primary)
                    Spacer()
                    IntField(title: "Width", value: $cutter.spriteSize.width)
                    Text("x")
                        .foregroundStyle(.secondary)
                    IntField(title: "Height", value: $cutter.spriteSize.height)
                }
                HStack {
                    Text("Number of Sprites:")
                        .font(Font.system(size: isCatalyst ? 13 : 18, weight: isCatalyst ? .regular : .bold))
                        .foregroundStyle(isCatalyst ? Color.secondary : Color.primary)
                    Spacer()
                    IntField(title: "Columns", value: $cutter.spriteCounts.x)
                    Text("x")
                        .foregroundStyle(.secondary)
                    IntField(title: "Rows", value: $cutter.spriteCounts.y)
                }
                HStack {
                    Text("Spacing:")
                        .font(Font.system(size: isCatalyst ? 13 : 18, weight: isCatalyst ? .regular : .bold))
                        .foregroundStyle(isCatalyst ? Color.secondary : Color.primary)
                    Spacer()
                    #if targetEnvironment(macCatalyst)
                    IntField(title: "Spacing", value: $cutter.spacing)
                    #else
                    Text("\(cutter.spacing)")
                    Stepper("Spacing", value: $cutter.spacing)
                        .labelsHidden()
                    #endif
                }
            }
            .padding()
            #if targetEnvironment(macCatalyst)
            Divider()
            HStack {
                Spacer()
                Button("Cut", systemImage: "scissors") {
                    showingExport = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!cutter.canCut)
            }
            .padding()
            #else
            Button {
                showingExport = true
            } label: {
                Label("Cut", systemImage: "scissors")
                    .font(.headline)
                    .frame(idealWidth: .infinity, maxWidth: .infinity)
            }
            #if os(visionOS)
            .buttonStyle(.borderedProminent)
            #else
            .buttonStyle(.glassProminent)
            #endif
            .controlSize(.large)
            .disabled(!cutter.canCut)
            .padding()
            #endif
        }
        .toolbar {
            #if !targetEnvironment(macCatalyst)
            ToolbarItem(placement: .topBarPinnedTrailing) {
                Button("Import Spritesheet", systemImage: "square.and.arrow.down") {
                    showingImport = true
                }
            }
            ToolbarItem {
                Button("Clear", systemImage: "xmark") {
                    cutter.image = nil
                }
                .disabled(cutter.image == nil)
            }
            #if os(iOS)
            .visibilityPriority(.low)
            #endif
            ToolbarOverflowMenu {
                Sprite_CutterApp.links()
            }
            #endif
        }
        .fileImporter(isPresented: $showingImport, allowedContentTypes: [.image], onCompletion: { result in
            guard let url = try? result.get(), url.startAccessingSecurityScopedResource(), let image = UIImage(contentsOfFile: url.path) else {
                showingImportError = true
                return
            }
            url.stopAccessingSecurityScopedResource()
            cutter.image = image
        })
        .fileExporter(isPresented: $showingExport, documents: (try? cutDocuments()) ?? [], contentType: .png) { result in
            //
        }
        .alert("Import Error", isPresented: $showingImportError) {
            Button("OK") { }
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK") { }
        }
    }
    
    func cutDocuments() throws -> [ImageDocument] {
        var documents: [ImageDocument] = []
        for (index, image) in try cutter.cut().enumerated() {
            documents.append(.init(image: image, number: index + 1))
        }
        return documents
    }
    
    func performDrop(info: DropInfo) -> Bool {
        let items = info.itemProviders(for: [.image])
        for item in items {
            item.loadObject(ofClass: UIImage.self) { (image, error) in
                DispatchQueue.main.async {
                    self.cutter.image = image as? UIImage
                }
            }
        }
        return true
    }
    
}

#Preview {
    CutterView()
}
