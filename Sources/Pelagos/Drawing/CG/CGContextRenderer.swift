#if canImport(CoreGraphics)
@preconcurrency import CoreGraphics
import Foundation
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(CoreText)
import CoreText
#endif

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
public final class CGContextRenderer: DrawCallback, @unchecked Sendable {
    private let context: CGContext

    public init(context: CGContext) {
        self.context = context
    }

    public func drawRect(_ rect: Rect, resolved: ResolvedRect, context drawContext: DrawContext) -> DrawDirective {
        drawShape(context: context, drawContext: drawContext) {
            let rectFrame = CGRect(
                x: resolved.x,
                y: resolved.y,
                width: resolved.width,
                height: resolved.height
            )
            let cornerX = resolved.rx
            let cornerY = resolved.ry
            if cornerX > 0 || cornerY > 0 {
                $0.addPath(CGPath(roundedRect: rectFrame, cornerWidth: cornerX, cornerHeight: cornerY, transform: nil))
            } else {
                $0.addRect(rectFrame)
            }
        }
    }

    public func drawCircle(_ circle: Circle, resolved: ResolvedCircle, context drawContext: DrawContext) -> DrawDirective {
        drawShape(context: context, drawContext: drawContext) {
            let rect = CGRect(
                x: resolved.cx - resolved.r,
                y: resolved.cy - resolved.r,
                width: resolved.r * 2,
                height: resolved.r * 2
            )
            $0.addEllipse(in: rect)
        }
    }

    public func drawEllipse(_ ellipse: Ellipse, resolved: ResolvedEllipse, context drawContext: DrawContext) -> DrawDirective {
        drawShape(context: context, drawContext: drawContext) {
            let rect = CGRect(
                x: resolved.cx - resolved.rx,
                y: resolved.cy - resolved.ry,
                width: resolved.rx * 2,
                height: resolved.ry * 2
            )
            $0.addEllipse(in: rect)
        }
    }

    public func drawLine(_ line: Line, resolved: ResolvedLine, context drawContext: DrawContext) -> DrawDirective {
        drawShape(context: context, drawContext: drawContext) {
            $0.move(to: CGPoint(x: resolved.x1, y: resolved.y1))
            $0.addLine(to: CGPoint(x: resolved.x2, y: resolved.y2))
        }
    }

    public func drawPolyline(_ polyline: Polyline, resolved: ResolvedPolyline, context drawContext: DrawContext) -> DrawDirective {
        drawShape(context: context, drawContext: drawContext) {
            guard let first = resolved.points.first else { return }
            $0.move(to: CGPoint(x: first.x, y: first.y))
            for point in resolved.points.dropFirst() {
                $0.addLine(to: CGPoint(x: point.x, y: point.y))
            }
        }
    }

    public func drawPolygon(_ polygon: Polygon, resolved: ResolvedPolygon, context drawContext: DrawContext) -> DrawDirective {
        drawShape(context: context, drawContext: drawContext) {
            guard let first = resolved.points.first else { return }
            $0.move(to: CGPoint(x: first.x, y: first.y))
            for point in resolved.points.dropFirst() {
                $0.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            $0.closeSubpath()
        }
    }

    public func drawPath(_ path: Path, context drawContext: DrawContext) -> DrawDirective {
        drawShape(context: context, drawContext: drawContext) {
            $0.addPath(buildPath(from: path.segments))
        }
    }

    public func drawText(_ text: Text, resolved: ResolvedText, context drawContext: DrawContext) -> DrawDirective {
        renderText(context: context, drawContext: drawContext, resolved: resolved)
    }

    public func drawImage(_ image: Image, resolved: ResolvedImage?, layout: ResolvedImageLayout, context drawContext: DrawContext) -> DrawDirective {
        renderImage(context: context, drawContext: drawContext, image: image, resolved: resolved, layout: layout)
    }
}

private func drawShape(
    context: CGContext,
    drawContext: DrawContext,
    draw: (CGMutablePath) -> Void
) -> DrawDirective {
    context.saveGState()
    defer { context.restoreGState() }

    let transform = makeTransform(from: drawContext.transforms)
    context.concatenate(transform)

    let path = CGMutablePath()
    draw(path)
    let bbox = path.boundingBoxOfPath

    if let clipReference = drawContext.presentation.clipPath,
       let clipPath = drawContext.definitions.clipPaths[clipReference],
       let clipShape = buildClipPath(clipPath, definitions: drawContext.definitions, bbox: bbox) {
        context.addPath(clipShape)
        context.clip(using: .winding)
    }

    context.addPath(path)

    let presentation = drawContext.presentation
    let resolvedPaint = drawContext.resolvedPaint
    let fillReference = fillReference(from: presentation.fill)
    let gradient = fillReference.flatMap { drawContext.definitions.gradients[$0] }
    let pattern = fillReference.flatMap { drawContext.definitions.patterns[$0] }
    let shouldFill = shouldFillPath(resolvedPaint, hasFillReference: gradient != nil || pattern != nil)
    let shouldStroke = shouldStrokePath(resolvedPaint)
    let fillRule = resolvedPaint.fillRule

    applyPresentation(resolvedPaint, to: context)

    if let gradient,
       resolvedPaint.fillAlpha > 0,
       drawGradient(
        context: context,
        path: path,
        gradient: gradient,
        presentation: presentation,
        drawContext: drawContext
       ) {
        if shouldStroke {
            context.addPath(path)
            context.drawPath(using: .stroke)
        }
        return .continue
    }

    if let pattern,
       resolvedPaint.fillAlpha > 0,
       drawPattern(
        context: context,
        path: path,
        pattern: pattern,
        drawContext: drawContext
       ) {
        if shouldStroke {
            context.addPath(path)
            context.drawPath(using: .stroke)
        }
        return .continue
    }

    if shouldFill && shouldStroke {
        context.drawPath(using: fillRule == .evenodd ? .eoFillStroke : .fillStroke)
    } else if shouldFill {
        context.drawPath(using: fillRule == .evenodd ? .eoFill : .fill)
    } else if shouldStroke {
        context.drawPath(using: .stroke)
    }

    return .continue
}

private func applyPresentation(_ resolvedPaint: ResolvedPaint, to context: CGContext) {
    if let fillColor = resolvedPaint.fillColor,
       resolvedPaint.fillAlpha > 0,
       let color = cgColor(from: fillColor, opacity: resolvedPaint.fillAlpha) {
        context.setFillColor(color)
    }

    if let strokeColor = resolvedPaint.strokeColor,
       resolvedPaint.strokeAlpha > 0,
       let color = cgColor(from: strokeColor, opacity: resolvedPaint.strokeAlpha) {
        context.setStrokeColor(color)
    }

    if let width = resolvedPaint.lineWidth {
        context.setLineWidth(width)
    }

    if let lineCap = resolvedPaint.lineCap {
        switch lineCap {
        case .butt: context.setLineCap(.butt)
        case .round: context.setLineCap(.round)
        case .square: context.setLineCap(.square)
        }
    }

    if let lineJoin = resolvedPaint.lineJoin {
        switch lineJoin {
        case .round: context.setLineJoin(.round)
        case .bevel: context.setLineJoin(.bevel)
        case .miter, .miterClip, .arcs: context.setLineJoin(.miter)
        }
    }

    if let miter = resolvedPaint.miterLimit {
        context.setMiterLimit(miter)
    }

    if let dashArray = resolvedPaint.dashArray {
        let lengths = dashArray.map { CGFloat($0) }
        let phase = CGFloat(resolvedPaint.dashOffset ?? 0)
        context.setLineDash(phase: phase, lengths: lengths)
    }
}

private func shouldFillPath(_ paint: ResolvedPaint, hasFillReference: Bool) -> Bool {
    if paint.fillAlpha <= 0 {
        return false
    }
    return paint.fillColor != nil || hasFillReference
}

private func shouldStrokePath(_ paint: ResolvedPaint) -> Bool {
    if paint.strokeAlpha <= 0 {
        return false
    }
    return paint.strokeColor != nil
}

private func drawGradient(
    context: CGContext,
    path: CGPath,
    gradient: any GradientElement,
    presentation: PresentationAttributes,
    drawContext: DrawContext
) -> Bool {
    let fillAlpha = drawContext.resolvedPaint.fillAlpha
    let stops = gradient.stops.isEmpty ? nil : gradient.stops
    guard let stops else { return false }

    let bbox = path.boundingBoxOfPath
    let bounds = DrawingBounds(minX: bbox.minX, minY: bbox.minY, width: bbox.width, height: bbox.height)
    let units = gradient.gradientUnits ?? .objectBoundingBox
    let viewRefWidth = drawContext.viewBox?.width ?? drawContext.viewSize.width?.resolvedValue() ?? bbox.width
    let viewRefHeight = drawContext.viewBox?.height ?? drawContext.viewSize.height?.resolvedValue() ?? bbox.height

    let colors = stops.compactMap { stop -> CGColor? in
        let alpha = fillAlpha * (stop.opacity ?? 1)
        return cgColor(from: stop.color, opacity: alpha)
    }
    guard colors.count == stops.count else { return false }
    let locations = stops.map { CGFloat($0.offset) }

    guard let cgGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: locations
    ) else { return false }

    context.saveGState()
    context.addPath(path)
    context.clip()
    context.setAlpha(CGFloat(drawContext.resolvedPaint.fillAlpha))

    let options: CGGradientDrawingOptions = [.drawsBeforeStartLocation, .drawsAfterEndLocation]

    if let linear = gradient as? LinearGradient {
        let x1 = resolveGradientCoordinate(linear.x1, bounds: bounds, viewRef: viewRefWidth, units: units, defaultValue: 0)
        let y1 = resolveGradientCoordinate(linear.y1, bounds: bounds, viewRef: viewRefHeight, units: units, defaultValue: 0)
        let x2 = resolveGradientCoordinate(linear.x2, bounds: bounds, viewRef: viewRefWidth, units: units, defaultValue: 1)
        let y2 = resolveGradientCoordinate(linear.y2, bounds: bounds, viewRef: viewRefHeight, units: units, defaultValue: 0)
        let start = CGPoint(x: x1, y: y1)
        let end = CGPoint(x: x2, y: y2)
        context.drawLinearGradient(cgGradient, start: start, end: end, options: options)
    } else if let radial = gradient as? RadialGradient {
        let cx = resolveGradientCoordinate(radial.cx, bounds: bounds, viewRef: viewRefWidth, units: units, defaultValue: 0.5)
        let cy = resolveGradientCoordinate(radial.cy, bounds: bounds, viewRef: viewRefHeight, units: units, defaultValue: 0.5)
        let fx = resolveGradientCoordinate(radial.fx, bounds: bounds, viewRef: viewRefWidth, units: units, defaultValue: cx)
        let fy = resolveGradientCoordinate(radial.fy, bounds: bounds, viewRef: viewRefHeight, units: units, defaultValue: cy)
        let radius = resolveGradientRadius(
            radial.r,
            bounds: bounds,
            viewRef: max(viewRefWidth, viewRefHeight),
            units: units,
            defaultValue: 0.5
        )
        context.drawRadialGradient(
            cgGradient,
            startCenter: CGPoint(x: fx, y: fy),
            startRadius: 0,
            endCenter: CGPoint(x: cx, y: cy),
            endRadius: radius,
            options: options
        )
    } else {
        context.restoreGState()
        return false
    }

    context.restoreGState()
    return true
}

private func fillReference(from fill: Fill?) -> String? {
    switch fill {
    case .some(.url(let reference)):
        return reference
    case .some(.urlWithFallback(let reference, _)):
        return reference
    default:
        return nil
    }
}

private func renderImage(
    context: CGContext,
    drawContext: DrawContext,
    image _: Image,
    resolved: ResolvedImage?,
    layout: ResolvedImageLayout
) -> DrawDirective {
#if canImport(ImageIO)
    guard let resolved,
          let cgImage = loadImage(from: resolved.data) else {
        return .continue
    }

    let x = layout.x
    let y = layout.y
    let width = layout.width ?? Double(cgImage.width)
    let height = layout.height ?? Double(cgImage.height)

    guard width > 0, height > 0 else { return .continue }

    context.saveGState()
    defer { context.restoreGState() }

    let transform = makeTransform(from: drawContext.transforms)
    context.concatenate(transform)

    let imageRect = CGRect(x: x, y: y, width: width, height: height)
    let imagePath = CGPath(rect: imageRect, transform: nil)

    if let clipReference = drawContext.presentation.clipPath,
       let clipPath = drawContext.definitions.clipPaths[clipReference],
       let clipShape = buildClipPath(clipPath, definitions: drawContext.definitions, bbox: imagePath.boundingBoxOfPath) {
        context.addPath(clipShape)
        context.clip(using: .winding)
    }

    let opacity = drawContext.presentation.opacity ?? 1
    context.setAlpha(CGFloat(opacity))
    context.translateBy(x: imageRect.minX, y: imageRect.minY + imageRect.height)
    context.scaleBy(x: 1, y: -1)
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: imageRect.width, height: imageRect.height))
    return .continue
#else
    return .continue
#endif
}

#if canImport(ImageIO)
private func loadImage(from data: Data) -> CGImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
        return nil
    }

    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}
#endif

private func renderText(
    context: CGContext,
    drawContext: DrawContext,
    resolved: ResolvedText
) -> DrawDirective {
#if canImport(CoreText)
    guard !resolved.runs.isEmpty else { return .continue }
    let attributed = NSMutableAttributedString()

    for run in resolved.runs {
        let font = makeFont(family: run.fontFamily, size: run.fontSize)
        let color = run.fillColor ?? .black
        let alpha = run.fillColor == nil ? 0 : run.fillAlpha
        let cgColor = cgColor(from: color, opacity: alpha) ?? CGColor(gray: 0, alpha: 0)
        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): cgColor
        ]
        attributed.append(NSAttributedString(string: run.text, attributes: attrs))
    }

    let line = CTLineCreateWithAttributedString(attributed)
    var x = resolved.x
    let y = resolved.y
    let anchor = resolved.textAnchor
    if anchor != .start {
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        switch anchor {
        case .middle:
            x -= width / 2
        case .end:
            x -= width
        case .start:
            break
        }
    }

    context.saveGState()
    defer { context.restoreGState() }

    let transform = makeTransform(from: drawContext.transforms)
    context.concatenate(transform)
    context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    context.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, context)
    return .continue
#else
    return .continue
#endif
}

private func makeFont(family: String?, size: Double) -> CTFont {
    let familyName = family?
        .split(separator: ",")
        .first
        .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"' ")) }
    let name = (familyName?.isEmpty == false ? familyName! : "Helvetica")
    return CTFontCreateWithName(name as CFString, size, nil)
}

private func drawPattern(
    context: CGContext,
    path: CGPath,
    pattern: Pattern,
    drawContext: DrawContext
) -> Bool {
    let bbox = path.boundingBoxOfPath
    let bounds = DrawingBounds(minX: bbox.minX, minY: bbox.minY, width: bbox.width, height: bbox.height)
    let viewRefWidth = drawContext.viewBox?.width ?? drawContext.viewSize.width?.resolvedValue() ?? bbox.width
    let viewRefHeight = drawContext.viewBox?.height ?? drawContext.viewSize.height?.resolvedValue() ?? bbox.height

    let units = pattern.patternUnits ?? .objectBoundingBox
    let contentUnits = pattern.patternContentUnits ?? .userSpaceOnUse

    let tileX = resolvePatternPosition(
        pattern.x,
        bounds: bounds,
        viewRef: viewRefWidth,
        units: units,
        defaultValue: 0,
        axis: .x
    )
    let tileY = resolvePatternPosition(
        pattern.y,
        bounds: bounds,
        viewRef: viewRefHeight,
        units: units,
        defaultValue: 0,
        axis: .y
    )
    let tileWidth = resolvePatternSize(
        pattern.width,
        bounds: bounds,
        viewRef: viewRefWidth,
        units: units,
        defaultValue: 0,
        axis: .x
    )
    let tileHeight = resolvePatternSize(
        pattern.height,
        bounds: bounds,
        viewRef: viewRefHeight,
        units: units,
        defaultValue: 0,
        axis: .y
    )

    guard tileWidth > 0, tileHeight > 0 else { return false }

    context.saveGState()
    context.addPath(path)
    context.clip()

    var startX = tileX
    while startX > bbox.minX {
        startX -= tileWidth
    }

    var startY = tileY
    while startY > bbox.minY {
        startY -= tileHeight
    }

    let patternTransform = makeTransform(from: pattern.patternTransform ?? [])
    let patternSVG = SVG(
        width: pattern.width,
        height: pattern.height,
        viewBox: pattern.viewBox,
        preserveAspectRatio: pattern.preserveAspectRatio,
        children: pattern.children,
        definitions: drawContext.definitions
    )
    let patternRenderer = CGContextRenderer(context: context)

    var y = startY
    while y < bbox.maxY {
        var x = startX
        while x < bbox.maxX {
            context.saveGState()
            context.translateBy(x: x, y: y)
            if !patternTransform.isIdentity {
                context.concatenate(patternTransform)
            }
            if contentUnits == .objectBoundingBox {
                context.scaleBy(x: bbox.width, y: bbox.height)
            }
            patternSVG.walk(callback: patternRenderer)
            context.restoreGState()
            x += tileWidth
        }
        y += tileHeight
    }

    context.restoreGState()
    return true
}


#endif
#endif
