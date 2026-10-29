import AppKit

/// Draws the application icon: the same pie as the menu bar, on a rounded
/// plate. The app had no icon at all, which left system alerts and Finder
/// showing an empty placeholder.
enum AppIconRenderer {
    static func image(size: CGFloat) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let inset = rect.width * 0.09
            let plate = NSBezierPath(
                roundedRect: rect.insetBy(dx: inset, dy: inset),
                xRadius: rect.width * 0.22,
                yRadius: rect.width * 0.22
            )
            NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
            plate.fill()

            NSColor(calibratedWhite: 1, alpha: 0.08).setStroke()
            plate.lineWidth = max(1, rect.width * 0.006)
            plate.stroke()

            let center = NSPoint(x: rect.midX, y: rect.midY)
            let radius = rect.width * 0.30
            let wedge = NSBezierPath()
            wedge.move(to: center)
            wedge.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - 360 * 0.72, clockwise: true)
            wedge.close()
            NSColor(calibratedRed: 0.20, green: 0.78, blue: 0.45, alpha: 1).setFill()
            wedge.fill()

            let ring = NSBezierPath()
            ring.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
            ring.lineWidth = max(1, rect.width * 0.012)
            NSColor(calibratedWhite: 1, alpha: 0.22).setStroke()
            ring.stroke()
            return true
        }
    }

    /// Writes an .iconset folder that `iconutil` can turn into an .icns.
    static func writeIconset(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let variants: [(name: String, points: CGFloat)] = [
            ("icon_16x16", 16), ("icon_16x16@2x", 32),
            ("icon_32x32", 32), ("icon_32x32@2x", 64),
            ("icon_128x128", 128), ("icon_128x128@2x", 256),
            ("icon_256x256", 256), ("icon_256x256@2x", 512),
            ("icon_512x512", 512), ("icon_512x512@2x", 1024),
        ]
        for variant in variants {
            let image = image(size: variant.points)
            guard
                let tiff = image.tiffRepresentation,
                let rep = NSBitmapImageRep(data: tiff),
                let png = rep.representation(using: .png, properties: [:])
            else { continue }
            try png.write(to: directory.appendingPathComponent("\(variant.name).png"))
        }
    }
}
