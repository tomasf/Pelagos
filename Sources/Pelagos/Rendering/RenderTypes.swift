import Foundation

// MARK: - Affine Transform

/// A 2D affine transformation matrix
public struct AffineTransform: Hashable, Sendable {
    public var a: Double
    public var b: Double
    public var c: Double
    public var d: Double
    public var tx: Double
    public var ty: Double

    public static let identity = AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)

    public init(a: Double = 1, b: Double = 0, c: Double = 0, d: Double = 1, tx: Double = 0, ty: Double = 0) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    public static func translation(x: Double, y: Double) -> AffineTransform {
        AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: x, ty: y)
    }

    public static func scale(x: Double, y: Double) -> AffineTransform {
        AffineTransform(a: x, b: 0, c: 0, d: y, tx: 0, ty: 0)
    }

    public static func rotation(radians: Double) -> AffineTransform {
        let c = cos(radians)
        let s = sin(radians)
        return AffineTransform(a: c, b: s, c: -s, d: c, tx: 0, ty: 0)
    }

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

    public var isIdentity: Bool {
        a == 1 && b == 0 && c == 0 && d == 1 && tx == 0 && ty == 0
    }
}

// MARK: - Stroke Style

/// Stroke rendering parameters
public struct StrokeStyle: Hashable, Sendable {
    public var width: Double
    public var cap: LineCap
    public var join: LineJoin
    public var miterLimit: Double
    public var dashArray: [Double]?
    public var dashOffset: Double

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

/// Color space for resolved colors
public enum ColorSpace: Hashable, Sendable {
    case sRGB
    case displayP3
}

/// Fully resolved color for rendering (all named colors and currentColor resolved)
public struct ResolvedColor: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double
    public var colorSpace: ColorSpace

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1, colorSpace: ColorSpace = .sRGB) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.colorSpace = colorSpace
    }

    public static let black = ResolvedColor(red: 0, green: 0, blue: 0)
    public static let white = ResolvedColor(red: 1, green: 1, blue: 1)
    public static let clear = ResolvedColor(red: 0, green: 0, blue: 0, alpha: 0)
}

// MARK: - Gradient Types

/// A fully resolved gradient stop
public struct ResolvedGradientStop: Hashable, Sendable {
    public var offset: Double
    public var color: ResolvedColor

    public init(offset: Double, color: ResolvedColor) {
        self.offset = offset
        self.color = color
    }
}

/// A fully resolved linear gradient with absolute coordinates
public struct ResolvedLinearGradient: Hashable, Sendable {
    public var startX: Double
    public var startY: Double
    public var endX: Double
    public var endY: Double
    public var stops: [ResolvedGradientStop]
    public var spreadMethod: SpreadMethod
    public var gradientUnits: GradientUnits
    public var gradientTransform: AffineTransform?

    public init(
        startX: Double,
        startY: Double,
        endX: Double,
        endY: Double,
        stops: [ResolvedGradientStop],
        spreadMethod: SpreadMethod = .pad,
        gradientUnits: GradientUnits = .objectBoundingBox,
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

/// A fully resolved radial gradient with absolute coordinates
public struct ResolvedRadialGradient: Hashable, Sendable {
    public var centerX: Double
    public var centerY: Double
    public var radius: Double
    public var focalX: Double
    public var focalY: Double
    public var stops: [ResolvedGradientStop]
    public var spreadMethod: SpreadMethod
    public var gradientUnits: GradientUnits
    public var gradientTransform: AffineTransform?

    public init(
        centerX: Double,
        centerY: Double,
        radius: Double,
        focalX: Double? = nil,
        focalY: Double? = nil,
        stops: [ResolvedGradientStop],
        spreadMethod: SpreadMethod = .pad,
        gradientUnits: GradientUnits = .objectBoundingBox,
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

/// Union type for resolved gradients
public enum ResolvedGradient: Hashable, Sendable {
    case linear(ResolvedLinearGradient)
    case radial(ResolvedRadialGradient)
}

// MARK: - Pattern

/// A resolved pattern for tiled rendering
public struct ResolvedPattern: Sendable {
    public var tileX: Double
    public var tileY: Double
    public var tileWidth: Double
    public var tileHeight: Double
    public var content: SVG
    public var transform: AffineTransform?
    public var patternUnits: GradientUnits

    public init(
        tileX: Double,
        tileY: Double,
        tileWidth: Double,
        tileHeight: Double,
        content: SVG,
        transform: AffineTransform? = nil,
        patternUnits: GradientUnits = .objectBoundingBox
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

/// A resolved text run for rendering
public struct ResolvedTextRun2: Hashable, Sendable {
    public var text: String
    public var fontFamily: String?
    public var fontSize: Double
    public var color: ResolvedColor

    public init(text: String, fontFamily: String?, fontSize: Double, color: ResolvedColor) {
        self.text = text
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.color = color
    }
}

/// Resolved text content for rendering
public struct ResolvedTextContent: Hashable, Sendable {
    public var runs: [ResolvedTextRun2]
    public var x: Double
    public var y: Double
    public var anchor: TextAnchor

    public init(runs: [ResolvedTextRun2], x: Double, y: Double, anchor: TextAnchor = .start) {
        self.runs = runs
        self.x = x
        self.y = y
        self.anchor = anchor
    }
}

// MARK: - Image

/// Resolved image for rendering
public struct ResolvedImageContent: Sendable {
    public var data: Data
    public var mimeType: String?
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

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

/// A simple rectangle for bounding boxes
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
