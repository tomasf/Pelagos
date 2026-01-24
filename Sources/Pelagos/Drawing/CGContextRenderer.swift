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

    public func handle(event: DrawEvent, context drawContext: DrawContext) -> DrawDirective {
        switch event {
        case .beginSVG, .endSVG, .beginGroup, .endGroup, .beginAnchor, .endAnchor, .beginSwitch, .endSwitch, .defs, .use:
            return .continue

        case .drawRect(let rect):
            let refs = resolveViewReferences(drawContext)
            let x = resolveLength(rect.x, viewRef: refs.width, fontSize: refs.fontSize)
            let y = resolveLength(rect.y, viewRef: refs.height, fontSize: refs.fontSize)
            let width = resolveLength(rect.width, viewRef: refs.width, fontSize: refs.fontSize)
            let height = resolveLength(rect.height, viewRef: refs.height, fontSize: refs.fontSize)
            let rx = resolveLength(rect.rx, viewRef: refs.width, fontSize: refs.fontSize)
            let ry = resolveLength(rect.ry, viewRef: refs.height, fontSize: refs.fontSize)
            return drawShape(context: context, drawContext: drawContext) {
                let cornerX = rx > 0 ? rx : (rect.ry == nil ? 0 : ry)
                let cornerY = ry > 0 ? ry : (rect.rx == nil ? 0 : rx)
                let rectFrame = CGRect(x: x, y: y, width: width, height: height)
                if cornerX > 0 || cornerY > 0 {
                    $0.addPath(CGPath(roundedRect: rectFrame, cornerWidth: cornerX, cornerHeight: cornerY, transform: nil))
                } else {
                    $0.addRect(rectFrame)
                }
            }

        case .drawCircle(let circle):
            let refs = resolveViewReferences(drawContext)
            let cx = resolveLength(circle.cx, viewRef: refs.width, fontSize: refs.fontSize)
            let cy = resolveLength(circle.cy, viewRef: refs.height, fontSize: refs.fontSize)
            let r = resolveLength(circle.r, viewRef: min(refs.width, refs.height), fontSize: refs.fontSize)
            return drawShape(context: context, drawContext: drawContext) {
                let rect = CGRect(
                    x: cx - r,
                    y: cy - r,
                    width: r * 2,
                    height: r * 2
                )
                $0.addEllipse(in: rect)
            }

        case .drawEllipse(let ellipse):
            let refs = resolveViewReferences(drawContext)
            let cx = resolveLength(ellipse.cx, viewRef: refs.width, fontSize: refs.fontSize)
            let cy = resolveLength(ellipse.cy, viewRef: refs.height, fontSize: refs.fontSize)
            let rx = resolveLength(ellipse.rx, viewRef: refs.width, fontSize: refs.fontSize)
            let ry = resolveLength(ellipse.ry, viewRef: refs.height, fontSize: refs.fontSize)
            return drawShape(context: context, drawContext: drawContext) {
                let rect = CGRect(
                    x: cx - rx,
                    y: cy - ry,
                    width: rx * 2,
                    height: ry * 2
                )
                $0.addEllipse(in: rect)
            }

        case .drawLine(let line):
            let refs = resolveViewReferences(drawContext)
            let x1 = resolveLength(line.x1, viewRef: refs.width, fontSize: refs.fontSize)
            let y1 = resolveLength(line.y1, viewRef: refs.height, fontSize: refs.fontSize)
            let x2 = resolveLength(line.x2, viewRef: refs.width, fontSize: refs.fontSize)
            let y2 = resolveLength(line.y2, viewRef: refs.height, fontSize: refs.fontSize)
            return drawShape(context: context, drawContext: drawContext) {
                $0.move(to: CGPoint(x: x1, y: y1))
                $0.addLine(to: CGPoint(x: x2, y: y2))
            }

        case .drawPolyline(let polyline):
            return drawShape(context: context, drawContext: drawContext) {
                guard let first = polyline.points.first else { return }
                $0.move(to: CGPoint(x: first.x, y: first.y))
                for point in polyline.points.dropFirst() {
                    $0.addLine(to: CGPoint(x: point.x, y: point.y))
                }
            }

        case .drawPolygon(let polygon):
            return drawShape(context: context, drawContext: drawContext) {
                guard let first = polygon.points.first else { return }
                $0.move(to: CGPoint(x: first.x, y: first.y))
                for point in polygon.points.dropFirst() {
                    $0.addLine(to: CGPoint(x: point.x, y: point.y))
                }
                $0.closeSubpath()
            }

        case .drawPath(let path):
            return drawShape(context: context, drawContext: drawContext) {
                $0.addPath(buildPath(from: path.segments))
            }

        case .drawText(let text, let runs):
            return drawText(context: context, drawContext: drawContext, text: text, runs: runs)
        case .drawImage(let image):
            return drawImage(context: context, drawContext: drawContext, image: image)
        }
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
        let x1 = resolveCoordinate(linear.x1, bbox: bbox, viewRef: viewRefWidth, units: units, defaultValue: 0)
        let y1 = resolveCoordinate(linear.y1, bbox: bbox, viewRef: viewRefHeight, units: units, defaultValue: 0)
        let x2 = resolveCoordinate(linear.x2, bbox: bbox, viewRef: viewRefWidth, units: units, defaultValue: 1)
        let y2 = resolveCoordinate(linear.y2, bbox: bbox, viewRef: viewRefHeight, units: units, defaultValue: 0)
        let start = CGPoint(x: x1, y: y1)
        let end = CGPoint(x: x2, y: y2)
        context.drawLinearGradient(cgGradient, start: start, end: end, options: options)
    } else if let radial = gradient as? RadialGradient {
        let cx = resolveCoordinate(radial.cx, bbox: bbox, viewRef: viewRefWidth, units: units, defaultValue: 0.5)
        let cy = resolveCoordinate(radial.cy, bbox: bbox, viewRef: viewRefHeight, units: units, defaultValue: 0.5)
        let fx = resolveCoordinate(radial.fx, bbox: bbox, viewRef: viewRefWidth, units: units, defaultValue: cx)
        let fy = resolveCoordinate(radial.fy, bbox: bbox, viewRef: viewRefHeight, units: units, defaultValue: cy)
        let radius = resolveRadius(
            radial.r,
            bbox: bbox,
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

private func drawImage(
    context: CGContext,
    drawContext: DrawContext,
    image: Image
) -> DrawDirective {
#if canImport(ImageIO)
    guard let href = image.href,
          let cgImage = loadImage(from: href) else {
        return .continue
    }

    let viewRefWidth = drawContext.viewBox?.width ?? drawContext.viewSize.width?.value ?? Double(cgImage.width)
    let viewRefHeight = drawContext.viewBox?.height ?? drawContext.viewSize.height?.value ?? Double(cgImage.height)

    let x = resolveImageLength(image.x, defaultValue: 0, viewRef: viewRefWidth)
    let y = resolveImageLength(image.y, defaultValue: 0, viewRef: viewRefHeight)
    let width = resolveImageLength(image.width, defaultValue: Double(cgImage.width), viewRef: viewRefWidth)
    let height = resolveImageLength(image.height, defaultValue: Double(cgImage.height), viewRef: viewRefHeight)

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
private func loadImage(from href: String) -> CGImage? {
    if href.hasPrefix("data:") {
        return loadDataImage(from: href)
    }
    return nil
}

private func loadDataImage(from href: String) -> CGImage? {
    let parts = href.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2,
          parts[0].contains("base64"),
          let data = Data(base64Encoded: String(parts[1])) else {
        return nil
    }

    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
        return nil
    }

    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}
#endif

private func resolveImageLength(_ length: Length?, defaultValue: Double, viewRef: Double) -> Double {
    guard let length else { return defaultValue }
    return length.resolvedValue(viewport: viewRef)
}

private func resolveViewReferences(_ drawContext: DrawContext) -> (width: Double, height: Double, fontSize: Double) {
    let width = drawContext.viewBox?.width
        ?? drawContext.viewSize.width?.resolvedValue()
        ?? 0
    let height = drawContext.viewBox?.height
        ?? drawContext.viewSize.height?.resolvedValue()
        ?? 0
    let fontSize = resolveFontSize(drawContext.presentation.fontSize, viewRef: height, fallback: 16)
    return (width, height, fontSize)
}

private func resolveLength(
    _ length: Length?,
    viewRef: Double,
    fontSize: Double,
    defaultValue: Double = 0
) -> Double {
    guard let length else { return defaultValue }
    return length.resolvedValue(fontSize: fontSize, viewport: viewRef)
}

private func drawText(
    context: CGContext,
    drawContext: DrawContext,
    text: Text,
    runs: [TextRun]
) -> DrawDirective {
#if canImport(CoreText)
    guard !runs.isEmpty else { return .continue }

    let viewRefHeight = drawContext.viewBox?.height ?? drawContext.viewSize.height?.resolvedValue() ?? 16
    let defaultFontSize = resolveFontSize(nil, viewRef: viewRefHeight, fallback: 16)
    let attributed = NSMutableAttributedString()

    for run in runs {
        let font = makeFont(from: run.presentation, viewRef: viewRefHeight, fallbackSize: defaultFontSize)
        let color = resolveTextFill(from: run.presentation) ?? .black
        let alpha = (run.presentation.opacity ?? 1) * (run.presentation.fillOpacity ?? 1)
        let cgColor = cgColor(from: color, opacity: alpha) ?? CGColor(gray: 0, alpha: 1)
        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): cgColor
        ]
        attributed.append(NSAttributedString(string: run.text, attributes: attrs))
    }

    let line = CTLineCreateWithAttributedString(attributed)
    var x = text.x?.first?.value ?? 0
    var y = text.y?.first?.value ?? 0

    if let dx = text.dx?.first?.value {
        x += dx
    }
    if let dy = text.dy?.first?.value {
        y += dy
    }

    let anchor = drawContext.presentation.textAnchor ?? .start
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

private func resolveFontSize(_ length: Length?, viewRef: Double, fallback: Double) -> Double {
    guard let length else { return fallback }
    return length.resolvedValue(viewport: viewRef)
}

private func makeFont(from presentation: PresentationAttributes, viewRef: Double, fallbackSize: Double) -> CTFont {
    let size = resolveFontSize(presentation.fontSize, viewRef: viewRef, fallback: fallbackSize)
    let family = presentation.fontFamily?
        .split(separator: ",")
        .first
        .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"' ")) }
    let name = family?.isEmpty == false ? family! : "Helvetica"
    return CTFontCreateWithName(name as CFString, size, nil)
}

private func resolveTextFill(from presentation: PresentationAttributes) -> Color? {
    switch presentation.fill {
    case .some(.none):
        return nil
    case .some(.color(let color)):
        return color
    case .some(.urlWithFallback(_, let fallback)):
        return fallback
    case .some(.url):
        return .black
    case nil:
        return .black
    }
}

private func buildClipPath(
    _ clipPath: ClipPath,
    definitions: Definitions,
    bbox: CGRect
) -> CGPath? {
    let units = clipPath.clipPathUnits ?? .userSpaceOnUse
    let baseTransform: CGAffineTransform
    switch units {
    case .objectBoundingBox:
        baseTransform = CGAffineTransform(translationX: bbox.minX, y: bbox.minY)
            .scaledBy(x: bbox.width, y: bbox.height)
    case .userSpaceOnUse:
        baseTransform = .identity
    }

    let path = CGMutablePath()
    for child in clipPath.children {
        appendClipElement(child, into: path, transform: baseTransform, definitions: definitions)
    }
    return path.isEmpty ? nil : path.copy()
}

private func appendClipElement(
    _ element: any GraphicElement,
    into path: CGMutablePath,
    transform: CGAffineTransform,
    definitions: Definitions
) {
    if let group = element as? Group {
        let groupTransform = transform.concatenating(makeTransform(from: group.presentation.transform ?? []))
        for child in group.children {
            appendClipElement(child, into: path, transform: groupTransform, definitions: definitions)
        }
        return
    }

    if let use = element as? Use {
        var useTransform = transform
        if let local = use.presentation.transform {
            useTransform = useTransform.concatenating(makeTransform(from: local))
        }
        if let x = use.x?.value, let y = use.y?.value {
            useTransform = useTransform.translatedBy(x: x, y: y)
        } else if let x = use.x?.value {
            useTransform = useTransform.translatedBy(x: x, y: 0)
        } else if let y = use.y?.value {
            useTransform = useTransform.translatedBy(x: 0, y: y)
        }
        if let reference = use.href,
           let resolved = definitions.elements[reference] {
            appendClipElement(resolved, into: path, transform: useTransform, definitions: definitions)
        }
        return
    }

    let localPath: CGPath?
    switch element {
    case let rect as Rect:
        let rx = rect.rx?.value ?? rect.ry?.value ?? 0
        let ry = rect.ry?.value ?? rect.rx?.value ?? 0
        let rectFrame = CGRect(x: rect.x.value, y: rect.y.value, width: rect.width.value, height: rect.height.value)
        if rx > 0 || ry > 0 {
            localPath = CGPath(roundedRect: rectFrame, cornerWidth: rx, cornerHeight: ry, transform: nil)
        } else {
            localPath = CGPath(rect: rectFrame, transform: nil)
        }
    case let circle as Circle:
        let rectFrame = CGRect(
            x: circle.cx.value - circle.r.value,
            y: circle.cy.value - circle.r.value,
            width: circle.r.value * 2,
            height: circle.r.value * 2
        )
        localPath = CGPath(ellipseIn: rectFrame, transform: nil)
    case let ellipse as Ellipse:
        let rectFrame = CGRect(
            x: ellipse.cx.value - ellipse.rx.value,
            y: ellipse.cy.value - ellipse.ry.value,
            width: ellipse.rx.value * 2,
            height: ellipse.ry.value * 2
        )
        localPath = CGPath(ellipseIn: rectFrame, transform: nil)
    case let line as Line:
        let linePath = CGMutablePath()
        linePath.move(to: CGPoint(x: line.x1.value, y: line.y1.value))
        linePath.addLine(to: CGPoint(x: line.x2.value, y: line.y2.value))
        localPath = linePath
    case let polyline as Polyline:
        let linePath = CGMutablePath()
        if let first = polyline.points.first {
            linePath.move(to: CGPoint(x: first.x, y: first.y))
            for point in polyline.points.dropFirst() {
                linePath.addLine(to: CGPoint(x: point.x, y: point.y))
            }
        }
        localPath = linePath
    case let polygon as Polygon:
        let polyPath = CGMutablePath()
        if let first = polygon.points.first {
            polyPath.move(to: CGPoint(x: first.x, y: first.y))
            for point in polygon.points.dropFirst() {
                polyPath.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            polyPath.closeSubpath()
        }
        localPath = polyPath
    case let pathElement as Path:
        localPath = buildPath(from: pathElement.segments)
    default:
        localPath = nil
    }

    guard let localPath else { return }

    var elementTransform = transform
    if let transforms = element.presentation.transform {
        elementTransform = elementTransform.concatenating(makeTransform(from: transforms))
    }
    path.addPath(localPath, transform: elementTransform)
}

private func drawPattern(
    context: CGContext,
    path: CGPath,
    pattern: Pattern,
    drawContext: DrawContext
) -> Bool {
    let bbox = path.boundingBoxOfPath
    let viewRefWidth = drawContext.viewBox?.width ?? drawContext.viewSize.width?.resolvedValue() ?? bbox.width
    let viewRefHeight = drawContext.viewBox?.height ?? drawContext.viewSize.height?.resolvedValue() ?? bbox.height

    let units = pattern.patternUnits ?? .objectBoundingBox
    let contentUnits = pattern.patternContentUnits ?? .userSpaceOnUse

    let tileX = resolvePatternPosition(
        pattern.x,
        bbox: bbox,
        viewRef: viewRefWidth,
        units: units,
        defaultValue: 0,
        axis: .x
    )
    let tileY = resolvePatternPosition(
        pattern.y,
        bbox: bbox,
        viewRef: viewRefHeight,
        units: units,
        defaultValue: 0,
        axis: .y
    )
    let tileWidth = resolvePatternSize(
        pattern.width,
        bbox: bbox,
        viewRef: viewRefWidth,
        units: units,
        defaultValue: 0,
        axis: .x
    )
    let tileHeight = resolvePatternSize(
        pattern.height,
        bbox: bbox,
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

private enum PatternAxis {
    case x
    case y
}

private func resolvePatternPosition(
    _ length: Length?,
    bbox: CGRect,
    viewRef: Double,
    units: GradientUnits,
    defaultValue: Double,
    axis: PatternAxis
) -> Double {
    let value = length?.value ?? defaultValue
    switch units {
    case .objectBoundingBox:
        let fraction = length?.unit == .percent ? value / 100 : value
        switch axis {
        case .x:
            return bbox.minX + bbox.width * fraction
        case .y:
            return bbox.minY + bbox.height * fraction
        }
    case .userSpaceOnUse:
        if length?.unit == .percent {
            return viewRef * (value / 100)
        }
        return length?.resolvedValue() ?? defaultValue
    }
}

private func resolvePatternSize(
    _ length: Length?,
    bbox: CGRect,
    viewRef: Double,
    units: GradientUnits,
    defaultValue: Double,
    axis: PatternAxis
) -> Double {
    let value = length?.value ?? defaultValue
    switch units {
    case .objectBoundingBox:
        let fraction = length?.unit == .percent ? value / 100 : value
        let size = axis == .x ? bbox.width : bbox.height
        return size * fraction
    case .userSpaceOnUse:
        if length?.unit == .percent {
            return viewRef * (value / 100)
        }
        return length?.resolvedValue() ?? defaultValue
    }
}

private func resolveCoordinate(
    _ length: Length?,
    bbox: CGRect,
    viewRef: Double,
    units: GradientUnits,
    defaultValue: Double
) -> Double {
    let value = length?.value ?? defaultValue
    switch units {
    case .objectBoundingBox:
        let fraction = length?.unit == .percent ? value / 100 : value
        return bbox.minX + bbox.width * fraction
    case .userSpaceOnUse:
        if length?.unit == .percent {
            return viewRef * (value / 100)
        }
        return length?.resolvedValue() ?? defaultValue
    }
}

private func resolveRadius(
    _ length: Length?,
    bbox: CGRect,
    viewRef: Double,
    units: GradientUnits,
    defaultValue: Double
) -> Double {
    let value = length?.value ?? defaultValue
    switch units {
    case .objectBoundingBox:
        let fraction = length?.unit == .percent ? value / 100 : value
        let scale = max(bbox.width, bbox.height)
        return scale * fraction
    case .userSpaceOnUse:
        if length?.unit == .percent {
            return viewRef * (value / 100)
        }
        return length?.resolvedValue() ?? defaultValue
    }
}

private func cgColor(from color: Color, opacity: Double) -> CGColor? {
    let alpha = CGFloat(max(0, min(1, opacity)))

    switch color {
    case .none:
        return nil
    case .currentColor:
        return CGColor(gray: 0, alpha: alpha)
    case .rgb(let r, let g, let b):
        return CGColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: alpha
        )
    case .rgba(let r, let g, let b, let a):
        return CGColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: alpha * CGFloat(a)
        )
    case .p3(let r, let g, let b, let a):
        let space = CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
        let components = [CGFloat(r), CGFloat(g), CGFloat(b), alpha * CGFloat(a)]
        return CGColor(colorSpace: space, components: components)
    case .named(let name):
        if let resolved = Color.namedColors[name] {
            return cgColor(from: resolved, opacity: opacity)
        }
        return CGColor(gray: 0, alpha: alpha)
    }
}

private func makeTransform(from transforms: [Transform]) -> CGAffineTransform {
    var transform = CGAffineTransform.identity
    for item in transforms {
        switch item {
        case .matrix(let a, let b, let c, let d, let e, let f):
            let t = CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
            transform = transform.concatenating(t)
        case .translate(let x, let y):
            transform = transform.translatedBy(x: x, y: y)
        case .scale(let x, let y):
            transform = transform.scaledBy(x: x, y: y)
        case .rotate(let angle, let cx, let cy):
            let radians = angle * Double.pi / 180
            if let cx, let cy {
                transform = transform
                    .translatedBy(x: cx, y: cy)
                    .rotated(by: radians)
                    .translatedBy(x: -cx, y: -cy)
            } else {
                transform = transform.rotated(by: radians)
            }
        case .skewX(let angle):
            let t = CGAffineTransform(a: 1, b: 0, c: tan(angle * Double.pi / 180), d: 1, tx: 0, ty: 0)
            transform = transform.concatenating(t)
        case .skewY(let angle):
            let t = CGAffineTransform(a: 1, b: tan(angle * Double.pi / 180), c: 0, d: 1, tx: 0, ty: 0)
            transform = transform.concatenating(t)
        }
    }
    return transform
}

private func buildPath(from segments: [PathSegment]) -> CGPath {
    let path = CGMutablePath()
    var current = CGPoint.zero
    var start = CGPoint.zero
    var lastCubic: CGPoint?
    var lastQuad: CGPoint?

    for segment in segments {
        switch segment {
        case .moveTo(let point):
            current = CGPoint(x: point.x, y: point.y)
            start = current
            path.move(to: current)
            lastCubic = nil
            lastQuad = nil

        case .moveToRelative(let point):
            current = CGPoint(x: current.x + point.x, y: current.y + point.y)
            start = current
            path.move(to: current)
            lastCubic = nil
            lastQuad = nil

        case .lineTo(let point):
            current = CGPoint(x: point.x, y: point.y)
            path.addLine(to: current)
            lastCubic = nil
            lastQuad = nil

        case .lineToRelative(let point):
            current = CGPoint(x: current.x + point.x, y: current.y + point.y)
            path.addLine(to: current)
            lastCubic = nil
            lastQuad = nil

        case .horizontalLineTo(let x):
            current = CGPoint(x: x, y: current.y)
            path.addLine(to: current)
            lastCubic = nil
            lastQuad = nil

        case .horizontalLineToRelative(let x):
            current = CGPoint(x: current.x + x, y: current.y)
            path.addLine(to: current)
            lastCubic = nil
            lastQuad = nil

        case .verticalLineTo(let y):
            current = CGPoint(x: current.x, y: y)
            path.addLine(to: current)
            lastCubic = nil
            lastQuad = nil

        case .verticalLineToRelative(let y):
            current = CGPoint(x: current.x, y: current.y + y)
            path.addLine(to: current)
            lastCubic = nil
            lastQuad = nil

        case .curveTo(let c1, let c2, let end):
            let endPoint = CGPoint(x: end.x, y: end.y)
            path.addCurve(
                to: endPoint,
                control1: CGPoint(x: c1.x, y: c1.y),
                control2: CGPoint(x: c2.x, y: c2.y)
            )
            current = endPoint
            lastCubic = CGPoint(x: c2.x, y: c2.y)
            lastQuad = nil

        case .curveToRelative(let c1, let c2, let end):
            let control1 = CGPoint(x: current.x + c1.x, y: current.y + c1.y)
            let control2 = CGPoint(x: current.x + c2.x, y: current.y + c2.y)
            let endPoint = CGPoint(x: current.x + end.x, y: current.y + end.y)
            path.addCurve(to: endPoint, control1: control1, control2: control2)
            current = endPoint
            lastCubic = control2
            lastQuad = nil

        case .smoothCurveTo(let c2, let end):
            let control1 = reflect(point: lastCubic, around: current)
            let control2 = CGPoint(x: c2.x, y: c2.y)
            let endPoint = CGPoint(x: end.x, y: end.y)
            path.addCurve(to: endPoint, control1: control1, control2: control2)
            current = endPoint
            lastCubic = control2
            lastQuad = nil

        case .smoothCurveToRelative(let c2, let end):
            let control1 = reflect(point: lastCubic, around: current)
            let control2 = CGPoint(x: current.x + c2.x, y: current.y + c2.y)
            let endPoint = CGPoint(x: current.x + end.x, y: current.y + end.y)
            path.addCurve(to: endPoint, control1: control1, control2: control2)
            current = endPoint
            lastCubic = control2
            lastQuad = nil

        case .quadraticCurveTo(let control, let end):
            let controlPoint = CGPoint(x: control.x, y: control.y)
            let endPoint = CGPoint(x: end.x, y: end.y)
            path.addQuadCurve(to: endPoint, control: controlPoint)
            current = endPoint
            lastQuad = controlPoint
            lastCubic = nil

        case .quadraticCurveToRelative(let control, let end):
            let controlPoint = CGPoint(x: current.x + control.x, y: current.y + control.y)
            let endPoint = CGPoint(x: current.x + end.x, y: current.y + end.y)
            path.addQuadCurve(to: endPoint, control: controlPoint)
            current = endPoint
            lastQuad = controlPoint
            lastCubic = nil

        case .smoothQuadraticCurveTo(let end):
            let control = reflect(point: lastQuad, around: current)
            let endPoint = CGPoint(x: end.x, y: end.y)
            path.addQuadCurve(to: endPoint, control: control)
            current = endPoint
            lastQuad = control
            lastCubic = nil

        case .smoothQuadraticCurveToRelative(let end):
            let control = reflect(point: lastQuad, around: current)
            let endPoint = CGPoint(x: current.x + end.x, y: current.y + end.y)
            path.addQuadCurve(to: endPoint, control: control)
            current = endPoint
            lastQuad = control
            lastCubic = nil

        case .arcTo(let rx, let ry, let rotation, let largeArc, let sweep, let end):
            let endPoint = CGPoint(x: end.x, y: end.y)
            addArc(
                to: path,
                from: current,
                to: endPoint,
                rx: rx,
                ry: ry,
                xAxisRotation: rotation,
                largeArc: largeArc,
                sweep: sweep
            )
            current = endPoint
            lastCubic = nil
            lastQuad = nil

        case .arcToRelative(let rx, let ry, let rotation, let largeArc, let sweep, let end):
            let endPoint = CGPoint(x: current.x + end.x, y: current.y + end.y)
            addArc(
                to: path,
                from: current,
                to: endPoint,
                rx: rx,
                ry: ry,
                xAxisRotation: rotation,
                largeArc: largeArc,
                sweep: sweep
            )
            current = endPoint
            lastCubic = nil
            lastQuad = nil

        case .closePath:
            path.closeSubpath()
            current = start
            lastCubic = nil
            lastQuad = nil
        }
    }

    return path
}

private func reflect(point: CGPoint?, around center: CGPoint) -> CGPoint {
    guard let point else { return center }
    return CGPoint(x: center.x * 2 - point.x, y: center.y * 2 - point.y)
}

private func addArc(
    to path: CGMutablePath,
    from start: CGPoint,
    to end: CGPoint,
    rx: Double,
    ry: Double,
    xAxisRotation: Double,
    largeArc: Bool,
    sweep: Bool
) {
    let absRx = Swift.abs(rx)
    let absRy = Swift.abs(ry)

    guard absRx > 0, absRy > 0 else {
        path.addLine(to: end)
        return
    }

    let phi = xAxisRotation * Double.pi / 180
    let cosPhi = cos(phi)
    let sinPhi = sin(phi)

    let startX = Double(start.x)
    let startY = Double(start.y)
    let endX = Double(end.x)
    let endY = Double(end.y)
    let dx = (startX - endX) / 2
    let dy = (startY - endY) / 2

    let x1p = cosPhi * dx + sinPhi * dy
    let y1p = -sinPhi * dx + cosPhi * dy

    var rxAdj = absRx
    var ryAdj = absRy
    let x1pSqRatio = (x1p * x1p) / (rxAdj * rxAdj)
    let y1pSqRatio = (y1p * y1p) / (ryAdj * ryAdj)
    let lambda = x1pSqRatio + y1pSqRatio
    if lambda > 1 {
        let scale = sqrt(lambda)
        rxAdj *= scale
        ryAdj *= scale
    }

    let rxSq = rxAdj * rxAdj
    let rySq = ryAdj * ryAdj
    let x1pSq = x1p * x1p
    let y1pSq = y1p * y1p

    let sign = (largeArc == sweep) ? -1.0 : 1.0
    let numerator = rxSq * rySq - rxSq * y1pSq - rySq * x1pSq
    let denom = rxSq * y1pSq + rySq * x1pSq
    let ratio = denom == 0 ? 0.0 : numerator / denom
    let factor = denom == 0 ? 0.0 : sign * sqrt(Swift.max(0.0, ratio))

    let cxp = factor * (rxAdj * y1p) / ryAdj
    let cyp = factor * (-ryAdj * x1p) / rxAdj

    let cx = cosPhi * cxp - sinPhi * cyp + (startX + endX) / 2
    let cy = sinPhi * cxp + cosPhi * cyp + (startY + endY) / 2

    let ux = (x1p - cxp) / rxAdj
    let uy = (y1p - cyp) / ryAdj
    let vx = (-x1p - cxp) / rxAdj
    let vy = (-y1p - cyp) / ryAdj

    let startAngle = atan2(uy, ux)
    var deltaAngle = atan2(ux * vy - uy * vx, ux * vx + uy * vy)

    if !sweep && deltaAngle > 0 {
        deltaAngle -= 2 * Double.pi
    } else if sweep && deltaAngle < 0 {
        deltaAngle += 2 * Double.pi
    }

    let segmentCount = Int(ceil(Swift.abs(deltaAngle) / (Double.pi / 2)))
    let segments = Swift.max(1, segmentCount)
    let step = deltaAngle / Double(segments)

    for i in 0..<segments {
        let t1 = startAngle + Double(i) * step
        let t2 = t1 + step
        let alpha = (4.0 / 3.0) * tan((t2 - t1) / 4.0)

        let p0 = pointOnArc(cx: cx, cy: cy, rx: rxAdj, ry: ryAdj, cosPhi: cosPhi, sinPhi: sinPhi, angle: t1)
        let p3 = pointOnArc(cx: cx, cy: cy, rx: rxAdj, ry: ryAdj, cosPhi: cosPhi, sinPhi: sinPhi, angle: t2)

        let d1 = derivativeOnArc(rx: rxAdj, ry: ryAdj, cosPhi: cosPhi, sinPhi: sinPhi, angle: t1)
        let d2 = derivativeOnArc(rx: rxAdj, ry: ryAdj, cosPhi: cosPhi, sinPhi: sinPhi, angle: t2)

        let p1 = CGPoint(x: p0.x + alpha * d1.x, y: p0.y + alpha * d1.y)
        let p2 = CGPoint(x: p3.x - alpha * d2.x, y: p3.y - alpha * d2.y)

        path.addCurve(to: p3, control1: p1, control2: p2)
    }
}

private func pointOnArc(
    cx: Double,
    cy: Double,
    rx: Double,
    ry: Double,
    cosPhi: Double,
    sinPhi: Double,
    angle: Double
) -> CGPoint {
    let cosA = cos(angle)
    let sinA = sin(angle)
    let x = cx + rx * cosPhi * cosA - ry * sinPhi * sinA
    let y = cy + rx * sinPhi * cosA + ry * cosPhi * sinA
    return CGPoint(x: x, y: y)
}

private func derivativeOnArc(
    rx: Double,
    ry: Double,
    cosPhi: Double,
    sinPhi: Double,
    angle: Double
) -> CGPoint {
    let cosA = cos(angle)
    let sinA = sin(angle)
    let dx = -rx * cosPhi * sinA - ry * sinPhi * cosA
    let dy = -rx * sinPhi * sinA + ry * cosPhi * cosA
    return CGPoint(x: dx, y: dy)
}
#endif
#endif
