import Foundation

/// An SVG switch element for conditional processing
public struct Switch: ContainerElement, GraphicElement, Hashable, Sendable {
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

    public static func == (lhs: Switch, rhs: Switch) -> Bool {
        lhs.id == rhs.id && lhs.presentation == rhs.presentation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(presentation)
    }
}
