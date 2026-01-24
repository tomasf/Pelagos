import Foundation

/// An SVG group element (g)
public struct Group: ContainerElement, GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var children: [any GraphicElement]

    public init(
        id: String? = nil,
        children: [any GraphicElement] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.children = children
        self.presentation = presentation
    }

    public static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.id == rhs.id && lhs.presentation == rhs.presentation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(presentation)
    }
}
