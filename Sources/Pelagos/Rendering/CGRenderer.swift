#if canImport(CoreGraphics)
import Foundation
import CoreGraphics
import CoreText
import ImageIO

/// A CoreGraphics-based renderer for SVG content
public final class CGRenderer: SVGRenderer {
    private let context: CGContext

    public init(context: CGContext) {
        self.context = context
    }

    // MARK: - Path Construction

    public func makePath() -> CGMutablePath {
        CGMutablePath()
    }

    public func moveTo(_ path: inout CGMutablePath, x: Double, y: Double) {
        path.move(to: CGPoint(x: x, y: y))
    }

    public func lineTo(_ path: inout CGMutablePath, x: Double, y: Double) {
        path.addLine(to: CGPoint(x: x, y: y))
    }

    public func curveTo(_ path: inout CGMutablePath, cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) {
        path.addCurve(
            to: CGPoint(x: x, y: y),
            control1: CGPoint(x: cp1x, y: cp1y),
            control2: CGPoint(x: cp2x, y: cp2y)
        )
    }

    public func quadTo(_ path: inout CGMutablePath, cpx: Double, cpy: Double, x: Double, y: Double) {
        path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cpx, y: cpy))
    }

    public func closePath(_ path: inout CGMutablePath) {
        path.closeSubpath()
    }

    public func addRect(_ path: inout CGMutablePath, x: Double, y: Double, width: Double, height: Double, rx: Double, ry: Double) {
        if rx <= 0 && ry <= 0 {
            path.addRect(CGRect(x: x, y: y, width: width, height: height))
        } else {
            path.addRoundedRect(
                in: CGRect(x: x, y: y, width: width, height: height),
                cornerWidth: min(rx, width / 2),
                cornerHeight: min(ry, height / 2)
            )
        }
    }

    public func addEllipse(_ path: inout CGMutablePath, cx: Double, cy: Double, rx: Double, ry: Double) {
        path.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    // MARK: - Color Conversion

    public func makeColor(from resolved: ResolvedColor) -> CGColor {
        switch resolved.colorSpace {
        case .sRGB:
            return CGColor(
                red: CGFloat(resolved.red),
                green: CGFloat(resolved.green),
                blue: CGFloat(resolved.blue),
                alpha: CGFloat(resolved.alpha)
            )
        case .displayP3:
            let space = CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
            let components = [CGFloat(resolved.red), CGFloat(resolved.green), CGFloat(resolved.blue), CGFloat(resolved.alpha)]
            return CGColor(colorSpace: space, components: components)
                ?? CGColor(red: CGFloat(resolved.red), green: CGFloat(resolved.green), blue: CGFloat(resolved.blue), alpha: CGFloat(resolved.alpha))
        }
    }

    // MARK: - Drawing Operations

    public func fill(_ path: CGMutablePath, color: CGColor, rule: FillRule) {
        context.saveGState()
        defer { context.restoreGState() }

        context.addPath(path)
        context.setFillColor(color)

        context.fillPath(using: rule.cgFillRule)
    }

    public func stroke(_ path: CGMutablePath, color: CGColor, style: StrokeStyle) {
        context.saveGState()
        defer { context.restoreGState() }

        context.addPath(path)
        context.setStrokeColor(color)
        context.setLineWidth(CGFloat(style.width))
        context.setMiterLimit(CGFloat(style.miterLimit))
        context.setLineCap(style.cap.cgLineCap)
        context.setLineJoin(style.join.cgLineJoin)

        if let dashArray = style.dashArray, !dashArray.isEmpty {
            context.setLineDash(phase: CGFloat(style.dashOffset), lengths: dashArray.map { CGFloat($0) })
        }

        context.strokePath()
    }

    public func strokeGradient(_ path: CGMutablePath, gradient: ResolvedGradient, style: StrokeStyle) {
        // Convert the stroke to a filled path
        let dashLengths = style.dashArray?.map { CGFloat($0) } ?? []
        let strokedPath = path.copy(
            strokingWithWidth: CGFloat(style.width),
            lineCap: style.cap.cgLineCap,
            lineJoin: style.join.cgLineJoin,
            miterLimit: CGFloat(style.miterLimit),
            transform: .identity
        )

        // Apply dash pattern if present
        let finalPath: CGPath
        if !dashLengths.isEmpty {
            finalPath = strokedPath.copy(dashingWithPhase: CGFloat(style.dashOffset), lengths: dashLengths)
        } else {
            finalPath = strokedPath
        }

        // Fill the stroked path with the gradient
        context.saveGState()
        defer { context.restoreGState() }

        context.addPath(finalPath)
        context.clip()

        let bounds = finalPath.boundingBox
        switch gradient {
        case .linear(let linear):
            drawLinearGradient(linear, bounds: bounds)
        case .radial(let radial):
            drawRadialGradient(radial, bounds: bounds)
        }
    }

    public func fillGradient(_ path: CGMutablePath, gradient: ResolvedGradient, rule: FillRule) {
        context.saveGState()
        defer { context.restoreGState() }

        context.addPath(path)
        context.clip(using: rule.cgFillRule)

        let bounds = path.boundingBox

        switch gradient {
        case .linear(let linear):
            drawLinearGradient(linear, bounds: bounds)
        case .radial(let radial):
            drawRadialGradient(radial, bounds: bounds)
        }
    }

    private func drawLinearGradient(_ linear: ResolvedLinearGradient, bounds: CGRect) {
        guard let cgGradient = createCGGradient(from: linear.stops) else { return }

        var start: CGPoint
        var end: CGPoint

        if linear.gradientUnits == .objectBoundingBox {
            // Transform from 0-1 coordinates to bounding box coordinates
            start = CGPoint(
                x: bounds.minX + linear.startX * bounds.width,
                y: bounds.minY + linear.startY * bounds.height
            )
            end = CGPoint(
                x: bounds.minX + linear.endX * bounds.width,
                y: bounds.minY + linear.endY * bounds.height
            )
        } else {
            start = CGPoint(x: linear.startX, y: linear.startY)
            end = CGPoint(x: linear.endX, y: linear.endY)
        }

        // Apply gradient transform if present
        if let transform = linear.gradientTransform {
            context.concatenate(transform.cgTransform)
        }

        var options: CGGradientDrawingOptions = []
        switch linear.spreadMethod {
        case .pad:
            options = [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        case .reflect, .repeat:
            options = [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        }

        context.drawLinearGradient(cgGradient, start: start, end: end, options: options)
    }

    private func drawRadialGradient(_ radial: ResolvedRadialGradient, bounds: CGRect) {
        guard let cgGradient = createCGGradient(from: radial.stops) else { return }

        var center: CGPoint
        var focal: CGPoint
        var radius: CGFloat

        if radial.gradientUnits == .objectBoundingBox {
            // Transform from 0-1 coordinates to bounding box coordinates
            center = CGPoint(
                x: bounds.minX + radial.centerX * bounds.width,
                y: bounds.minY + radial.centerY * bounds.height
            )
            focal = CGPoint(
                x: bounds.minX + radial.focalX * bounds.width,
                y: bounds.minY + radial.focalY * bounds.height
            )
            // For objectBoundingBox, radius is relative to the normalized space
            // We use the average of width and height for a reasonable approximation
            radius = CGFloat(radial.radius) * max(bounds.width, bounds.height)
        } else {
            center = CGPoint(x: radial.centerX, y: radial.centerY)
            focal = CGPoint(x: radial.focalX, y: radial.focalY)
            radius = CGFloat(radial.radius)
        }

        // Apply gradient transform if present
        if let transform = radial.gradientTransform {
            context.concatenate(transform.cgTransform)
        }

        var options: CGGradientDrawingOptions = []
        switch radial.spreadMethod {
        case .pad:
            options = [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        case .reflect, .repeat:
            options = [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        }

        context.drawRadialGradient(
            cgGradient,
            startCenter: focal,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: options
        )
    }

    private func createCGGradient(from stops: [ResolvedGradientStop]) -> CGGradient? {
        let colors = stops.map { makeColor(from: $0.color) }
        let locations = stops.map { CGFloat($0.offset) }
        return CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: locations)
    }

    public func fillPattern(_ path: CGMutablePath, pattern: ResolvedPattern, rule: FillRule) {
        context.saveGState()
        defer { context.restoreGState() }

        context.addPath(path)
        context.clip(using: rule.cgFillRule)

        // Calculate tile dimensions based on pattern units
        var tileX: CGFloat
        var tileY: CGFloat
        var tileWidth: CGFloat
        var tileHeight: CGFloat
        var tileBounds: CGRect

        if pattern.patternUnits == .objectBoundingBox {
            // Pattern coordinates are fractions of bounding box
            let bounds = path.boundingBox
            tileX = bounds.minX + CGFloat(pattern.tileX) * bounds.width
            tileY = bounds.minY + CGFloat(pattern.tileY) * bounds.height
            tileWidth = CGFloat(pattern.tileWidth) * bounds.width
            tileHeight = CGFloat(pattern.tileHeight) * bounds.height
            tileBounds = bounds

            // Apply pattern transform if any
            if let transform = pattern.transform {
                context.concatenate(transform.cgTransform)
            }
        } else {
            // Pattern coordinates are in user space
            // path.boundingBox is already in the path's local coordinate system (user space)
            tileX = CGFloat(pattern.tileX)
            tileY = CGFloat(pattern.tileY)
            tileWidth = CGFloat(pattern.tileWidth)
            tileHeight = CGFloat(pattern.tileHeight)
            tileBounds = path.boundingBox

            // Apply pattern transform if any
            if let transform = pattern.transform {
                context.concatenate(transform.cgTransform)
            }
        }

        guard tileWidth > 0, tileHeight > 0 else { return }

        let startX = floor((tileBounds.minX - tileX) / tileWidth) * tileWidth + tileX
        let startY = floor((tileBounds.minY - tileY) / tileHeight) * tileHeight + tileY

        // Calculate content scale for objectBoundingBox content units
        let bounds = path.boundingBox
        let contentScaleX: CGFloat = pattern.patternContentUnits == .objectBoundingBox ? bounds.width : 1
        let contentScaleY: CGFloat = pattern.patternContentUnits == .objectBoundingBox ? bounds.height : 1

        var y = startY
        while y < tileBounds.maxY {
            var x = startX
            while x < tileBounds.maxX {
                context.saveGState()
                context.translateBy(x: x, y: y)

                // Scale content for objectBoundingBox content units
                if pattern.patternContentUnits == .objectBoundingBox {
                    context.scaleBy(x: contentScaleX, y: contentScaleY)
                }

                // Render pattern content
                pattern.content.render(with: self)

                context.restoreGState()
                x += tileWidth
            }
            y += tileHeight
        }
    }

    public func drawText(_ text: ResolvedTextContent) {
        context.saveGState()
        defer { context.restoreGState() }

        // Combine all runs into a single string
        let combinedText = text.runs.map { $0.text }.joined()
        guard !combinedText.isEmpty else { return }

        // For simplicity, use the first run's attributes for the entire string
        // A more complete implementation would handle per-run attributes
        let fontSize = CGFloat(text.runs.first?.fontSize ?? 16)
        let fontName = text.runs.first?.fontFamily ?? "Helvetica"
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let color = makeColor(from: text.runs.first?.color ?? .black)

        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: color
        ]

        guard let attrString = CFAttributedStringCreate(
            kCFAllocatorDefault,
            combinedText as CFString,
            attributes as CFDictionary
        ) else { return }

        let line = CTLineCreateWithAttributedString(attrString)
        let typographicBounds = CTLineGetBoundsWithOptions(line, [])

        var xOffset: CGFloat = 0
        switch text.anchor {
        case .start:
            xOffset = 0
        case .middle:
            xOffset = -typographicBounds.width / 2
        case .end:
            xOffset = -typographicBounds.width
        }

        // Move to text position and flip for CoreText
        // We translate to the text position, then flip Y locally so text draws correctly
        context.translateBy(x: CGFloat(text.x) + xOffset, y: CGFloat(text.y))
        context.scaleBy(x: 1, y: -1)

        context.textMatrix = .identity
        context.textPosition = .zero

        CTLineDraw(line, context)
    }

    public func drawImage(_ image: ResolvedImageContent) {
        guard let provider = CGDataProvider(data: image.data as CFData),
              let source = CGImageSourceCreateWithDataProvider(provider, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return
        }

        let rect = CGRect(x: image.x, y: image.y, width: image.width, height: image.height)

        // CGContext draws images upside down, so we need to flip
        context.saveGState()
        defer { context.restoreGState() }

        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
    }

    // MARK: - State Management

    public func save() {
        context.saveGState()
    }

    public func restore() {
        context.restoreGState()
    }

    public func concatenate(_ transform: AffineTransform) {
        context.concatenate(transform.cgTransform)
    }

    public func clip(_ path: CGMutablePath, rule: FillRule) {
        context.addPath(path)
        context.clip(using: rule.cgFillRule)
    }

    public func setOpacity(_ opacity: Double) {
        context.setAlpha(CGFloat(opacity))
    }
}

private extension AffineTransform {
    var cgTransform: CGAffineTransform {
        CGAffineTransform(
            a: CGFloat(a),
            b: CGFloat(b),
            c: CGFloat(c),
            d: CGFloat(d),
            tx: CGFloat(tx),
            ty: CGFloat(ty)
        )
    }
}

private extension FillRule {
    var cgFillRule: CGPathFillRule {
        switch self {
        case .nonzero:
            return .winding
        case .evenodd:
            return .evenOdd
        }
    }
}

private extension LineCap {
    var cgLineCap: CGLineCap {
        switch self {
        case .butt:
            return .butt
        case .round:
            return .round
        case .square:
            return .square
        }
    }
}

private extension LineJoin {
    var cgLineJoin: CGLineJoin {
        switch self {
        case .miter, .miterClip, .arcs:
            return .miter
        case .round:
            return .round
        case .bevel:
            return .bevel
        }
    }
}

// MARK: - Convenience Extension

public extension SVG {
    /// Render this SVG to a CGContext
    func render(to context: CGContext) {
        render(with: CGRenderer(context: context))
    }
}
#endif
