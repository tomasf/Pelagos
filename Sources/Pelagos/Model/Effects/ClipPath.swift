import Foundation

/// An SVG clipPath element
struct ClipPath: ContainerElement, Sendable {
    var id: String?

    var clipPathUnits: CoordinateUnits?
    var children: [any GraphicElement]

    init(
        id: String? = nil,
        clipPathUnits: CoordinateUnits? = nil,
        children: [any GraphicElement] = []
    ) {
        self.id = id
        self.clipPathUnits = clipPathUnits
        self.children = children
    }
}
