import Foundation

/// A 2D transform operation
enum Transform: Hashable, Sendable {
    case matrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)
    case translate(x: Double, y: Double)
    case scale(x: Double, y: Double)
    case rotate(angle: Double, cx: Double?, cy: Double?)
    case skewX(angle: Double)
    case skewY(angle: Double)
}

extension Transform {
    static func translate(x: Double) -> Transform {
        .translate(x: x, y: 0)
    }

    static func scale(_ s: Double) -> Transform {
        .scale(x: s, y: s)
    }

    static func rotate(_ angle: Double) -> Transform {
        .rotate(angle: angle, cx: nil, cy: nil)
    }
}
