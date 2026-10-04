import AppKit

enum IconGenerator {
    static func write(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for size in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let pixels = size * scale
                let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                              isPlanar: false, colorSpaceName: .deviceRGB,
                                              bytesPerRow: 0, bitsPerPixel: 0)!
                let context = NSGraphicsContext(bitmapImageRep: bitmap)!
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = context
                context.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
                draw()
                NSGraphicsContext.restoreGraphicsState()
                let suffix = scale == 2 ? "@2x" : ""
                let url = directory.appendingPathComponent("icon_\(size)x\(size)\(suffix).png")
                try bitmap.representation(using: .png, properties: [:])!.write(to: url)
            }
        }
    }

    private static func draw() {
        let square = NSBezierPath(roundedRect: NSRect(x: 56, y: 56, width: 912, height: 912), xRadius: 220, yRadius: 220)
        NSGradient(starting: NSColor(red: 0.13, green: 0.16, blue: 0.20, alpha: 1),
                   ending: NSColor(red: 0.035, green: 0.04, blue: 0.065, alpha: 1))!
            .draw(in: square, angle: 70)
        let accent = NSColor(red: 0.65, green: 0.96, blue: 0.82, alpha: 1)
        let lilac = NSColor(red: 0.76, green: 0.72, blue: 1, alpha: 1)
        for (index, y) in [CGFloat(285), 400, 515].enumerated() {
            let rect = NSRect(x: 242, y: y, width: 540, height: 174)
            let layer = NSBezierPath(roundedRect: rect, xRadius: 56, yRadius: 56)
            (index == 2 ? accent.withAlphaComponent(0.16) : lilac.withAlphaComponent(0.05 + Double(index) * 0.06)).setFill()
            layer.fill()
            (index == 2 ? accent : lilac.withAlphaComponent(0.32 + Double(index) * 0.17)).setStroke()
            layer.lineWidth = index == 2 ? 12 : 8
            layer.stroke()
        }
        let check = NSBezierPath()
        check.move(to: NSPoint(x: 426, y: 604))
        check.line(to: NSPoint(x: 487, y: 554))
        check.line(to: NSPoint(x: 600, y: 656))
        check.lineWidth = 23
        check.lineCapStyle = .round
        check.lineJoinStyle = .round
        accent.setStroke()
        check.stroke()
        accent.setFill()
        NSBezierPath(ovalIn: NSRect(x: 490, y: 769, width: 44, height: 44)).fill()
    }
}
