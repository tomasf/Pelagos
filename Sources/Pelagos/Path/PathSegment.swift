import Foundation

/// A segment in an SVG path
public enum PathSegment: Hashable, Sendable {
    // Move commands
    case moveTo(Point)
    case moveToRelative(Point)

    // Line commands
    case lineTo(Point)
    case lineToRelative(Point)
    case horizontalLineTo(Double)
    case horizontalLineToRelative(Double)
    case verticalLineTo(Double)
    case verticalLineToRelative(Double)

    // Cubic Bézier commands
    case curveTo(control1: Point, control2: Point, end: Point)
    case curveToRelative(control1: Point, control2: Point, end: Point)
    case smoothCurveTo(control2: Point, end: Point)
    case smoothCurveToRelative(control2: Point, end: Point)

    // Quadratic Bézier commands
    case quadraticCurveTo(control: Point, end: Point)
    case quadraticCurveToRelative(control: Point, end: Point)
    case smoothQuadraticCurveTo(Point)
    case smoothQuadraticCurveToRelative(Point)

    // Arc command
    case arcTo(rx: Double, ry: Double, xAxisRotation: Double, largeArcFlag: Bool, sweepFlag: Bool, end: Point)
    case arcToRelative(rx: Double, ry: Double, xAxisRotation: Double, largeArcFlag: Bool, sweepFlag: Bool, end: Point)

    // Close path
    case closePath
}
