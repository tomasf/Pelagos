import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(CoreGraphics)
func makeTransform(from transforms: [Transform]) -> CGAffineTransform {
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
#endif
