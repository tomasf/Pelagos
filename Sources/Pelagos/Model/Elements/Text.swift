import Foundation

/// An SVG text element
struct Text: GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var x: [Length]?
    var y: [Length]?
    var dx: [Length]?
    var dy: [Length]?
    var rotate: [Double]?
    var textLength: Length?
    var lengthAdjust: LengthAdjust?

    var content: [TextContent]

    init(
        id: String? = nil,
        x: [Length]? = nil,
        y: [Length]? = nil,
        dx: [Length]? = nil,
        dy: [Length]? = nil,
        rotate: [Double]? = nil,
        textLength: Length? = nil,
        lengthAdjust: LengthAdjust? = nil,
        content: [TextContent] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
        self.rotate = rotate
        self.textLength = textLength
        self.lengthAdjust = lengthAdjust
        self.content = content
        self.presentation = presentation
    }
}

/// Content within a text element
enum TextContent: Hashable, Sendable {
    case text(String)
    case span(TSpan)
    case reference(TextPath)
}

/// An SVG tspan element
struct TSpan: Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var x: [Length]?
    var y: [Length]?
    var dx: [Length]?
    var dy: [Length]?
    var rotate: [Double]?
    var textLength: Length?
    var lengthAdjust: LengthAdjust?

    var content: [TextContent]

    init(
        id: String? = nil,
        x: [Length]? = nil,
        y: [Length]? = nil,
        dx: [Length]? = nil,
        dy: [Length]? = nil,
        rotate: [Double]? = nil,
        textLength: Length? = nil,
        lengthAdjust: LengthAdjust? = nil,
        content: [TextContent] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
        self.rotate = rotate
        self.textLength = textLength
        self.lengthAdjust = lengthAdjust
        self.content = content
        self.presentation = presentation
    }
}

/// An SVG textPath element
struct TextPath: Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var href: String?
    var startOffset: Length?
    var method: TextPathMethod?
    var spacing: TextPathSpacing?

    var content: String

    init(
        id: String? = nil,
        href: String? = nil,
        startOffset: Length? = nil,
        method: TextPathMethod? = nil,
        spacing: TextPathSpacing? = nil,
        content: String = "",
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.href = href
        self.startOffset = startOffset
        self.method = method
        self.spacing = spacing
        self.content = content
        self.presentation = presentation
    }
}

enum LengthAdjust: String, Hashable, Sendable {
    case spacing
    case spacingAndGlyphs
}

enum TextPathMethod: String, Hashable, Sendable {
    case align
    case stretch
}

enum TextPathSpacing: String, Hashable, Sendable {
    case auto
    case exact
}
