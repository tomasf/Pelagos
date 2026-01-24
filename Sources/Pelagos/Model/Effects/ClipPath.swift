import Foundation

/// An SVG clipPath element
public struct ClipPath: ContainerElement, Hashable, Sendable {
    public var id: String?

    public var clipPathUnits: GradientUnits?  // Uses same enum
    public var children: [any GraphicElement]

    public init(
        id: String? = nil,
        clipPathUnits: GradientUnits? = nil,
        children: [any GraphicElement] = []
    ) {
        self.id = id
        self.clipPathUnits = clipPathUnits
        self.children = children
    }

    public static func == (lhs: ClipPath, rhs: ClipPath) -> Bool {
        lhs.id == rhs.id && lhs.clipPathUnits == rhs.clipPathUnits
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(clipPathUnits)
    }
}
