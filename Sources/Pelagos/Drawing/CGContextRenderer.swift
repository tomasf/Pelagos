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
            return drawShape(context: context, presentation: drawContext.presentation, transforms: drawContext.transforms) {
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
            return drawShape(context: context, presentation: drawContext.presentation, transforms: drawContext.transforms) {
                let rect = CGRect(
                    x: circle.cx.value - circle.r.value,
                    y: circle.cy.value - circle.r.value,
                    width: circle.r.value * 2,
                    height: circle.r.value * 2
                )
                $0.addEllipse(in: rect)
            }

        case .drawEllipse(let ellipse):
            return drawShape(context: context, presentation: drawContext.presentation, transforms: drawContext.transforms) {
                let rect = CGRect(
                    x: ellipse.cx.value - ellipse.rx.value,
                    y: ellipse.cy.value - ellipse.ry.value,
                    width: ellipse.rx.value * 2,
                    height: ellipse.ry.value * 2
                )
                $0.addEllipse(in: rect)
            }

        case .drawLine(let line):
            return drawShape(context: context, presentation: drawContext.presentation, transforms: drawContext.transforms) {
                $0.move(to: CGPoint(x: line.x1.value, y: line.y1.value))
                $0.addLine(to: CGPoint(x: line.x2.value, y: line.y2.value))
            }

        case .drawPolyline(let polyline):
            return drawShape(context: context, presentation: drawContext.presentation, transforms: drawContext.transforms) {
                guard let first = polyline.points.first else { return }
                $0.move(to: CGPoint(x: first.x, y: first.y))
                for point in polyline.points.dropFirst() {
                    $0.addLine(to: CGPoint(x: point.x, y: point.y))
                }
            }

        case .drawPolygon(let polygon):
            return drawShape(context: context, presentation: drawContext.presentation, transforms: drawContext.transforms) {
                guard let first = polygon.points.first else { return }
                $0.move(to: CGPoint(x: first.x, y: first.y))
                for point in polygon.points.dropFirst() {
                    $0.addLine(to: CGPoint(x: point.x, y: point.y))
                }
                $0.closeSubpath()
            }

        case .drawPath(let path):
            return drawShape(context: context, presentation: drawContext.presentation, transforms: drawContext.transforms) {
                $0.addPath(buildPath(from: path.segments))
            }

        case .drawText, .drawImage:
            return .continue
        }
    }
}

private func drawShape(
    context: CGContext,
    presentation: PresentationAttributes,
    transforms: [Transform],
    draw: (CGMutablePath) -> Void
) -> DrawDirective {
    context.saveGState()
    defer { context.restoreGState() }

    let transform = makeTransform(from: transforms)
    context.concatenate(transform)

    applyPresentation(presentation, to: context)

    let path = CGMutablePath()
    draw(path)
    context.addPath(path)

    let shouldFill = shouldFillPath(presentation)
    let shouldStroke = shouldStrokePath(presentation)
    let fillRule = presentation.fillRule ?? .nonzero

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
    case .url, .urlWithFallback:
        return nil
    }
}

private func colorForStroke(_ stroke: Fill?, opacity: Double, strokeOpacity: Double?) -> CGColor? {
    guard let stroke else { return nil }
    switch stroke {
    case .none:
        return nil
    case .color(let color):
        return cgColor(from: color, opacity: opacity * (strokeOpacity ?? 1))
    case .url, .urlWithFallback:
        return nil
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

        case .arcTo(_, _, _, _, _, let end):
            let endPoint = CGPoint(x: end.x, y: end.y)
            path.addLine(to: endPoint)
            current = endPoint
            lastCubic = nil
            lastQuad = nil

        case .arcToRelative(_, _, _, _, _, let end):
            let endPoint = CGPoint(x: current.x + end.x, y: current.y + end.y)
            path.addLine(to: endPoint)
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
#endif
#endif
