import Foundation

/// An SVG image element
public struct Image: GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var href: String?
    public var x: Length?
    public var y: Length?
    public var width: Length?
    public var height: Length?
    public var preserveAspectRatio: PreserveAspectRatio?

    public init(
        id: String? = nil,
        href: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        preserveAspectRatio: PreserveAspectRatio? = nil,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.href = href
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.preserveAspectRatio = preserveAspectRatio
        self.presentation = presentation
    }
}
