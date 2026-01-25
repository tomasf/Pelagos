import Foundation

/// An SVG group element (g)
struct Group: ContainerElement, GraphicElement, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var children: [any GraphicElement]

    init(
        id: String? = nil,
        children: [any GraphicElement] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.children = children
        self.presentation = presentation
    }

}
