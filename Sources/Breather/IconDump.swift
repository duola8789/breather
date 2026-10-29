import AppKit
import BreatherCore

enum IconDump {
    static func run(directory: String) -> Int32 {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

        let cases: [(name: String, progress: Double, phase: Phase, isPaused: Bool)] = [
            ("work-25", 0.25, .work, false),
            ("work-75", 0.75, .work, false),
            ("rest-50", 0.5, .rest, false),
            ("paused-50", 0.5, .work, true),
        ]

        for dark in [false, true] {
            let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
            for item in cases {
                let icon = StatusIconRenderer.pie(
                    progress: item.progress,
                    isPaused: item.isPaused
                )
                let scale: CGFloat = 8
                let outputSize = NSSize(width: icon.size.width * scale, height: icon.size.height * scale)
                let output = NSImage(size: outputSize)

                output.lockFocus()
                appearance?.performAsCurrentDrawingAppearance {
                    (dark ? NSColor.black : NSColor.white).setFill()
                    let rect = NSRect(origin: .zero, size: outputSize)
                    rect.fill()

                    let ctx = NSGraphicsContext.current?.cgContext
                    ctx?.beginTransparencyLayer(auxiliaryInfo: nil)
                    icon.draw(in: rect)
                    (dark ? NSColor.white : NSColor.black).setFill()
                    rect.fill(using: .sourceIn)
                    ctx?.endTransparencyLayer()
                }
                output.unlockFocus()

                guard
                    let tiff = output.tiffRepresentation,
                    let rep = NSBitmapImageRep(data: tiff),
                    let png = rep.representation(using: .png, properties: [:])
                else { continue }

                let name = "\(dark ? "dark" : "light")-\(item.name).png"
                try? png.write(to: URL(fileURLWithPath: directory).appendingPathComponent(name))
            }
        }

        print("wrote icon dumps to \(directory)")
        return 0
    }
}
