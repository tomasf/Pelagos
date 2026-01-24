import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(CoreGraphics)
func buildClipPath(
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
#endif
