import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(CoreGraphics)
func buildPath(from segments: [PathSegment]) -> CGPath {
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

    let segments = Int(ceil(Swift.abs(deltaAngle / (Double.pi / 2))))
    let anglePerSegment = deltaAngle / Double(segments)

    for index in 0..<segments {
        let t1 = startAngle + Double(index) * anglePerSegment
        let t2 = t1 + anglePerSegment
        addArcSegment(
            to: path,
            center: CGPoint(x: cx, y: cy),
            rx: rxAdj,
            ry: ryAdj,
            rotation: phi,
            startAngle: t1,
            endAngle: t2
        )
    }
}

private func addArcSegment(
    to path: CGMutablePath,
    center: CGPoint,
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
    let alpha = (4 / 3) * t / (1 + t * t)

    let x1 = rx * cos(startAngle)
    let y1 = ry * sin(startAngle)
    let x2 = rx * cos(endAngle)
    let y2 = ry * sin(endAngle)

    let dx1 = -alpha * rx * sin(startAngle)
    let dy1 = alpha * ry * cos(startAngle)
    let dx2 = alpha * rx * sin(endAngle)
    let dy2 = -alpha * ry * cos(endAngle)

    let start = CGPoint(
        x: center.x + cosPhi * x1 - sinPhi * y1,
        y: center.y + sinPhi * x1 + cosPhi * y1
    )
    let end = CGPoint(
        x: center.x + cosPhi * x2 - sinPhi * y2,
        y: center.y + sinPhi * x2 + cosPhi * y2
    )
    let control1 = CGPoint(
        x: start.x + cosPhi * dx1 - sinPhi * dy1,
        y: start.y + sinPhi * dx1 + cosPhi * dy1
    )
    let control2 = CGPoint(
        x: end.x + cosPhi * dx2 - sinPhi * dy2,
        y: end.y + sinPhi * dx2 + cosPhi * dy2
    )

    if path.isEmpty {
        path.move(to: start)
    }

    path.addCurve(to: end, control1: control1, control2: control2)
}
#endif
