import Foundation

/// An SVG text element
public struct Text: GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var x: [Length]?
    public var y: [Length]?
    public var dx: [Length]?
    public var dy: [Length]?
    public var rotate: [Double]?
    public var textLength: Length?
    public var lengthAdjust: LengthAdjust?

    public var content: [TextContent]

    public init(
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
public enum TextContent: Hashable, Sendable {
    case text(String)
    case span(TSpan)
    case reference(TextPath)
}

/// An SVG tspan element
public struct TSpan: Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var x: [Length]?
    public var y: [Length]?
    public var dx: [Length]?
    public var dy: [Length]?
    public var rotate: [Double]?
    public var textLength: Length?
    public var lengthAdjust: LengthAdjust?

    public var content: [TextContent]

    public init(
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
public struct TextPath: Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var href: String?
    public var startOffset: Length?
    public var method: TextPathMethod?
    public var spacing: TextPathSpacing?

    public var content: String

    public init(
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

public enum LengthAdjust: String, Hashable, Sendable {
    case spacing
    case spacingAndGlyphs
}

public enum TextPathMethod: String, Hashable, Sendable {
    case align
    case stretch
}

public enum TextPathSpacing: String, Hashable, Sendable {
    case auto
    case exact
}
