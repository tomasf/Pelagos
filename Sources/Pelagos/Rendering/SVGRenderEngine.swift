import Foundation

/// Rendering context that tracks inherited state during tree traversal
struct RenderContext: Sendable {
    var presentation: PresentationAttributes
    var transforms: [Transform]
    var viewBox: ViewBox?
    var viewSize: (width: Length?, height: Length?)
    var definitions: Definitions
    var opacity: Double

    init(
        presentation: PresentationAttributes = PresentationAttributes(),
        transforms: [Transform] = [],
        viewBox: ViewBox? = nil,
        viewSize: (width: Length?, height: Length?) = (nil, nil),
        definitions: Definitions = Definitions(),
        opacity: Double = 1
    ) {
        self.presentation = presentation
        self.transforms = transforms
        self.viewBox = viewBox
        self.viewSize = viewSize
        self.definitions = definitions
        self.opacity = opacity
    }

    /// Get viewport dimensions for resolving lengths
    var viewportWidth: Double {
        viewBox?.width ?? viewSize.width?.resolvedValue() ?? 0
    }

    var viewportHeight: Double {
        viewBox?.height ?? viewSize.height?.resolvedValue() ?? 0
    }

    var fontSize: Double {
        presentation.fontSize?.resolvedValue(viewport: viewportHeight) ?? 16
    }
}

// MARK: - SVG Render Extension

public extension SVG {
    /// Renders this SVG document using the provided renderer.
    ///
    /// The renderer receives drawing commands (path construction, fills, strokes, text, images)
    /// that can be used to render the SVG to any graphics backend.
    ///
    /// - Parameters:
    ///   - renderer: The renderer to use for drawing operations.
    ///   - size: An optional output size. When provided with a viewBox, the SVG content
    ///           is scaled and positioned according to the `preserveAspectRatio` attribute.
    ///           If nil, the SVG renders at its intrinsic size.
    func render<R: SVGRenderer>(with renderer: R, size: (width: Double, height: Double)? = nil) {
        let context = RenderContext(
            presentation: presentation,
            transforms: presentation.transform ?? [],
            viewBox: viewBox,
            viewSize: (width, height),
            definitions: definitions,
            opacity: presentation.opacity ?? 1
        )

        if let size, let viewBox {
            let viewBoxTransform = makeViewBoxTransform(
                viewBox: viewBox,
                outputSize: size,
                preserveAspectRatio: preserveAspectRatio
            )
            if !viewBoxTransform.isIdentity {
                renderer.save()
                renderer.concatenate(viewBoxTransform)
                renderContainer(children, with: renderer, context: context)
                renderer.restore()
                return
            }
        }

        renderContainer(children, with: renderer, context: context)
    }
}

// MARK: - Rendering Functions

private func renderContainer<R: SVGRenderer>(
    _ children: [any GraphicElement],
    with renderer: R,
    context: RenderContext
) {
    for child in children {
        renderElement(child, with: renderer, context: context)
    }
}

private func renderElement<R: SVGRenderer>(
    _ element: any GraphicElement,
    with renderer: R,
    context: RenderContext
) {
    // Skip invisible elements
    if element.presentation.display == DisplayMode.none {
        return
    }
    if element.presentation.visibility == .hidden {
        return
    }

    let childContext = inheritContext(context, element: element)

    // Handle containers
    if let group = element as? Group {
        renderGroup(group, with: renderer, context: childContext)
        return
    }
    if let anchor = element as? Anchor {
        renderGroup(anchor.children, with: renderer, context: childContext)
        return
    }
    if let switchNode = element as? Switch {
        // Switch renders only the first child
        if let first = switchNode.children.first {
            renderElement(first, with: renderer, context: childContext)
        }
        return
    }
    if let svg = element as? SVG {
        renderNestedSVG(svg, with: renderer, context: childContext)
        return
    }
    if let use = element as? Use {
        renderUse(use, with: renderer, context: childContext)
        return
    }

    // Handle shapes and content
    renderer.save()
    defer { renderer.restore() }

    // Apply transforms
    let transform = makeAffineTransform(from: childContext.transforms)
    if !transform.isIdentity {
        renderer.concatenate(transform)
    }

    // Apply clip path if any
    if let clipPathRef = childContext.presentation.clipPath,
       let clipPath = context.definitions.clipPaths[clipPathRef] {
        applyClipPath(clipPath, with: renderer, context: childContext)
    }

    // Apply opacity
    if childContext.opacity < 1 {
        renderer.setOpacity(childContext.opacity)
    }

    // Render the element
    if let rect = element as? Rect {
        renderRect(rect, with: renderer, context: childContext)
    } else if let circle = element as? Circle {
        renderCircle(circle, with: renderer, context: childContext)
    } else if let ellipse = element as? Ellipse {
        renderEllipse(ellipse, with: renderer, context: childContext)
    } else if let line = element as? Line {
        renderLine(line, with: renderer, context: childContext)
    } else if let polyline = element as? Polyline {
        renderPolyline(polyline, with: renderer, context: childContext)
    } else if let polygon = element as? Polygon {
        renderPolygon(polygon, with: renderer, context: childContext)
    } else if let path = element as? Path {
        renderPath(path, with: renderer, context: childContext)
    } else if let text = element as? Text {
        renderText(text, with: renderer, context: childContext)
    } else if let image = element as? Image {
        renderImage(image, with: renderer, context: childContext)
    }
}

private func renderGroup<R: SVGRenderer>(
    _ group: Group,
    with renderer: R,
    context: RenderContext
) {
    renderer.save()
    defer { renderer.restore() }

    let transform = makeAffineTransform(from: context.transforms)
    if !transform.isIdentity {
        renderer.concatenate(transform)
    }

    if let clipPathRef = context.presentation.clipPath,
       let clipPath = context.definitions.clipPaths[clipPathRef] {
        applyClipPath(clipPath, with: renderer, context: context)
    }

    if context.opacity < 1 {
        renderer.setOpacity(context.opacity)
    }

    // Reset transforms for children since we've already applied them
    var childContext = context
    childContext.transforms = []

    for child in group.children {
        renderElement(child, with: renderer, context: childContext)
    }
}

private func renderGroup<R: SVGRenderer>(
    _ children: [any GraphicElement],
    with renderer: R,
    context: RenderContext
) {
    renderer.save()
    defer { renderer.restore() }

    let transform = makeAffineTransform(from: context.transforms)
    if !transform.isIdentity {
        renderer.concatenate(transform)
    }

    if context.opacity < 1 {
        renderer.setOpacity(context.opacity)
    }

    var childContext = context
    childContext.transforms = []

    for child in children {
        renderElement(child, with: renderer, context: childContext)
    }
}

private func renderNestedSVG<R: SVGRenderer>(
    _ svg: SVG,
    with renderer: R,
    context: RenderContext
) {
    renderer.save()
    defer { renderer.restore() }

    // Apply transforms from context (parent group transforms, etc.)
    let transform = makeAffineTransform(from: context.transforms)
    if !transform.isIdentity {
        renderer.concatenate(transform)
    }

    // Apply x/y positioning
    let x = resolveLength(svg.x, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let y = resolveLength(svg.y, viewRef: context.viewportHeight, fontSize: context.fontSize)
    if x != 0 || y != 0 {
        renderer.concatenate(.translation(x: x, y: y))
    }

    // Resolve nested SVG's viewport dimensions
    let nestedWidth = svg.width.map { resolveLength($0, viewRef: context.viewportWidth, fontSize: context.fontSize) }
        ?? svg.viewBox?.width
    let nestedHeight = svg.height.map { resolveLength($0, viewRef: context.viewportHeight, fontSize: context.fontSize) }
        ?? svg.viewBox?.height

    // Apply clipping to the viewport
    if let w = nestedWidth, let h = nestedHeight, w > 0, h > 0 {
        var clipPath = renderer.makePath()
        renderer.addRect(&clipPath, x: 0, y: 0, width: w, height: h, rx: 0, ry: 0)
        renderer.clip(clipPath, rule: .nonzero)
    }

    // Apply viewBox transform
    if let viewBox = svg.viewBox, let w = nestedWidth, let h = nestedHeight {
        let viewBoxTransform = makeViewBoxTransform(
            viewBox: viewBox,
            outputSize: (width: w, height: h),
            preserveAspectRatio: svg.preserveAspectRatio
        )
        if !viewBoxTransform.isIdentity {
            renderer.concatenate(viewBoxTransform)
        }
    }

    // Create new context for nested SVG with new viewport
    // Use document-global definitions (IDs are document-global in SVG)
    let nestedContext = RenderContext(
        presentation: context.presentation,
        transforms: [],  // Transforms already applied above
        viewBox: svg.viewBox,
        viewSize: (svg.width, svg.height),
        definitions: context.definitions,
        opacity: context.opacity
    )

    renderContainer(svg.children, with: renderer, context: nestedContext)
}

private func renderUse<R: SVGRenderer>(
    _ use: Use,
    with renderer: R,
    context: RenderContext
) {
    guard let href = use.href,
          let referenced = context.definitions.elements[href] else {
        return
    }

    // Apply use element's translation
    var childContext = context
    if let x = use.x?.value, x != 0 {
        childContext.transforms.append(.translate(x: x, y: use.y?.value ?? 0))
    } else if let y = use.y?.value, y != 0 {
        childContext.transforms.append(.translate(x: 0, y: y))
    }

    renderElement(referenced, with: renderer, context: childContext)
}

// MARK: - Shape Rendering

private func renderRect<R: SVGRenderer>(
    _ rect: Rect,
    with renderer: R,
    context: RenderContext
) {
    let x = resolveLength(rect.x, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let y = resolveLength(rect.y, viewRef: context.viewportHeight, fontSize: context.fontSize)
    let width = resolveLength(rect.width, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let height = resolveLength(rect.height, viewRef: context.viewportHeight, fontSize: context.fontSize)
    let rx = resolveLength(rect.rx ?? rect.ry, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let ry = resolveLength(rect.ry ?? rect.rx, viewRef: context.viewportHeight, fontSize: context.fontSize)

    var path = renderer.makePath()
    renderer.addRect(&path, x: x, y: y, width: width, height: height, rx: rx, ry: ry)

    drawPath(path, with: renderer, context: context)
}

private func renderCircle<R: SVGRenderer>(
    _ circle: Circle,
    with renderer: R,
    context: RenderContext
) {
    let cx = resolveLength(circle.cx, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let cy = resolveLength(circle.cy, viewRef: context.viewportHeight, fontSize: context.fontSize)
    let r = resolveLength(circle.r, viewRef: min(context.viewportWidth, context.viewportHeight), fontSize: context.fontSize)

    var path = renderer.makePath()
    renderer.addEllipse(&path, cx: cx, cy: cy, rx: r, ry: r)

    drawPath(path, with: renderer, context: context)
}

private func renderEllipse<R: SVGRenderer>(
    _ ellipse: Ellipse,
    with renderer: R,
    context: RenderContext
) {
    let cx = resolveLength(ellipse.cx, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let cy = resolveLength(ellipse.cy, viewRef: context.viewportHeight, fontSize: context.fontSize)
    let rx = resolveLength(ellipse.rx, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let ry = resolveLength(ellipse.ry, viewRef: context.viewportHeight, fontSize: context.fontSize)

    var path = renderer.makePath()
    renderer.addEllipse(&path, cx: cx, cy: cy, rx: rx, ry: ry)

    drawPath(path, with: renderer, context: context)
}

private func renderLine<R: SVGRenderer>(
    _ line: Line,
    with renderer: R,
    context: RenderContext
) {
    let x1 = resolveLength(line.x1, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let y1 = resolveLength(line.y1, viewRef: context.viewportHeight, fontSize: context.fontSize)
    let x2 = resolveLength(line.x2, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let y2 = resolveLength(line.y2, viewRef: context.viewportHeight, fontSize: context.fontSize)

    var path = renderer.makePath()
    renderer.moveTo(&path, x: x1, y: y1)
    renderer.lineTo(&path, x: x2, y: y2)

    // Lines only have stroke, no fill
    strokePath(path, with: renderer, context: context)
}

private func renderPolyline<R: SVGRenderer>(
    _ polyline: Polyline,
    with renderer: R,
    context: RenderContext
) {
    guard let first = polyline.points.first else { return }

    var path = renderer.makePath()
    renderer.moveTo(&path, x: first.x, y: first.y)
    for point in polyline.points.dropFirst() {
        renderer.lineTo(&path, x: point.x, y: point.y)
    }

    drawPath(path, with: renderer, context: context)
}

private func renderPolygon<R: SVGRenderer>(
    _ polygon: Polygon,
    with renderer: R,
    context: RenderContext
) {
    guard let first = polygon.points.first else { return }

    var path = renderer.makePath()
    renderer.moveTo(&path, x: first.x, y: first.y)
    for point in polygon.points.dropFirst() {
        renderer.lineTo(&path, x: point.x, y: point.y)
    }
    renderer.closePath(&path)

    drawPath(path, with: renderer, context: context)
}

private func renderPath<R: SVGRenderer>(
    _ pathElement: Path,
    with renderer: R,
    context: RenderContext
) {
    var path = renderer.makePath()
    buildPath(&path, from: pathElement.segments, with: renderer)

    drawPath(path, with: renderer, context: context)
}

// MARK: - Path Building from Segments

private func buildPath<R: SVGRenderer>(
    _ path: inout R.Path,
    from segments: [PathSegment],
    with renderer: R
) {
    var currentX: Double = 0
    var currentY: Double = 0
    var startX: Double = 0
    var startY: Double = 0
    var lastCubicX: Double?
    var lastCubicY: Double?
    var lastQuadX: Double?
    var lastQuadY: Double?

    for segment in segments {
        switch segment {
        case .moveTo(let point):
            currentX = point.x
            currentY = point.y
            startX = currentX
            startY = currentY
            renderer.moveTo(&path, x: currentX, y: currentY)
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .moveToRelative(let point):
            currentX += point.x
            currentY += point.y
            startX = currentX
            startY = currentY
            renderer.moveTo(&path, x: currentX, y: currentY)
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .lineTo(let point):
            currentX = point.x
            currentY = point.y
            renderer.lineTo(&path, x: currentX, y: currentY)
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .lineToRelative(let point):
            currentX += point.x
            currentY += point.y
            renderer.lineTo(&path, x: currentX, y: currentY)
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .horizontalLineTo(let x):
            currentX = x
            renderer.lineTo(&path, x: currentX, y: currentY)
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .horizontalLineToRelative(let x):
            currentX += x
            renderer.lineTo(&path, x: currentX, y: currentY)
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .verticalLineTo(let y):
            currentY = y
            renderer.lineTo(&path, x: currentX, y: currentY)
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .verticalLineToRelative(let y):
            currentY += y
            renderer.lineTo(&path, x: currentX, y: currentY)
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .curveTo(let c1, let c2, let end):
            renderer.curveTo(&path, cp1x: c1.x, cp1y: c1.y, cp2x: c2.x, cp2y: c2.y, x: end.x, y: end.y)
            currentX = end.x
            currentY = end.y
            lastCubicX = c2.x
            lastCubicY = c2.y
            lastQuadX = nil; lastQuadY = nil

        case .curveToRelative(let c1, let c2, let end):
            let cp1x = currentX + c1.x
            let cp1y = currentY + c1.y
            let cp2x = currentX + c2.x
            let cp2y = currentY + c2.y
            let endX = currentX + end.x
            let endY = currentY + end.y
            renderer.curveTo(&path, cp1x: cp1x, cp1y: cp1y, cp2x: cp2x, cp2y: cp2y, x: endX, y: endY)
            currentX = endX
            currentY = endY
            lastCubicX = cp2x
            lastCubicY = cp2y
            lastQuadX = nil; lastQuadY = nil

        case .smoothCurveTo(let c2, let end):
            let cp1x = reflectPoint(lastCubicX, around: currentX)
            let cp1y = reflectPoint(lastCubicY, around: currentY)
            renderer.curveTo(&path, cp1x: cp1x, cp1y: cp1y, cp2x: c2.x, cp2y: c2.y, x: end.x, y: end.y)
            currentX = end.x
            currentY = end.y
            lastCubicX = c2.x
            lastCubicY = c2.y
            lastQuadX = nil; lastQuadY = nil

        case .smoothCurveToRelative(let c2, let end):
            let cp1x = reflectPoint(lastCubicX, around: currentX)
            let cp1y = reflectPoint(lastCubicY, around: currentY)
            let cp2x = currentX + c2.x
            let cp2y = currentY + c2.y
            let endX = currentX + end.x
            let endY = currentY + end.y
            renderer.curveTo(&path, cp1x: cp1x, cp1y: cp1y, cp2x: cp2x, cp2y: cp2y, x: endX, y: endY)
            currentX = endX
            currentY = endY
            lastCubicX = cp2x
            lastCubicY = cp2y
            lastQuadX = nil; lastQuadY = nil

        case .quadraticCurveTo(let control, let end):
            renderer.quadTo(&path, cpx: control.x, cpy: control.y, x: end.x, y: end.y)
            currentX = end.x
            currentY = end.y
            lastQuadX = control.x
            lastQuadY = control.y
            lastCubicX = nil; lastCubicY = nil

        case .quadraticCurveToRelative(let control, let end):
            let cpx = currentX + control.x
            let cpy = currentY + control.y
            let endX = currentX + end.x
            let endY = currentY + end.y
            renderer.quadTo(&path, cpx: cpx, cpy: cpy, x: endX, y: endY)
            currentX = endX
            currentY = endY
            lastQuadX = cpx
            lastQuadY = cpy
            lastCubicX = nil; lastCubicY = nil

        case .smoothQuadraticCurveTo(let end):
            let cpx = reflectPoint(lastQuadX, around: currentX)
            let cpy = reflectPoint(lastQuadY, around: currentY)
            renderer.quadTo(&path, cpx: cpx, cpy: cpy, x: end.x, y: end.y)
            currentX = end.x
            currentY = end.y
            lastQuadX = cpx
            lastQuadY = cpy
            lastCubicX = nil; lastCubicY = nil

        case .smoothQuadraticCurveToRelative(let end):
            let cpx = reflectPoint(lastQuadX, around: currentX)
            let cpy = reflectPoint(lastQuadY, around: currentY)
            let endX = currentX + end.x
            let endY = currentY + end.y
            renderer.quadTo(&path, cpx: cpx, cpy: cpy, x: endX, y: endY)
            currentX = endX
            currentY = endY
            lastQuadX = cpx
            lastQuadY = cpy
            lastCubicX = nil; lastCubicY = nil

        case .arcTo(let rx, let ry, let rotation, let largeArc, let sweep, let end):
            addArc(&path, with: renderer, from: (currentX, currentY), to: (end.x, end.y),
                   rx: rx, ry: ry, xAxisRotation: rotation, largeArc: largeArc, sweep: sweep)
            currentX = end.x
            currentY = end.y
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .arcToRelative(let rx, let ry, let rotation, let largeArc, let sweep, let end):
            let endX = currentX + end.x
            let endY = currentY + end.y
            addArc(&path, with: renderer, from: (currentX, currentY), to: (endX, endY),
                   rx: rx, ry: ry, xAxisRotation: rotation, largeArc: largeArc, sweep: sweep)
            currentX = endX
            currentY = endY
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil

        case .closePath:
            renderer.closePath(&path)
            currentX = startX
            currentY = startY
            lastCubicX = nil; lastCubicY = nil
            lastQuadX = nil; lastQuadY = nil
        }
    }
}

private func reflectPoint(_ point: Double?, around center: Double) -> Double {
    guard let point else { return center }
    return center * 2 - point
}

// MARK: - Arc Conversion

private func addArc<R: SVGRenderer>(
    _ path: inout R.Path,
    with renderer: R,
    from start: (x: Double, y: Double),
    to end: (x: Double, y: Double),
    rx rxInput: Double,
    ry ryInput: Double,
    xAxisRotation: Double,
    largeArc: Bool,
    sweep: Bool
) {
    var rx = Swift.abs(rxInput)
    var ry = Swift.abs(ryInput)

    guard rx > 0, ry > 0 else {
        renderer.lineTo(&path, x: end.x, y: end.y)
        return
    }

    let phi = xAxisRotation * Double.pi / 180
    let cosPhi = cos(phi)
    let sinPhi = sin(phi)

    let dx = (start.x - end.x) / 2
    let dy = (start.y - end.y) / 2

    let x1p = cosPhi * dx + sinPhi * dy
    let y1p = -sinPhi * dx + cosPhi * dy

    // Scale radii if needed
    let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
    if lambda > 1 {
        let scale = sqrt(lambda)
        rx *= scale
        ry *= scale
    }

    let rxSq = rx * rx
    let rySq = ry * ry
    let x1pSq = x1p * x1p
    let y1pSq = y1p * y1p

    let sign: Double = (largeArc == sweep) ? -1.0 : 1.0
    let numerator = rxSq * rySq - rxSq * y1pSq - rySq * x1pSq
    let denom = rxSq * y1pSq + rySq * x1pSq
    let ratio: Double = denom == 0 ? 0.0 : numerator / denom
    let factor: Double = denom == 0 ? 0.0 : sign * sqrt(Swift.max(0.0, ratio))

    let cxp = factor * (rx * y1p) / ry
    let cyp = factor * (-ry * x1p) / rx

    let cx = cosPhi * cxp - sinPhi * cyp + (start.x + end.x) / 2
    let cy = sinPhi * cxp + cosPhi * cyp + (start.y + end.y) / 2

    let ux = (x1p - cxp) / rx
    let uy = (y1p - cyp) / ry
    let vx = (-x1p - cxp) / rx
    let vy = (-y1p - cyp) / ry

    let startAngle = atan2(uy, ux)
    var deltaAngle = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    if !sweep && deltaAngle > 0 {
        deltaAngle -= 2 * Double.pi
    } else if sweep && deltaAngle < 0 {
        deltaAngle += 2 * Double.pi
    }

    // Split into segments of at most 90 degrees
    let segments = Int(ceil(Swift.abs(deltaAngle / (Double.pi / 2))))
    let anglePerSegment = deltaAngle / Double(segments)

    for i in 0..<segments {
        let t1 = startAngle + Double(i) * anglePerSegment
        let t2 = t1 + anglePerSegment
        addArcSegment(&path, with: renderer, center: (cx, cy), rx: rx, ry: ry,
                      rotation: phi, startAngle: t1, endAngle: t2)
    }
}

private func addArcSegment<R: SVGRenderer>(
    _ path: inout R.Path,
    with renderer: R,
    center: (x: Double, y: Double),
    rx: Double,
    ry: Double,
    rotation: Double,
    startAngle: Double,
    endAngle: Double
) {
    let cosPhi = cos(rotation)
    let sinPhi = sin(rotation)
    let delta = endAngle - startAngle
    let t = tan(delta / 4)
    let alpha = (4.0 / 3.0) * t / (1 + t * t)

    let x1 = rx * cos(startAngle)
    let y1 = ry * sin(startAngle)
    let x2 = rx * cos(endAngle)
    let y2 = ry * sin(endAngle)

    let dx1 = -alpha * rx * sin(startAngle)
    let dy1 = alpha * ry * cos(startAngle)
    let dx2 = alpha * rx * sin(endAngle)
    let dy2 = -alpha * ry * cos(endAngle)

    let endX = center.x + cosPhi * x2 - sinPhi * y2
    let endY = center.y + sinPhi * x2 + cosPhi * y2

    let startXRotated = center.x + cosPhi * x1 - sinPhi * y1
    let startYRotated = center.y + sinPhi * x1 + cosPhi * y1

    let cp1x = startXRotated + cosPhi * dx1 - sinPhi * dy1
    let cp1y = startYRotated + sinPhi * dx1 + cosPhi * dy1
    let cp2x = endX + cosPhi * dx2 - sinPhi * dy2
    let cp2y = endY + sinPhi * dx2 + cosPhi * dy2

    renderer.curveTo(&path, cp1x: cp1x, cp1y: cp1y, cp2x: cp2x, cp2y: cp2y, x: endX, y: endY)
}

// MARK: - Fill and Stroke

private func drawPath<R: SVGRenderer>(
    _ path: R.Path,
    with renderer: R,
    context: RenderContext
) {
    let fillRule = context.presentation.fillRule ?? .nonzero

    // Fill
    if let fillPaint = resolveFill(context.presentation, definitions: context.definitions) {
        switch fillPaint {
        case .color(let color):
            let nativeColor = renderer.makeColor(from: color)
            renderer.fill(path, color: nativeColor, rule: fillRule)
        case .gradient(let gradient):
            renderer.fillGradient(path, gradient: gradient, rule: fillRule)
        case .pattern(let pattern):
            renderer.fillPattern(path, pattern: pattern, rule: fillRule)
        }
    }

    // Stroke
    strokePath(path, with: renderer, context: context)
}

private func strokePath<R: SVGRenderer>(
    _ path: R.Path,
    with renderer: R,
    context: RenderContext
) {
    guard let strokePaint = resolveStroke(context.presentation, definitions: context.definitions) else { return }

    let strokeStyle = StrokeStyle(
        width: context.presentation.strokeWidth?.resolvedValue(fontSize: context.fontSize) ?? 1,
        cap: context.presentation.strokeLineCap ?? .butt,
        join: context.presentation.strokeLineJoin ?? .miter,
        miterLimit: context.presentation.strokeMiterLimit ?? 4,
        dashArray: context.presentation.strokeDashArray?.map { $0.resolvedValue(fontSize: context.fontSize) },
        dashOffset: context.presentation.strokeDashOffset?.resolvedValue(fontSize: context.fontSize) ?? 0
    )

    switch strokePaint {
    case .color(let color):
        let nativeColor = renderer.makeColor(from: color)
        renderer.stroke(path, color: nativeColor, style: strokeStyle)
    case .gradient(let gradient):
        renderer.strokeGradient(path, gradient: gradient, style: strokeStyle)
    case .pattern:
        // Pattern strokes not yet supported
        break
    }
}

// MARK: - Text Rendering

private func renderText<R: SVGRenderer>(
    _ text: Text,
    with renderer: R,
    context: RenderContext
) {
    let x = resolveLength(text.x?.first, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let y = resolveLength(text.y?.first, viewRef: context.viewportHeight, fontSize: context.fontSize)
    let dx = resolveLength(text.dx?.first, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let dy = resolveLength(text.dy?.first, viewRef: context.viewportHeight, fontSize: context.fontSize)

    let runs = buildTextRuns(from: text.content, presentation: context.presentation, viewportHeight: context.viewportHeight)

    let textContent = ResolvedTextContent(
        runs: runs,
        x: x + dx,
        y: y + dy,
        anchor: context.presentation.textAnchor ?? .start
    )

    renderer.drawText(textContent)
}

private func buildTextRuns(
    from content: [TextContent],
    presentation: PresentationAttributes,
    viewportHeight: Double
) -> [ResolvedTextRun] {
    var runs: [ResolvedTextRun] = []
    let baseFontSize = presentation.fontSize?.resolvedValue(viewport: viewportHeight) ?? 16

    for item in content {
        switch item {
        case .text(let text):
            let color = resolveFillColor(from: presentation.fill, currentColor: presentation.color)
            runs.append(ResolvedTextRun(
                text: text,
                fontFamily: presentation.fontFamily,
                fontSize: baseFontSize,
                color: color
            ))
        case .span(let tspan):
            let merged = presentation.merged(with: tspan.presentation)
            runs.append(contentsOf: buildTextRuns(
                from: tspan.content,
                presentation: merged,
                viewportHeight: viewportHeight
            ))
        case .reference(let textPath):
            let merged = presentation.merged(with: textPath.presentation)
            let fontSize = merged.fontSize?.resolvedValue(viewport: viewportHeight) ?? baseFontSize
            let color = resolveFillColor(from: merged.fill, currentColor: merged.color)
            runs.append(ResolvedTextRun(
                text: textPath.content,
                fontFamily: merged.fontFamily,
                fontSize: fontSize,
                color: color
            ))
        }
    }
    return runs
}

// MARK: - Image Rendering

private func renderImage<R: SVGRenderer>(
    _ image: Image,
    with renderer: R,
    context: RenderContext
) {
    guard let href = image.href,
          href.hasPrefix("data:"),
          let resolved = decodeDataURL(href) else {
        return
    }

    let x = resolveLength(image.x, viewRef: context.viewportWidth, fontSize: context.fontSize)
    let y = resolveLength(image.y, viewRef: context.viewportHeight, fontSize: context.fontSize)
    let width = image.width.map { resolveLength($0, viewRef: context.viewportWidth, fontSize: context.fontSize) } ?? 0
    let height = image.height.map { resolveLength($0, viewRef: context.viewportHeight, fontSize: context.fontSize) } ?? 0

    let content = ResolvedImageContent(
        data: resolved.data,
        mimeType: resolved.mimeType,
        x: x,
        y: y,
        width: width,
        height: height
    )

    renderer.drawImage(content)
}

private func decodeDataURL(_ href: String) -> (data: Data, mimeType: String?)? {
    let parts = href.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2 else { return nil }

    let meta = String(parts[0])
    let payload = String(parts[1])
    guard meta.contains("base64"),
          let data = Data(base64Encoded: payload) else {
        return nil
    }

    let mimeType = meta
        .dropFirst("data:".count)
        .split(separator: ";", maxSplits: 1)
        .first
        .map(String.init)

    return (data, mimeType)
}

// MARK: - Clip Path

private func applyClipPath<R: SVGRenderer>(
    _ clipPath: ClipPath,
    with renderer: R,
    context: RenderContext
) {
    var path = renderer.makePath()
    buildClipPath(&path, from: clipPath, with: renderer, context: context)
    let clipRule = context.presentation.fillRule ?? .nonzero
    renderer.clip(path, rule: clipRule)
}

private func buildClipPath<R: SVGRenderer>(
    _ path: inout R.Path,
    from clipPath: ClipPath,
    with renderer: R,
    context: RenderContext
) {
    for child in clipPath.children {
        // Get the transform for this element if any
        let transform: AffineTransform? = {
            guard let transforms = child.presentation.transform else {
                return nil
            }
            return makeAffineTransformOptional(from: transforms)
        }()

        // Helper to apply transform to a point
        func transformPoint(x: Double, y: Double) -> (x: Double, y: Double) {
            guard let t = transform else { return (x, y) }
            return (
                x: t.a * x + t.c * y + t.tx,
                y: t.b * x + t.d * y + t.ty
            )
        }

        if let rect = child as? Rect {
            let x = resolveLength(rect.x, viewRef: context.viewportWidth, fontSize: context.fontSize)
            let y = resolveLength(rect.y, viewRef: context.viewportHeight, fontSize: context.fontSize)
            let width = resolveLength(rect.width, viewRef: context.viewportWidth, fontSize: context.fontSize)
            let height = resolveLength(rect.height, viewRef: context.viewportHeight, fontSize: context.fontSize)
            let rx = resolveLength(rect.rx ?? rect.ry, viewRef: context.viewportWidth, fontSize: context.fontSize)
            let ry = resolveLength(rect.ry ?? rect.rx, viewRef: context.viewportHeight, fontSize: context.fontSize)

            if transform != nil {
                // For transformed rects, we need to build the path manually
                // since addRect doesn't support transforms
                let corners = [
                    (x: x, y: y),
                    (x: x + width, y: y),
                    (x: x + width, y: y + height),
                    (x: x, y: y + height)
                ].map { transformPoint(x: $0.x, y: $0.y) }

                renderer.moveTo(&path, x: corners[0].x, y: corners[0].y)
                renderer.lineTo(&path, x: corners[1].x, y: corners[1].y)
                renderer.lineTo(&path, x: corners[2].x, y: corners[2].y)
                renderer.lineTo(&path, x: corners[3].x, y: corners[3].y)
                renderer.closePath(&path)
            } else {
                renderer.addRect(&path, x: x, y: y, width: width, height: height, rx: rx, ry: ry)
            }
        } else if let circle = child as? Circle {
            let cx = resolveLength(circle.cx, viewRef: context.viewportWidth, fontSize: context.fontSize)
            let cy = resolveLength(circle.cy, viewRef: context.viewportHeight, fontSize: context.fontSize)
            let r = resolveLength(circle.r, viewRef: min(context.viewportWidth, context.viewportHeight), fontSize: context.fontSize)

            if let t = transform {
                // Transform center and approximate radius scaling
                let center = transformPoint(x: cx, y: cy)
                let scaleX = sqrt(t.a * t.a + t.b * t.b)
                let scaleY = sqrt(t.c * t.c + t.d * t.d)
                renderer.addEllipse(&path, cx: center.x, cy: center.y, rx: r * scaleX, ry: r * scaleY)
            } else {
                renderer.addEllipse(&path, cx: cx, cy: cy, rx: r, ry: r)
            }
        } else if let ellipse = child as? Ellipse {
            let cx = resolveLength(ellipse.cx, viewRef: context.viewportWidth, fontSize: context.fontSize)
            let cy = resolveLength(ellipse.cy, viewRef: context.viewportHeight, fontSize: context.fontSize)
            let rx = resolveLength(ellipse.rx, viewRef: context.viewportWidth, fontSize: context.fontSize)
            let ry = resolveLength(ellipse.ry, viewRef: context.viewportHeight, fontSize: context.fontSize)

            if let t = transform {
                let center = transformPoint(x: cx, y: cy)
                let scaleX = sqrt(t.a * t.a + t.b * t.b)
                let scaleY = sqrt(t.c * t.c + t.d * t.d)
                renderer.addEllipse(&path, cx: center.x, cy: center.y, rx: rx * scaleX, ry: ry * scaleY)
            } else {
                renderer.addEllipse(&path, cx: cx, cy: cy, rx: rx, ry: ry)
            }
        } else if let polygon = child as? Polygon, let first = polygon.points.first {
            let firstTransformed = transformPoint(x: first.x, y: first.y)
            renderer.moveTo(&path, x: firstTransformed.x, y: firstTransformed.y)
            for point in polygon.points.dropFirst() {
                let pt = transformPoint(x: point.x, y: point.y)
                renderer.lineTo(&path, x: pt.x, y: pt.y)
            }
            renderer.closePath(&path)
        } else if let pathElement = child as? Path {
            if let t = transform {
                // Transform path segments
                func transformPt(_ p: Point) -> Point {
                    Point(
                        x: t.a * p.x + t.c * p.y + t.tx,
                        y: t.b * p.x + t.d * p.y + t.ty
                    )
                }
                let transformedSegments = pathElement.segments.map { segment -> PathSegment in
                    switch segment {
                    case .moveTo(let point):
                        return .moveTo(transformPt(point))
                    case .moveToRelative(let point):
                        // Relative moves: only transform the delta (no translation)
                        return .moveToRelative(Point(x: t.a * point.x + t.c * point.y, y: t.b * point.x + t.d * point.y))
                    case .lineTo(let point):
                        return .lineTo(transformPt(point))
                    case .lineToRelative(let point):
                        return .lineToRelative(Point(x: t.a * point.x + t.c * point.y, y: t.b * point.x + t.d * point.y))
                    case .horizontalLineTo(let x):
                        // Convert to lineTo since transform may affect both axes
                        return .lineTo(transformPt(Point(x: x, y: 0)))
                    case .horizontalLineToRelative(let dx):
                        return .lineToRelative(Point(x: t.a * dx, y: t.b * dx))
                    case .verticalLineTo(let y):
                        return .lineTo(transformPt(Point(x: 0, y: y)))
                    case .verticalLineToRelative(let dy):
                        return .lineToRelative(Point(x: t.c * dy, y: t.d * dy))
                    case .curveTo(let control1, let control2, let end):
                        return .curveTo(control1: transformPt(control1), control2: transformPt(control2), end: transformPt(end))
                    case .curveToRelative(let control1, let control2, let end):
                        return .curveToRelative(
                            control1: Point(x: t.a * control1.x + t.c * control1.y, y: t.b * control1.x + t.d * control1.y),
                            control2: Point(x: t.a * control2.x + t.c * control2.y, y: t.b * control2.x + t.d * control2.y),
                            end: Point(x: t.a * end.x + t.c * end.y, y: t.b * end.x + t.d * end.y)
                        )
                    case .smoothCurveTo(let control2, let end):
                        return .smoothCurveTo(control2: transformPt(control2), end: transformPt(end))
                    case .smoothCurveToRelative(let control2, let end):
                        return .smoothCurveToRelative(
                            control2: Point(x: t.a * control2.x + t.c * control2.y, y: t.b * control2.x + t.d * control2.y),
                            end: Point(x: t.a * end.x + t.c * end.y, y: t.b * end.x + t.d * end.y)
                        )
                    case .quadraticCurveTo(let control, let end):
                        return .quadraticCurveTo(control: transformPt(control), end: transformPt(end))
                    case .quadraticCurveToRelative(let control, let end):
                        return .quadraticCurveToRelative(
                            control: Point(x: t.a * control.x + t.c * control.y, y: t.b * control.x + t.d * control.y),
                            end: Point(x: t.a * end.x + t.c * end.y, y: t.b * end.x + t.d * end.y)
                        )
                    case .smoothQuadraticCurveTo(let point):
                        return .smoothQuadraticCurveTo(transformPt(point))
                    case .smoothQuadraticCurveToRelative(let point):
                        return .smoothQuadraticCurveToRelative(Point(x: t.a * point.x + t.c * point.y, y: t.b * point.x + t.d * point.y))
                    case .arcTo(let rx, let ry, let xAxisRotation, let largeArcFlag, let sweepFlag, let end):
                        // Arc radii need special handling with transforms, but for simple translate this works
                        return .arcTo(rx: rx, ry: ry, xAxisRotation: xAxisRotation, largeArcFlag: largeArcFlag, sweepFlag: sweepFlag, end: transformPt(end))
                    case .arcToRelative(let rx, let ry, let xAxisRotation, let largeArcFlag, let sweepFlag, let end):
                        return .arcToRelative(rx: rx, ry: ry, xAxisRotation: xAxisRotation, largeArcFlag: largeArcFlag, sweepFlag: sweepFlag, end: Point(x: t.a * end.x + t.c * end.y, y: t.b * end.x + t.d * end.y))
                    case .closePath:
                        return .closePath
                    }
                }
                buildPath(&path, from: transformedSegments, with: renderer)
            } else {
                buildPath(&path, from: pathElement.segments, with: renderer)
            }
        } else if let group = child as? Group {
            for groupChild in group.children {
                // Create a ClipPath wrapper for each child
                let subClip = ClipPath(id: nil, clipPathUnits: clipPath.clipPathUnits, children: [groupChild])
                buildClipPath(&path, from: subClip, with: renderer, context: context)
            }
        }
    }
}

// MARK: - Paint Resolution

private enum ResolvedPaint2 {
    case color(ResolvedColor)
    case gradient(ResolvedGradient)
    case pattern(ResolvedPattern)
}

private func resolveFill(
    _ presentation: PresentationAttributes,
    definitions: Definitions
) -> ResolvedPaint2? {
    let currentColor = presentation.color

    guard let fill = presentation.fill else {
        // Default fill is black
        let resolved = ResolvedColor.black
        return applyOpacity(resolved, presentation: presentation)
    }

    switch fill {
    case .none:
        return nil
    case .color(let color):
        let resolved = resolveColorToResolved(color, currentColor: currentColor)
        return applyOpacity(resolved, presentation: presentation)
    case .url(let ref):
        return resolveReference(ref, definitions: definitions, presentation: presentation)
    case .urlWithFallback(let ref, let fallback):
        if let paint = resolveReference(ref, definitions: definitions, presentation: presentation) {
            return paint
        }
        let resolved = resolveColorToResolved(fallback, currentColor: currentColor)
        return applyOpacity(resolved, presentation: presentation)
    }
}

private func applyOpacity(_ color: ResolvedColor, presentation: PresentationAttributes) -> ResolvedPaint2 {
    let opacity = presentation.opacity ?? 1
    let fillOpacity = presentation.fillOpacity ?? 1
    var adjusted = color
    adjusted.alpha *= opacity * fillOpacity
    return .color(adjusted)
}

private func resolveReference(
    _ ref: String,
    definitions: Definitions,
    presentation: PresentationAttributes
) -> ResolvedPaint2? {
    if let gradient = definitions.gradients[ref] {
        return resolveGradient(gradient, presentation: presentation)
    }
    if let pattern = definitions.patterns[ref] {
        return resolvePattern(pattern)
    }
    return nil
}

private func resolveGradient(
    _ gradient: any GradientElement,
    presentation: PresentationAttributes
) -> ResolvedPaint2? {
    let fillOpacity = presentation.fillOpacity ?? 1
    return resolveGradientWithOpacity(gradient, presentation: presentation, paintOpacity: fillOpacity)
}

private func resolveGradientWithOpacity(
    _ gradient: any GradientElement,
    presentation: PresentationAttributes,
    paintOpacity: Double
) -> ResolvedPaint2? {
    let opacity = presentation.opacity ?? 1
    let alpha = opacity * paintOpacity
    let currentColor = presentation.color

    if let linear = gradient as? LinearGradient {
        let stops = linear.stops.map { stop in
            var color = resolveColorToResolved(stop.color, currentColor: currentColor)
            color.alpha *= alpha * (stop.opacity ?? 1)
            return ResolvedGradientStop(offset: stop.offset, color: color)
        }
        let gradientTransform = linear.gradientTransform.flatMap { makeAffineTransformOptional(from: $0) }
        let resolved = ResolvedLinearGradient(
            startX: linear.x1?.value ?? 0,
            startY: linear.y1?.value ?? 0,
            endX: linear.x2?.value ?? 1,
            endY: linear.y2?.value ?? 0,
            stops: stops,
            spreadMethod: linear.spreadMethod ?? .pad,
            gradientUnits: linear.gradientUnits ?? .objectBoundingBox,
            gradientTransform: gradientTransform
        )
        return .gradient(.linear(resolved))
    }

    if let radial = gradient as? RadialGradient {
        let stops = radial.stops.map { stop in
            var color = resolveColorToResolved(stop.color, currentColor: currentColor)
            color.alpha *= alpha * (stop.opacity ?? 1)
            return ResolvedGradientStop(offset: stop.offset, color: color)
        }
        let cx = radial.cx?.value ?? 0.5
        let cy = radial.cy?.value ?? 0.5
        let gradientTransform = radial.gradientTransform.flatMap { makeAffineTransformOptional(from: $0) }
        let resolved = ResolvedRadialGradient(
            centerX: cx,
            centerY: cy,
            radius: radial.r?.value ?? 0.5,
            focalX: radial.fx?.value ?? cx,
            focalY: radial.fy?.value ?? cy,
            stops: stops,
            spreadMethod: radial.spreadMethod ?? .pad,
            gradientUnits: radial.gradientUnits ?? .objectBoundingBox,
            gradientTransform: gradientTransform
        )
        return .gradient(.radial(resolved))
    }

    return nil
}

private func resolvePattern(_ pattern: Pattern) -> ResolvedPaint2? {
    // Create a minimal SVG for the pattern content
    let patternSVG = SVG(
        width: pattern.width,
        height: pattern.height,
        viewBox: pattern.viewBox,
        children: pattern.children
    )

    let resolved = ResolvedPattern(
        tileX: pattern.x?.value ?? 0,
        tileY: pattern.y?.value ?? 0,
        tileWidth: pattern.width?.value ?? 0,
        tileHeight: pattern.height?.value ?? 0,
        content: patternSVG,
        transform: pattern.patternTransform.flatMap { makeAffineTransformOptional(from: $0) },
        patternUnits: pattern.patternUnits ?? .objectBoundingBox,
        patternContentUnits: pattern.patternContentUnits ?? .userSpaceOnUse
    )
    return .pattern(resolved)
}

private func resolveStroke(
    _ presentation: PresentationAttributes,
    definitions: Definitions
) -> ResolvedPaint2? {
    let currentColor = presentation.color

    guard let stroke = presentation.stroke else {
        return nil
    }

    switch stroke {
    case .none:
        return nil
    case .color(let color):
        var resolved = resolveColorToResolved(color, currentColor: currentColor)
        let opacity = presentation.opacity ?? 1
        let strokeOpacity = presentation.strokeOpacity ?? 1
        resolved.alpha *= opacity * strokeOpacity
        return .color(resolved)
    case .url(let ref):
        return resolveStrokeReference(ref, definitions: definitions, presentation: presentation)
    case .urlWithFallback(let ref, let fallback):
        if let paint = resolveStrokeReference(ref, definitions: definitions, presentation: presentation) {
            return paint
        }
        var resolved = resolveColorToResolved(fallback, currentColor: currentColor)
        let opacity = presentation.opacity ?? 1
        let strokeOpacity = presentation.strokeOpacity ?? 1
        resolved.alpha *= opacity * strokeOpacity
        return .color(resolved)
    }
}

private func resolveStrokeReference(
    _ ref: String,
    definitions: Definitions,
    presentation: PresentationAttributes
) -> ResolvedPaint2? {
    if let gradient = definitions.gradients[ref] {
        return resolveGradientForStroke(gradient, presentation: presentation)
    }
    // Pattern strokes not yet supported
    return nil
}

private func resolveGradientForStroke(
    _ gradient: any GradientElement,
    presentation: PresentationAttributes
) -> ResolvedPaint2? {
    let strokeOpacity = presentation.strokeOpacity ?? 1
    return resolveGradientWithOpacity(gradient, presentation: presentation, paintOpacity: strokeOpacity)
}

private func resolveFillColor(from fill: Fill?, currentColor: Color?) -> ResolvedColor {
    guard let fill else {
        return .black
    }

    switch fill {
    case .none:
        return .clear
    case .color(let color):
        return resolveColorToResolved(color, currentColor: currentColor)
    case .urlWithFallback(_, let fallback):
        return resolveColorToResolved(fallback, currentColor: currentColor)
    case .url:
        return .black
    }
}

private func resolveColorToResolved(_ color: Color, currentColor: Color? = nil) -> ResolvedColor {
    switch color {
    case .none:
        return .clear
    case .currentColor:
        if let current = currentColor {
            return resolveColorToResolved(current, currentColor: nil)
        }
        return .black
    case .rgb(let r, let g, let b):
        return ResolvedColor(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    case .rgba(let r, let g, let b, let a):
        return ResolvedColor(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: a)
    case .p3(let r, let g, let b, let a):
        return ResolvedColor(red: r, green: g, blue: b, alpha: a, colorSpace: .displayP3)
    case .named(let name):
        if let resolved = Color.namedColors[name] {
            return resolveColorToResolved(resolved, currentColor: currentColor)
        }
        return .black
    }
}

// MARK: - Context Inheritance

private func inheritContext(
    _ parent: RenderContext,
    element: any GraphicElement
) -> RenderContext {
    let presentation = parent.presentation.merged(with: element.presentation)

    var transforms = parent.transforms
    if let local = element.presentation.transform {
        transforms.append(contentsOf: local)
    }

    let elementOpacity = element.presentation.opacity ?? 1

    return RenderContext(
        presentation: presentation,
        transforms: transforms,
        viewBox: parent.viewBox,
        viewSize: parent.viewSize,
        definitions: parent.definitions,
        opacity: parent.opacity * elementOpacity
    )
}

// MARK: - Transform Conversion

private func makeAffineTransform(from transforms: [Transform]) -> AffineTransform {
    var result = AffineTransform.identity
    for transform in transforms {
        let t = convertTransform(transform)
        // SVG transforms are applied right-to-left: transform="A B C" means C first, then B, then A
        // So we pre-multiply each transform: result = t * result
        result = t.concatenating(result)
    }
    return result
}

private func makeAffineTransformOptional(from transforms: [Transform]) -> AffineTransform? {
    let result = makeAffineTransform(from: transforms)
    return result.isIdentity ? nil : result
}

private func makeViewBoxTransform(
    viewBox: ViewBox,
    outputSize: (width: Double, height: Double),
    preserveAspectRatio: PreserveAspectRatio?
) -> AffineTransform {
    let scaleX = outputSize.width / viewBox.width
    let scaleY = outputSize.height / viewBox.height
    let alignment = preserveAspectRatio?.alignment ?? .xMidYMid
    let meetOrSlice = preserveAspectRatio?.meetOrSlice ?? .meet

    if alignment == .none {
        // For preserveAspectRatio="none", apply non-uniform scaling to fit viewBox to viewport
        return AffineTransform.translation(x: -viewBox.minX, y: -viewBox.minY)
            .concatenating(.scale(x: scaleX, y: scaleY))
    }

    let scale = meetOrSlice == .slice ? max(scaleX, scaleY) : min(scaleX, scaleY)
    let scaledWidth = viewBox.width * scale
    let scaledHeight = viewBox.height * scale

    let offsetX = alignmentOffset(
        alignment: alignment,
        start: 0,
        end: outputSize.width - scaledWidth
    )
    let offsetY = alignmentOffset(
        alignment: alignment,
        start: 0,
        end: outputSize.height - scaledHeight
    )

    // Transform order: translate viewBox to origin, scale uniformly, then offset for alignment
    return AffineTransform.translation(x: -viewBox.minX, y: -viewBox.minY)
        .concatenating(.scale(x: scale, y: scale))
        .concatenating(.translation(x: offsetX, y: offsetY))
}

private func alignmentOffset(
    alignment: PreserveAspectRatio.Alignment,
    start: Double,
    end: Double
) -> Double {
    switch alignment {
    case .xMinYMin, .xMinYMid, .xMinYMax:
        return start
    case .xMidYMin, .xMidYMid, .xMidYMax:
        return (start + end) / 2
    case .xMaxYMin, .xMaxYMid, .xMaxYMax:
        return end
    case .none:
        return start
    }
}

private func convertTransform(_ transform: Transform) -> AffineTransform {
    switch transform {
    case .matrix(let a, let b, let c, let d, let e, let f):
        return AffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
    case .translate(let x, let y):
        return AffineTransform.translation(x: x, y: y)
    case .scale(let x, let y):
        return AffineTransform.scale(x: x, y: y)
    case .rotate(let angle, let cx, let cy):
        let radians = angle * Double.pi / 180
        if let cx, let cy {
            // Rotate around (cx, cy): translate so (cx, cy) is at origin, rotate, translate back
            return AffineTransform.translation(x: -cx, y: -cy)
                .concatenating(.rotation(radians: radians))
                .concatenating(.translation(x: cx, y: cy))
        }
        return AffineTransform.rotation(radians: radians)
    case .skewX(let angle):
        let t = tan(angle * Double.pi / 180)
        return AffineTransform(a: 1, b: 0, c: t, d: 1, tx: 0, ty: 0)
    case .skewY(let angle):
        let t = tan(angle * Double.pi / 180)
        return AffineTransform(a: 1, b: t, c: 0, d: 1, tx: 0, ty: 0)
    }
}

// MARK: - Length Resolution

private func resolveLength(_ length: Length?, viewRef: Double, fontSize: Double) -> Double {
    guard let length else { return 0 }
    return length.resolvedValue(fontSize: fontSize, viewport: viewRef)
}
