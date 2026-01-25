import Foundation

/// Protocol for rendering SVG content to a graphics backend.
///
/// Pelagos handles all SVG semantics (tree walking, inheritance, length resolution,
/// shape-to-path conversion) and calls these primitive methods to actually draw.
///
/// To implement a renderer:
/// 1. Define your `Path` and `NativeColor` types
/// 2. Implement the path building methods (`moveTo`, `lineTo`, etc.)
/// 3. Implement the drawing methods (`fill`, `stroke`, `drawText`, `drawImage`)
/// 4. Implement state management (`save`, `restore`, `concatenate`, `clip`)
///
/// Example usage:
/// ```swift
/// let renderer = CGRenderer(context: cgContext)
/// svg.render(with: renderer)
/// ```
public protocol SVGRenderer<Path, NativeColor> {
    /// The path type for this renderer (e.g., CGMutablePath, UIBezierPath)
    associatedtype Path
    /// The color type for this renderer (e.g., CGColor, UIColor)
    associatedtype NativeColor

    // MARK: - Path Construction

    /// Create a new empty path
    func makePath() -> Path

    /// Move to a point (start a new subpath)
    func moveTo(_ path: inout Path, x: Double, y: Double)

    /// Add a line from the current point
    func lineTo(_ path: inout Path, x: Double, y: Double)

    /// Add a cubic Bézier curve
    func curveTo(_ path: inout Path, cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double)

    /// Add a quadratic Bézier curve
    func quadTo(_ path: inout Path, cpx: Double, cpy: Double, x: Double, y: Double)

    /// Close the current subpath
    func closePath(_ path: inout Path)

    /// Add a rectangle (with optional corner radii)
    func addRect(_ path: inout Path, x: Double, y: Double, width: Double, height: Double, rx: Double, ry: Double)

    /// Add an ellipse
    func addEllipse(_ path: inout Path, cx: Double, cy: Double, rx: Double, ry: Double)

    // MARK: - Color Conversion

    /// Create a native color from a resolved color
    func makeColor(from resolved: ResolvedColor) -> NativeColor

    // MARK: - Drawing Operations

    /// Fill a path with a solid color
    func fill(_ path: Path, color: NativeColor, rule: FillRule)

    /// Stroke a path with a solid color
    func stroke(_ path: Path, color: NativeColor, style: StrokeStyle)

    /// Stroke a path with a gradient
    func strokeGradient(_ path: Path, gradient: ResolvedGradient, style: StrokeStyle)

    /// Fill a path with a gradient
    func fillGradient(_ path: Path, gradient: ResolvedGradient, rule: FillRule)

    /// Fill a path with a pattern
    func fillPattern(_ path: Path, pattern: ResolvedPattern, rule: FillRule)

    /// Draw text
    func drawText(_ text: ResolvedTextContent)

    /// Draw an image
    func drawImage(_ image: ResolvedImageContent)

    // MARK: - State Management

    /// Save the current graphics state
    func save()

    /// Restore the previously saved graphics state
    func restore()

    /// Concatenate a transform to the current transform
    func concatenate(_ transform: AffineTransform)

    /// Set the clipping path
    func clip(_ path: Path, rule: FillRule)

    /// Set the global opacity for subsequent drawing operations
    func setOpacity(_ opacity: Double)
}

// MARK: - Default Implementations

public extension SVGRenderer {
    /// Default rectangle implementation using basic path operations
    func addRect(_ path: inout Path, x: Double, y: Double, width: Double, height: Double, rx: Double, ry: Double) {
        if rx <= 0 && ry <= 0 {
            // Simple rectangle
            moveTo(&path, x: x, y: y)
            lineTo(&path, x: x + width, y: y)
            lineTo(&path, x: x + width, y: y + height)
            lineTo(&path, x: x, y: y + height)
            closePath(&path)
        } else {
            // Rounded rectangle
            let cornerX = min(rx, width / 2)
            let cornerY = min(ry, height / 2)

            moveTo(&path, x: x + cornerX, y: y)
            lineTo(&path, x: x + width - cornerX, y: y)
            quadTo(&path, cpx: x + width, cpy: y, x: x + width, y: y + cornerY)
            lineTo(&path, x: x + width, y: y + height - cornerY)
            quadTo(&path, cpx: x + width, cpy: y + height, x: x + width - cornerX, y: y + height)
            lineTo(&path, x: x + cornerX, y: y + height)
            quadTo(&path, cpx: x, cpy: y + height, x: x, y: y + height - cornerY)
            lineTo(&path, x: x, y: y + cornerY)
            quadTo(&path, cpx: x, cpy: y, x: x + cornerX, y: y)
            closePath(&path)
        }
    }

    /// Default ellipse implementation using cubic Bézier curves
    func addEllipse(_ path: inout Path, cx: Double, cy: Double, rx: Double, ry: Double) {
        // Approximate ellipse with 4 cubic Bézier curves
        // Magic number for circular arc approximation: 4 * (sqrt(2) - 1) / 3 ≈ 0.5523
        let k: Double = 0.5522847498

        moveTo(&path, x: cx + rx, y: cy)
        curveTo(&path, cp1x: cx + rx, cp1y: cy + ry * k, cp2x: cx + rx * k, cp2y: cy + ry, x: cx, y: cy + ry)
        curveTo(&path, cp1x: cx - rx * k, cp1y: cy + ry, cp2x: cx - rx, cp2y: cy + ry * k, x: cx - rx, y: cy)
        curveTo(&path, cp1x: cx - rx, cp1y: cy - ry * k, cp2x: cx - rx * k, cp2y: cy - ry, x: cx, y: cy - ry)
        curveTo(&path, cp1x: cx + rx * k, cp1y: cy - ry, cp2x: cx + rx, cp2y: cy - ry * k, x: cx + rx, y: cy)
        closePath(&path)
    }

    /// Default no-op for opacity (renderers can override)
    func setOpacity(_ opacity: Double) {}
}
