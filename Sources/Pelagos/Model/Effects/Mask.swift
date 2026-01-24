import Foundation

/// An SVG mask element
public struct Mask: ContainerElement, Hashable, Sendable {
    public var id: String?

    public var x: Length?
    public var y: Length?
    public var width: Length?
    public var height: Length?
    public var maskUnits: GradientUnits?
    public var maskContentUnits: GradientUnits?

    public var children: [any GraphicElement]

    public init(
        id: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        maskUnits: GradientUnits? = nil,
        maskContentUnits: GradientUnits? = nil,
        children: [any GraphicElement] = []
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.maskUnits = maskUnits
        self.maskContentUnits = maskContentUnits
        self.children = children
    }

    public static func == (lhs: Mask, rhs: Mask) -> Bool {
        lhs.id == rhs.id &&
        lhs.x == rhs.x &&
        lhs.y == rhs.y &&
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.maskUnits == rhs.maskUnits &&
        lhs.maskContentUnits == rhs.maskContentUnits
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(maskUnits)
        hasher.combine(maskContentUnits)
    }
}
