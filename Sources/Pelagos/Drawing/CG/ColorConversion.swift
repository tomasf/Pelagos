import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(CoreGraphics)
func cgColor(from color: Color, opacity: Double) -> CGColor? {
    let alpha = CGFloat(max(0, min(1, opacity)))

    switch color {
    case .none:
        return nil
    case .currentColor:
        return nil
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
    case .named:
        return nil
    }
}
#endif
