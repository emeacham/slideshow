#!/usr/bin/env swift
import CoreGraphics
import Foundation
import ImageIO

func px(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

func grad(_ colors: [CGColor], _ stops: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: stops)!
}

func makeCtx(_ size: Int) -> CGContext {
    CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue
    )!
}

func drawIcon(_ ctx: CGContext, _ s: CGFloat) {
    let cx = s * 0.435, cy = s * 0.52, lr = s * 0.33
    let lb = CGRect(x: cx - lr, y: cy - lr, width: lr * 2, height: lr * 2)

    ctx.saveGState()

    // Clip everything to the macOS rounded-rect icon shape
    ctx.addPath(CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
        cornerWidth: s * 0.225, cornerHeight: s * 0.225, transform: nil
    ))
    ctx.clip()

    // Dark navy background
    ctx.drawLinearGradient(
        grad([px(0.08, 0.10, 0.20), px(0.03, 0.03, 0.09)], [0, 1]),
        start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: []
    )

    // Handle — drawn before the ring so the ring overlaps the joint cleanly.
    // Ring edge at 45° below-right of lens center.
    let hx = cx + lr * cos(-CGFloat.pi / 4)
    let hy = cy + lr * sin(-CGFloat.pi / 4)
    let hw = s * 0.115
    let hl = s * 0.30

    ctx.saveGState()
    ctx.translateBy(x: hx, y: hy)
    ctx.rotate(by: -CGFloat.pi / 4)
    // After -π/4 rotation, local +x points toward screen lower-right.
    // Draw the pill horizontally in local space; rotation does the orientation work.
    ctx.addPath(CGPath(
        roundedRect: CGRect(x: hw * 0.15, y: -hw / 2, width: hl, height: hw),
        cornerWidth: hw / 2, cornerHeight: hw / 2, transform: nil
    ))
    ctx.clip()
    ctx.drawLinearGradient(
        grad([px(0.92, 0.84, 0.48), px(0.68, 0.54, 0.22), px(0.44, 0.34, 0.12)], [0, 0.5, 1]),
        start: CGPoint(x: 0, y: -hw / 2), end: CGPoint(x: 0, y: hw / 2), options: []
    )
    ctx.restoreGState()

    // Lens scene — sky-to-ground gradient evoking a photo viewed through glass
    ctx.saveGState()
    ctx.addPath(CGPath(ellipseIn: lb, transform: nil))
    ctx.clip()

    ctx.drawLinearGradient(
        grad(
            [px(0.15, 0.42, 0.82), px(0.90, 0.53, 0.18), px(0.80, 0.26, 0.20), px(0.16, 0.11, 0.25)],
            [0, 0.45, 0.62, 1]
        ),
        start: CGPoint(x: cx, y: cy + lr), end: CGPoint(x: cx, y: cy - lr), options: []
    )

    // Sun glow near the horizon
    let sc = CGPoint(x: cx + s * 0.02, y: cy + s * 0.01)
    ctx.drawRadialGradient(
        grad([px(1, 0.95, 0.72, 0.80), px(1, 0.70, 0.20, 0.28), px(1, 0.50, 0.10, 0)], [0, 0.25, 1]),
        startCenter: sc, startRadius: 0,
        endCenter: sc, endRadius: s * 0.20,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    // Concentric optic rings — subtle glass-lens texture
    ctx.setStrokeColor(px(1, 1, 1, 0.055))
    ctx.setLineWidth(s * 0.005)
    for i in 1...3 {
        let r = lr * (0.44 + CGFloat(i) * 0.17)
        ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }

    // Glass glare — top-left reflection highlight
    let gc = CGPoint(x: cx - lr * 0.27, y: cy + lr * 0.29)
    ctx.drawRadialGradient(
        grad([px(1, 1, 1, 0.38), px(1, 1, 1, 0)], [0, 1]),
        startCenter: gc, startRadius: 0,
        endCenter: gc, endRadius: lr * 0.52, options: []
    )

    ctx.restoreGState()

    // Gold metallic ring with drop-shadow
    ctx.setStrokeColor(px(0, 0, 0, 0.42))
    ctx.setLineWidth(s * 0.058)
    ctx.strokeEllipse(in: lb)

    ctx.setStrokeColor(px(0.78, 0.65, 0.28))
    ctx.setLineWidth(s * 0.040)
    ctx.strokeEllipse(in: lb)

    ctx.setStrokeColor(px(0.98, 0.92, 0.68, 0.55))
    ctx.setLineWidth(s * 0.007)
    ctx.strokeEllipse(in: lb.insetBy(dx: s * 0.016, dy: s * 0.016))

    // Lens-flare sparkle dots near the handle
    for (fx, fy, fr): (CGFloat, CGFloat, CGFloat) in [(0.74, 0.26, 0.017), (0.79, 0.33, 0.010), (0.70, 0.21, 0.007)] {
        let r = s * fr
        ctx.setFillColor(px(1.0, 0.96, 0.82, 0.78))
        ctx.fillEllipse(in: CGRect(x: s * fx - r, y: s * fy - r, width: r * 2, height: r * 2))
    }

    ctx.restoreGState()
}

func savePNG(_ ctx: CGContext, to path: String) {
    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, "public.png" as CFString, 1, nil)
    else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let iconsetDir = "Resources/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Each entry: (render size, iconset filename). Two entries may share the same render size.
let entries: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

var cache = [Int: CGContext]()
for (size, filename) in entries {
    if cache[size] == nil {
        let c = makeCtx(size)
        drawIcon(c, CGFloat(size))
        cache[size] = c
    }
    savePNG(cache[size]!, to: "\(iconsetDir)/\(filename)")
    print("  \(filename)")
}
print("Iconset ready at \(iconsetDir)")
