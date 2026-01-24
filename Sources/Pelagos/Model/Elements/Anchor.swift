import Foundation

/// An SVG anchor element (a)
public struct Anchor: ContainerElement, GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var href: String?
    public var target: String?
    public var children: [any GraphicElement]

    public init(
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

    public static func == (lhs: Anchor, rhs: Anchor) -> Bool {
        lhs.id == rhs.id &&
        lhs.href == rhs.href &&
        lhs.target == rhs.target &&
        lhs.presentation == rhs.presentation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(href)
        hasher.combine(target)
        hasher.combine(presentation)
    }
}
