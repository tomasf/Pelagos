import Foundation

/// An SVG mask element
struct Mask: ContainerElement, Sendable {
    var id: String?

    var x: Length?
    var y: Length?
    var width: Length?
    var height: Length?
    var maskUnits: CoordinateUnits?
    var maskContentUnits: CoordinateUnits?

    var children: [any GraphicElement]

    init(
        id: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        maskUnits: CoordinateUnits? = nil,
        maskContentUnits: CoordinateUnits? = nil,
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
}
