import Foundation

/// An SVG anchor element (a)
struct Anchor: ContainerElement, GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var href: String?
    var target: String?
    var children: [any GraphicElement]

    init(
        id: String? = nil,
        href: String? = nil,
        target: String? = nil,
        children: [any GraphicElement] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.href = href
        self.target = target
        self.children = children
        self.presentation = presentation
    }

    static func == (lhs: Anchor, rhs: Anchor) -> Bool {
        lhs.id == rhs.id &&
        lhs.href == rhs.href &&
        lhs.target == rhs.target &&
        lhs.presentation == rhs.presentation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(href)
        hasher.combine(target)
        hasher.combine(presentation)
    }
}
