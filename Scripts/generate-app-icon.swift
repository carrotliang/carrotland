import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Package the selected artwork as the app's opaque 1024-pixel icon.
let output = CommandLine.arguments.dropFirst().first ?? "ClockApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let input = CommandLine.arguments.dropFirst(2).first ?? "docs/design/dynamic-carrot-icon-v1.png"
guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: input) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Unable to read icon artwork: \(input)")
}
precondition(image.width == image.height, "Icon artwork must be square")
let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                        bytesPerRow: 4096, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(red: 1, green: 0.97, blue: 0.88, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
context.interpolationQuality = .high
context.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL,
                                                UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
print("Generated \(output) from \(input)")
