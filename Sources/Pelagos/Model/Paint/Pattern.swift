import Foundation

/// An SVG pattern element
struct Pattern: ContainerElement, Sendable {
    var id: String?

    var x: Length?
    var y: Length?
    var width: Length?
    var height: Length?

    var patternUnits: CoordinateUnits?
    var patternContentUnits: CoordinateUnits?
    var patternTransform: [Transform]?
    var viewBox: ViewBox?
    var preserveAspectRatio: PreserveAspectRatio?
    var href: String?

    var children: [any GraphicElement]

    init(
        id: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        patternUnits: CoordinateUnits? = nil,
        patternContentUnits: CoordinateUnits? = nil,
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
}
