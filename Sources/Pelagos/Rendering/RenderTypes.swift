import Foundation

// MARK: - Affine Transform

/// A 2D affine transformation matrix.
///
/// The matrix is stored in the standard form:
/// ```
/// [ a  c  tx ]
/// [ b  d  ty ]
/// [ 0  0  1  ]
/// ```
///
/// When applied to a point (x, y), the result is:
/// - newX = a*x + c*y + tx
/// - newY = b*x + d*y + ty
public struct AffineTransform: Hashable, Sendable {
    /// The matrix entry at position (0, 0). Controls horizontal scaling.
    public var a: Double
    /// The matrix entry at position (1, 0). Controls vertical shearing.
    public var b: Double
    /// The matrix entry at position (0, 1). Controls horizontal shearing.
    public var c: Double
    /// The matrix entry at position (1, 1). Controls vertical scaling.
    public var d: Double
    /// The horizontal translation component.
    public var tx: Double
    /// The vertical translation component.
    public var ty: Double

    /// The identity transform (no transformation).
    public static let identity = AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)

    /// Creates an affine transform with the specified matrix components.
    /// - Parameters:
    ///   - a: The (0,0) matrix entry. Default is 1.
    ///   - b: The (1,0) matrix entry. Default is 0.
    ///   - c: The (0,1) matrix entry. Default is 0.
    ///   - d: The (1,1) matrix entry. Default is 1.
    ///   - tx: The horizontal translation. Default is 0.
    ///   - ty: The vertical translation. Default is 0.
    public init(a: Double = 1, b: Double = 0, c: Double = 0, d: Double = 1, tx: Double = 0, ty: Double = 0) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    /// Creates a translation transform.
    /// - Parameters:
    ///   - x: The horizontal translation distance.
    ///   - y: The vertical translation distance.
    /// - Returns: A transform that translates by the specified amounts.
    public static func translation(x: Double, y: Double) -> AffineTransform {
        AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: x, ty: y)
    }

    /// Creates a scaling transform.
    /// - Parameters:
    ///   - x: The horizontal scale factor.
    ///   - y: The vertical scale factor.
    /// - Returns: A transform that scales by the specified factors.
    public static func scale(x: Double, y: Double) -> AffineTransform {
        AffineTransform(a: x, b: 0, c: 0, d: y, tx: 0, ty: 0)
    }

    /// Creates a rotation transform.
    /// - Parameter radians: The rotation angle in radians (counterclockwise).
    /// - Returns: A transform that rotates by the specified angle.
    public static func rotation(radians: Double) -> AffineTransform {
        let c = cos(radians)
        let s = sin(radians)
        return AffineTransform(a: c, b: s, c: -s, d: c, tx: 0, ty: 0)
    }

    /// Returns a new transform by concatenating this transform with another.
    ///
    /// The resulting transform applies `self` first, then `other`.
    /// - Parameter other: The transform to concatenate.
    /// - Returns: The concatenated transform.
    public func concatenating(_ other: AffineTransform) -> AffineTransform {
        AffineTransform(
            a: a * other.a + b * other.c,
            b: a * other.b + b * other.d,
            c: c * other.a + d * other.c,
            d: c * other.b + d * other.d,
            tx: tx * other.a + ty * other.c + other.tx,
            ty: tx * other.b + ty * other.d + other.ty
        )
    }

    /// Whether this transform is the identity transform.
    public var isIdentity: Bool {
        a == 1 && b == 0 && c == 0 && d == 1 && tx == 0 && ty == 0
    }
}

// MARK: - Stroke Style

/// Parameters controlling how strokes are rendered.
public struct StrokeStyle: Hashable, Sendable {
    /// The width of the stroke in user units.
    public var width: Double
    /// The style of line endings.
    public var cap: LineCap
    /// The style of line joins.
    public var join: LineJoin
    /// The limit for miter joins before they become beveled.
    public var miterLimit: Double
    /// The dash pattern, or nil for solid strokes.
    public var dashArray: [Double]?
    /// The offset into the dash pattern to start from.
    public var dashOffset: Double

    /// Creates a stroke style with the specified parameters.
    /// - Parameters:
    ///   - width: The stroke width. Default is 1.
    ///   - cap: The line cap style. Default is `.butt`.
    ///   - join: The line join style. Default is `.miter`.
    ///   - miterLimit: The miter limit. Default is 4.
    ///   - dashArray: The dash pattern. Default is nil (solid).
    ///   - dashOffset: The dash offset. Default is 0.
    public init(
        width: Double = 1,
        cap: LineCap = .butt,
        join: LineJoin = .miter,
        miterLimit: Double = 4,
        dashArray: [Double]? = nil,
        dashOffset: Double = 0
    ) {
        self.width = width
        self.cap = cap
        self.join = join
        self.miterLimit = miterLimit
        self.dashArray = dashArray
        self.dashOffset = dashOffset
    }
}

// MARK: - Resolved Paint

/// The color space for a resolved color.
public enum ColorSpace: Hashable, Sendable {
    /// The standard sRGB color space.
    case sRGB
    /// The wide-gamut Display P3 color space.
    case displayP3
}

/// A fully resolved color ready for rendering.
///
/// All SVG color references (named colors, hex values, `currentColor`) are
/// resolved to this type before rendering.
public struct ResolvedColor: Hashable, Sendable {
    /// The red component (0.0 to 1.0).
    public var red: Double
    /// The green component (0.0 to 1.0).
    public var green: Double
    /// The blue component (0.0 to 1.0).
    public var blue: Double
    /// The alpha (opacity) component (0.0 to 1.0).
    public var alpha: Double
    /// The color space for this color.
    public var colorSpace: ColorSpace

    /// Creates a resolved color with the specified components.
    /// - Parameters:
    ///   - red: The red component (0.0 to 1.0).
    ///   - green: The green component (0.0 to 1.0).
    ///   - blue: The blue component (0.0 to 1.0).
    ///   - alpha: The alpha component (0.0 to 1.0). Default is 1.
    ///   - colorSpace: The color space. Default is `.sRGB`.
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1, colorSpace: ColorSpace = .sRGB) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.colorSpace = colorSpace
    }

    /// Opaque black.
    public static let black = ResolvedColor(red: 0, green: 0, blue: 0)
    /// Opaque white.
    public static let white = ResolvedColor(red: 1, green: 1, blue: 1)
    /// Fully transparent.
    public static let clear = ResolvedColor(red: 0, green: 0, blue: 0, alpha: 0)
}

// MARK: - Gradient Types

/// A single color stop in a gradient.
public struct ResolvedGradientStop: Hashable, Sendable {
    /// The position of this stop along the gradient (0.0 to 1.0).
    public var offset: Double
    /// The color at this stop.
    public var color: ResolvedColor

    /// Creates a gradient stop.
    /// - Parameters:
    ///   - offset: The position along the gradient (0.0 to 1.0).
    ///   - color: The color at this position.
    public init(offset: Double, color: ResolvedColor) {
        self.offset = offset
        self.color = color
    }
}

/// A fully resolved linear gradient ready for rendering.
public struct ResolvedLinearGradient: Hashable, Sendable {
    /// The x-coordinate of the gradient start point.
    public var startX: Double
    /// The y-coordinate of the gradient start point.
    public var startY: Double
    /// The x-coordinate of the gradient end point.
    public var endX: Double
    /// The y-coordinate of the gradient end point.
    public var endY: Double
    /// The color stops defining the gradient.
    public var stops: [ResolvedGradientStop]
    /// How the gradient extends beyond its bounds.
    public var spreadMethod: SpreadMethod
    /// The coordinate system for gradient coordinates.
    public var gradientUnits: CoordinateUnits
    /// An optional transform applied to the gradient.
    public var gradientTransform: AffineTransform?

    /// Creates a resolved linear gradient.
    /// - Parameters:
    ///   - startX: The x-coordinate of the start point.
    ///   - startY: The y-coordinate of the start point.
    ///   - endX: The x-coordinate of the end point.
    ///   - endY: The y-coordinate of the end point.
    ///   - stops: The color stops.
    ///   - spreadMethod: How the gradient extends. Default is `.pad`.
    ///   - gradientUnits: The coordinate system. Default is `.objectBoundingBox`.
    ///   - gradientTransform: An optional transform.
    public init(
        startX: Double,
        startY: Double,
        endX: Double,
        endY: Double,
        stops: [ResolvedGradientStop],
        spreadMethod: SpreadMethod = .pad,
        gradientUnits: CoordinateUnits = .objectBoundingBox,
        gradientTransform: AffineTransform? = nil
    ) {
        self.startX = startX
        self.startY = startY
        self.endX = endX
        self.endY = endY
        self.stops = stops
        self.spreadMethod = spreadMethod
        self.gradientUnits = gradientUnits
        self.gradientTransform = gradientTransform
    }
}

/// A fully resolved radial gradient ready for rendering.
public struct ResolvedRadialGradient: Hashable, Sendable {
    /// The x-coordinate of the gradient center.
    public var centerX: Double
    /// The y-coordinate of the gradient center.
    public var centerY: Double
    /// The radius of the gradient.
    public var radius: Double
    /// The x-coordinate of the focal point.
    public var focalX: Double
    /// The y-coordinate of the focal point.
    public var focalY: Double
    /// The color stops defining the gradient.
    public var stops: [ResolvedGradientStop]
    /// How the gradient extends beyond its bounds.
    public var spreadMethod: SpreadMethod
    /// The coordinate system for gradient coordinates.
    public var gradientUnits: CoordinateUnits
    /// An optional transform applied to the gradient.
    public var gradientTransform: AffineTransform?

    /// Creates a resolved radial gradient.
    /// - Parameters:
    ///   - centerX: The x-coordinate of the center.
    ///   - centerY: The y-coordinate of the center.
    ///   - radius: The gradient radius.
    ///   - focalX: The x-coordinate of the focal point. Defaults to centerX.
    ///   - focalY: The y-coordinate of the focal point. Defaults to centerY.
    ///   - stops: The color stops.
    ///   - spreadMethod: How the gradient extends. Default is `.pad`.
    ///   - gradientUnits: The coordinate system. Default is `.objectBoundingBox`.
    ///   - gradientTransform: An optional transform.
    public init(
        centerX: Double,
        centerY: Double,
        radius: Double,
        focalX: Double? = nil,
        focalY: Double? = nil,
        stops: [ResolvedGradientStop],
        spreadMethod: SpreadMethod = .pad,
        gradientUnits: CoordinateUnits = .objectBoundingBox,
        gradientTransform: AffineTransform? = nil
    ) {
        self.centerX = centerX
        self.centerY = centerY
        self.radius = radius
        self.focalX = focalX ?? centerX
        self.focalY = focalY ?? centerY
        self.stops = stops
        self.spreadMethod = spreadMethod
        self.gradientUnits = gradientUnits
        self.gradientTransform = gradientTransform
    }
}

/// A resolved gradient, either linear or radial.
public enum ResolvedGradient: Hashable, Sendable {
    /// A linear gradient.
    case linear(ResolvedLinearGradient)
    /// A radial gradient.
    case radial(ResolvedRadialGradient)
}

// MARK: - Pattern

/// A resolved pattern for tiled rendering.
public struct ResolvedPattern: Sendable {
    /// The x-coordinate of the pattern tile origin.
    public var tileX: Double
    /// The y-coordinate of the pattern tile origin.
    public var tileY: Double
    /// The width of each pattern tile.
    public var tileWidth: Double
    /// The height of each pattern tile.
    public var tileHeight: Double
    /// The SVG content to render in each tile.
    public var content: SVG
    /// An optional transform applied to the pattern.
    public var transform: AffineTransform?
    /// The coordinate system for pattern coordinates.
    public var patternUnits: CoordinateUnits

    /// Creates a resolved pattern.
    /// - Parameters:
    ///   - tileX: The x-coordinate of the tile origin.
    ///   - tileY: The y-coordinate of the tile origin.
    ///   - tileWidth: The tile width.
    ///   - tileHeight: The tile height.
    ///   - content: The SVG content for each tile.
    ///   - transform: An optional pattern transform.
    ///   - patternUnits: The coordinate system. Default is `.objectBoundingBox`.
    public init(
        tileX: Double,
        tileY: Double,
        tileWidth: Double,
        tileHeight: Double,
        content: SVG,
        transform: AffineTransform? = nil,
        patternUnits: CoordinateUnits = .objectBoundingBox
    ) {
        self.tileX = tileX
        self.tileY = tileY
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.content = content
        self.transform = transform
        self.patternUnits = patternUnits
    }
}

// MARK: - Text

/// A single run of text with consistent styling.
public struct ResolvedTextRun: Hashable, Sendable {
    /// The text content of this run.
    public var text: String
    /// The font family name, or nil for the default font.
    public var fontFamily: String?
    /// The font size in user units.
    public var fontSize: Double
    /// The text color.
    public var color: ResolvedColor

    /// Creates a text run.
    /// - Parameters:
    ///   - text: The text content.
    ///   - fontFamily: The font family name.
    ///   - fontSize: The font size.
    ///   - color: The text color.
    public init(text: String, fontFamily: String?, fontSize: Double, color: ResolvedColor) {
        self.text = text
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.color = color
    }
}

/// Resolved text content ready for rendering.
public struct ResolvedTextContent: Hashable, Sendable {
    /// The text runs that make up this content.
    public var runs: [ResolvedTextRun]
    /// The x-coordinate of the text anchor point.
    public var x: Double
    /// The y-coordinate of the text anchor point.
    public var y: Double
    /// The text alignment relative to the anchor point.
    public var anchor: TextAnchor

    /// Creates resolved text content.
    /// - Parameters:
    ///   - runs: The text runs.
    ///   - x: The x-coordinate of the anchor point.
    ///   - y: The y-coordinate of the anchor point.
    ///   - anchor: The text alignment. Default is `.start`.
    public init(runs: [ResolvedTextRun], x: Double, y: Double, anchor: TextAnchor = .start) {
        self.runs = runs
        self.x = x
        self.y = y
        self.anchor = anchor
    }
}

// MARK: - Image

/// Resolved image content ready for rendering.
public struct ResolvedImageContent: Sendable {
    /// The raw image data.
    public var data: Data
    /// The MIME type of the image (e.g., "image/png").
    public var mimeType: String?
    /// The x-coordinate of the image position.
    public var x: Double
    /// The y-coordinate of the image position.
    public var y: Double
    /// The width to render the image.
    public var width: Double
    /// The height to render the image.
    public var height: Double

    /// Creates resolved image content.
    /// - Parameters:
    ///   - data: The raw image data.
    ///   - mimeType: The MIME type.
    ///   - x: The x-coordinate.
    ///   - y: The y-coordinate.
    ///   - width: The render width.
    ///   - height: The render height.
    public init(data: Data, mimeType: String?, x: Double, y: Double, width: Double, height: Double) {
        self.data = data
        self.mimeType = mimeType
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

// MARK: - Bounding Box

/// A simple rectangle for bounding boxes.
struct BoundingBox: Hashable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var minX: Double { x }
    var minY: Double { y }
    var maxX: Double { x + width }
    var maxY: Double { y + height }

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
