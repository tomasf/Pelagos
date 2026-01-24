#if canImport(CoreGraphics)
@preconcurrency import CoreGraphics
import Foundation

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
            return drawShape(context: context, drawContext: drawContext) {
                let rx = rect.rx?.value ?? rect.ry?.value ?? 0
                let ry = rect.ry?.value ?? rect.rx?.value ?? 0
                let rectFrame = CGRect(x: rect.x.value, y: rect.y.value, width: rect.width.value, height: rect.height.value)
                if rx > 0 || ry > 0 {
                    $0.addPath(CGPath(roundedRect: rectFrame, cornerWidth: rx, cornerHeight: ry, transform: nil))
                } else {
                    $0.addRect(rectFrame)
                }
            }

        case .drawCircle(let circle):
            return drawShape(context: context, drawContext: drawContext) {
                let rect = CGRect(
                    x: circle.cx.value - circle.r.value,
                    y: circle.cy.value - circle.r.value,
                    width: circle.r.value * 2,
                    height: circle.r.value * 2
                )
                $0.addEllipse(in: rect)
            }

        case .drawEllipse(let ellipse):
            return drawShape(context: context, drawContext: drawContext) {
                let rect = CGRect(
                    x: ellipse.cx.value - ellipse.rx.value,
                    y: ellipse.cy.value - ellipse.ry.value,
                    width: ellipse.rx.value * 2,
                    height: ellipse.ry.value * 2
                )
                $0.addEllipse(in: rect)
            }

        case .drawLine(let line):
            return drawShape(context: context, drawContext: drawContext) {
                $0.move(to: CGPoint(x: line.x1.value, y: line.y1.value))
                $0.addLine(to: CGPoint(x: line.x2.value, y: line.y2.value))
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

        case .drawText, .drawImage:
            return .continue
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
    context.addPath(path)

    let presentation = drawContext.presentation
    let shouldFill = shouldFillPath(presentation)
    let shouldStroke = shouldStrokePath(presentation)
    let fillRule = presentation.fillRule ?? .nonzero

    applyPresentation(presentation, to: context)

    if shouldFill, case .url(let reference) = presentation.fill ?? .none {
        if let gradient = drawContext.definitions.gradients[reference] {
            if drawGradient(
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
        }
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

private func applyPresentation(_ presentation: PresentationAttributes, to context: CGContext) {
    let opacity = presentation.opacity ?? 1

    if let fillColor = colorForFill(presentation.fill, opacity: opacity, fillOpacity: presentation.fillOpacity) {
        context.setFillColor(fillColor)
    }

    if let strokeColor = colorForStroke(presentation.stroke, opacity: opacity, strokeOpacity: presentation.strokeOpacity) {
        context.setStrokeColor(strokeColor)
    }

    if let width = presentation.strokeWidth?.value {
        context.setLineWidth(width)
    }

    if let lineCap = presentation.strokeLineCap {
        switch lineCap {
        case .butt: context.setLineCap(.butt)
        case .round: context.setLineCap(.round)
        case .square: context.setLineCap(.square)
        }
    }

    if let lineJoin = presentation.strokeLineJoin {
        switch lineJoin {
        case .round: context.setLineJoin(.round)
        case .bevel: context.setLineJoin(.bevel)
        case .miter, .miterClip, .arcs: context.setLineJoin(.miter)
        }
    }

    if let miter = presentation.strokeMiterLimit {
        context.setMiterLimit(miter)
    }

    if let dashArray = presentation.strokeDashArray {
        let lengths = dashArray.map { CGFloat($0.value) }
        let phase = CGFloat(presentation.strokeDashOffset?.value ?? 0)
        context.setLineDash(phase: phase, lengths: lengths)
    }
}

private func shouldFillPath(_ presentation: PresentationAttributes) -> Bool {
    if let fill = presentation.fill {
        return fill != .none
    }
    return true
}

private func shouldStrokePath(_ presentation: PresentationAttributes) -> Bool {
    if let stroke = presentation.stroke {
        return stroke != .none
    }
    return false
}

private func colorForFill(_ fill: Fill?, opacity: Double, fillOpacity: Double?) -> CGColor? {
    guard let fill else {
        return cgColor(from: .black, opacity: opacity)
    }
    switch fill {
    case .none:
        return nil
    case .color(let color):
        return cgColor(from: color, opacity: opacity * (fillOpacity ?? 1))
    case .url:
        return nil
    case .urlWithFallback(_, let fallback):
        return cgColor(from: fallback, opacity: opacity * (fillOpacity ?? 1))
    }
}

private func colorForStroke(_ stroke: Fill?, opacity: Double, strokeOpacity: Double?) -> CGColor? {
    guard let stroke else { return nil }
    switch stroke {
    case .none:
        return nil
    case .color(let color):
        return cgColor(from: color, opacity: opacity * (strokeOpacity ?? 1))
    case .url:
        return nil
    case .urlWithFallback(_, let fallback):
        return cgColor(from: fallback, opacity: opacity * (strokeOpacity ?? 1))
    }
}

private func drawGradient(
    context: CGContext,
    path: CGPath,
    gradient: any GradientElement,
    presentation: PresentationAttributes,
    drawContext: DrawContext
) -> Bool {
    let stops = gradient.stops.isEmpty ? nil : gradient.stops
    guard let stops else { return false }

    let bbox = path.boundingBoxOfPath
    let units = gradient.gradientUnits ?? .objectBoundingBox
    let viewRefWidth = drawContext.viewBox?.width ?? drawContext.viewSize.width?.value ?? bbox.width
    let viewRefHeight = drawContext.viewBox?.height ?? drawContext.viewSize.height?.value ?? bbox.height

    let colors = stops.compactMap { stop -> CGColor? in
        let opacity = presentation.opacity ?? 1
        let alpha = opacity * (stop.opacity ?? 1)
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
        return value
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
        return value
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
