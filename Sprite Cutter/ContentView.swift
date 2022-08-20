//
//  ContentView.swift
//  Sprite Cutter
//
//  Created by Jayden Irwin on 2021-04-11.
//

import SwiftUI
import JaydenCodeGenerator

struct ContentView: View, DropDelegate {
    
    #if targetEnvironment(macCatalyst)
    let isCatalyst = true
    #else
    let isCatalyst = false
    #endif
    
    @State var cutter = Cutter()
    
    @State var showingImport = false
    @State var showingImportError = false
    @State var showingExport = false
    @State var showingExportError = false
    @State var showingHelp = false
    @State var showingJaydenCode = false
    
    var jaydenCode: String {
        JaydenCodeGenerator.generateCode(secret: "QXC2HFR010")
    }
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(.clear)
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
                        .foregroundColor(Color(UIColor.secondaryLabel))
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
                        .foregroundColor(Color(isCatalyst ? UIColor.secondaryLabel : UIColor.label))
                    Spacer()
                    IntField(title: "Width", value: $cutter.spriteSize.width)
                    Text("x")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    IntField(title: "Height", value: $cutter.spriteSize.height)
                }
                HStack {
                    Text("Number of Sprites:")
                        .font(Font.system(size: isCatalyst ? 13 : 18, weight: isCatalyst ? .regular : .bold))
                        .foregroundColor(Color(isCatalyst ? UIColor.secondaryLabel : UIColor.label))
                    Spacer()
                    IntField(title: "Columns", value: $cutter.spriteCounts.x)
                    Text("x")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    IntField(title: "Rows", value: $cutter.spriteCounts.y)
                }
                HStack {
                    Text("Spacing:")
                        .font(Font.system(size: isCatalyst ? 13 : 18, weight: isCatalyst ? .regular : .bold))
                        .foregroundColor(Color(isCatalyst ? UIColor.secondaryLabel : UIColor.label))
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
                Button("Cut") {
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
                Text("Cut")
                    .font(.headline)
                    .frame(idealWidth: .infinity, maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!cutter.canCut)
            .padding()
            #endif
        }
        .toolbar {
            Button {
                showingHelp = true
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .imageScale(.large)
        }
        #if targetEnvironment(macCatalyst)
        .navigationBarHidden(true)
        #endif
        .onChange(of: cutter.spacing, perform: { newValue in
            if newValue == 1138 {
                showingJaydenCode = true
            }
        })
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
        .sheet(isPresented: $showingHelp, content: {
            HelpView()
        })
        .alert("Secret Code: \(jaydenCode)", isPresented: $showingJaydenCode) {
            Button("Copy") {
                UIPasteboard.general.string = jaydenCode
            }
            Button("OK", role: .cancel, action: { })
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
