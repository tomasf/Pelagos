import Foundation

/// An SVG group element (g)
struct Group: ContainerElement, GraphicElement, Hashable, Sendable {
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

    static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.id == rhs.id && lhs.presentation == rhs.presentation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(presentation)
    }
}
