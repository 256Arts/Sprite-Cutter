import SwiftUI

struct CutterView: View, DropDelegate {

    /// Desktop lays the cutter's controls out as a compact inspector rather than as the large
    /// touch controls an iPhone needs.
    #if os(macOS)
    let isDesktop = true
    #else
    let isDesktop = false
    #endif
    
    @State var cutter = Cutter(image: ScreenshotMode.demoSpritesheet) // nil unless launched with -screenshotMode
    
    @State var showingImport = false
    @State var showingImportError = false
    @State var showingExport = false
    @State var showingExportError = false
    
    var body: some View {
        VStack {
            ZStack {
                Color.clear
                if let image = cutter.image {
                    // At 1× so one source pixel maps to one point before `.resizable()` scales it.
                    Image(image, scale: 1, label: Text("Spritesheet"))
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
            #if os(macOS)
            Divider()
            #endif
            VStack {
                HStack {
                    Text("Sprite Size:")
                        .font(Font.system(size: isDesktop ? 13 : 18, weight: isDesktop ? .regular : .bold))
                        .foregroundStyle(isDesktop ? Color.secondary : Color.primary)
                    Spacer()
                    IntField(title: "Width", value: $cutter.spriteSize.width)
                    Text("x")
                        .foregroundStyle(.secondary)
                    IntField(title: "Height", value: $cutter.spriteSize.height)
                }
                HStack {
                    Text("Number of Sprites:")
                        .font(Font.system(size: isDesktop ? 13 : 18, weight: isDesktop ? .regular : .bold))
                        .foregroundStyle(isDesktop ? Color.secondary : Color.primary)
                    Spacer()
                    IntField(title: "Columns", value: $cutter.spriteCounts.x)
                    Text("x")
                        .foregroundStyle(.secondary)
                    IntField(title: "Rows", value: $cutter.spriteCounts.y)
                }
                HStack {
                    Text("Spacing:")
                        .font(Font.system(size: isDesktop ? 13 : 18, weight: isDesktop ? .regular : .bold))
                        .foregroundStyle(isDesktop ? Color.secondary : Color.primary)
                    Spacer()
                    #if os(macOS)
                    IntField(title: "Spacing", value: $cutter.spacing)
                    #else
                    Text("\(cutter.spacing)")
                    Stepper("Spacing", value: $cutter.spacing)
                        .labelsHidden()
                    #endif
                }
            }
            .padding()
            #if os(macOS)
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
            // The Mac keeps a bare title bar: its drop target imports on click, and its links live in
            // the Help menu.
            #if !os(macOS)
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
        .focusedSceneValue(\.showingImport, $showingImport)
        .fileImporter(isPresented: $showingImport, allowedContentTypes: [.image], onCompletion: { result in
            guard let url = try? result.get(), url.startAccessingSecurityScopedResource(), let image = CGImage.loading(contentsOf: url) else {
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
            documents.append(.init(image: image, filename: "Sprite \(index + 1)"))
        }
        return documents
    }
    
    func performDrop(info: DropInfo) -> Bool {
        let items = info.itemProviders(for: [.image])
        for item in items {
            item.loadObject(ofClass: PlatformImage.self) { (image, error) in
                let cgImage = (image as? PlatformImage)?.cgImage
                DispatchQueue.main.async {
                    self.cutter.image = cgImage
                }
            }
        }
        return true
    }
    
}

#Preview {
    CutterView()
}
