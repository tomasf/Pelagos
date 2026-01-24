import Foundation

/// An SVG use element that references another element
public struct Use: GraphicElement, ReferencingElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var href: String?
    public var x: Length?
    public var y: Length?
    public var width: Length?
    public var height: Length?

    public init(
        id: String? = nil,
        href: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.href = href
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.presentation = presentation
    }
}
