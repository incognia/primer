// Genera app.icns a partir de un PNG cuadrado: lo recorta al cuerpo redondeado de ícono de macOS (824/1024) con margen transparente.
// Uso (desde la raíz del repositorio): swiftc shared/scripts/make-icon.swift -o /tmp/make-icon && /tmp/make-icon shared/assets/icon.png macos/Primer.app/Contents/Resources/app.icns
import Cocoa

let args = CommandLine.arguments
guard args.count == 3, let img = NSImage(contentsOfFile: args[1]) else { print("uso: make-icon <origen.png> <destino.icns>"); exit(1) }

let iconset = NSTemporaryDirectory() + "primer.iconset"
try? FileManager.default.removeItem(atPath: iconset)
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

for (s, scale) in [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)] {
    let px = s * scale
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    let body = CGFloat(px) * 824 / 1024
    let rect = NSRect(x: (CGFloat(px) - body) / 2, y: (CGFloat(px) - body) / 2, width: body, height: body)
    let r = body * 0.2237
    NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r).addClip()
    img.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
    let name = "icon_\(s)x\(s)" + (scale == 2 ? "@2x" : "") + ".png"
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: iconset + "/" + name))
}

let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset, "-o", args[2]]
try! p.run(); p.waitUntilExit()
exit(p.terminationStatus)
