import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// A vector clock mark rendered into the app's standard 1024-point icon.
let output = CommandLine.arguments.dropFirst().first ?? "ClockApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                        bytesPerRow: 4096, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(red: 0.025, green: 0.24, blue: 0.50, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.setLineWidth(44)
context.strokeEllipse(in: CGRect(x: 184, y: 184, width: 656, height: 656))
context.setLineWidth(48)
context.setLineCap(.round)
context.setLineJoin(.round)
context.move(to: CGPoint(x: 512, y: 714))
context.addLine(to: CGPoint(x: 512, y: 512))
context.addLine(to: CGPoint(x: 660, y: 424))
context.strokePath()
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL,
                                                UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
