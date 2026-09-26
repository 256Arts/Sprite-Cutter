import SwiftUI
import ImageIO
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
/// The platform's image type.
///
/// Sprite pixels travel as `CGImage`, which is identical on every platform; this alias exists only
/// for the few UIKit/AppKit boundaries that still demand a platform image (asset-catalog lookup,
/// `NSItemProvider`).
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformImage = NSImage

extension NSImage {
    /// Matches `UIImage.cgImage`, so shared code can ask either platform's image for its pixels.
    var cgImage: CGImage? {
        cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}
#endif

enum ImageEditError: Error {
    case failedToEncodePNG
}

extension CGImage {

    /// Loads pixels from a file on disk.
    static func loading(contentsOf url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    /// Loads pixels from encoded image data.
    static func loading(data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    /// Looks up a bundled asset-catalog image — the one lookup that still needs a platform image.
    static func named(_ name: String) -> CGImage? {
        PlatformImage(named: name)?.cgImage
    }

    /// PNG-encodes the pixels at their native size, with no rescaling.
    func pngData() throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw ImageEditError.failedToEncodePNG
        }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ImageEditError.failedToEncodePNG
        }
        return data as Data
    }

}
