import Foundation

/// An SVG pattern element
public struct Pattern: ContainerElement, Hashable, Sendable {
    public var id: String?

    public var x: Length?
    public var y: Length?
    public var width: Length?
    public var height: Length?

    public var patternUnits: GradientUnits?  // Uses same enum as gradients
    public var patternContentUnits: GradientUnits?
    public var patternTransform: [Transform]?
    public var viewBox: ViewBox?
    public var preserveAspectRatio: PreserveAspectRatio?
    public var href: String?

    public var children: [any GraphicElement]

    public init(
        id: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        patternUnits: GradientUnits? = nil,
        patternContentUnits: GradientUnits? = nil,
        patternTransform: [Transform]? = nil,
        viewBox: ViewBox? = nil,
        preserveAspectRatio: PreserveAspectRatio? = nil,
        href: String? = nil,
        children: [any GraphicElement] = []
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.patternUnits = patternUnits
        self.patternContentUnits = patternContentUnits
        self.patternTransform = patternTransform
        self.viewBox = viewBox
        self.preserveAspectRatio = preserveAspectRatio
        self.href = href
        self.children = children
    }

    public static func == (lhs: Pattern, rhs: Pattern) -> Bool {
        lhs.id == rhs.id &&
        lhs.x == rhs.x &&
        lhs.y == rhs.y &&
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.patternUnits == rhs.patternUnits &&
        lhs.patternContentUnits == rhs.patternContentUnits &&
        lhs.patternTransform == rhs.patternTransform &&
        lhs.viewBox == rhs.viewBox &&
        lhs.preserveAspectRatio == rhs.preserveAspectRatio &&
        lhs.href == rhs.href
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(patternUnits)
        hasher.combine(patternContentUnits)
        hasher.combine(patternTransform)
        hasher.combine(viewBox)
        hasher.combine(preserveAspectRatio)
        hasher.combine(href)
    }
}
