import Foundation

/// An SVG mask element
struct Mask: ContainerElement, Hashable, Sendable {
    var id: String?

    var x: Length?
    var y: Length?
    var width: Length?
    var height: Length?
    var maskUnits: GradientUnits?
    var maskContentUnits: GradientUnits?

    var children: [any GraphicElement]

    init(
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

    static func == (lhs: Mask, rhs: Mask) -> Bool {
        lhs.id == rhs.id &&
        lhs.x == rhs.x &&
        lhs.y == rhs.y &&
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.maskUnits == rhs.maskUnits &&
        lhs.maskContentUnits == rhs.maskContentUnits
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(maskUnits)
        hasher.combine(maskContentUnits)
    }
}
