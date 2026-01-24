import Foundation

/// An SVG switch element for conditional processing
struct Switch: ContainerElement, GraphicElement, Hashable, Sendable {
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

    static func == (lhs: Switch, rhs: Switch) -> Bool {
        lhs.id == rhs.id && lhs.presentation == rhs.presentation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(presentation)
    }
}
