import Foundation

/// An SVG clipPath element
struct ClipPath: ContainerElement, Hashable, Sendable {
    var id: String?

    var clipPathUnits: GradientUnits?  // Uses same enum
    var children: [any GraphicElement]

    init(
        id: String? = nil,
        clipPathUnits: GradientUnits? = nil,
        children: [any GraphicElement] = []
    ) {
        self.id = id
        self.clipPathUnits = clipPathUnits
        self.children = children
    }

    static func == (lhs: ClipPath, rhs: ClipPath) -> Bool {
        lhs.id == rhs.id && lhs.clipPathUnits == rhs.clipPathUnits
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(clipPathUnits)
    }
}
