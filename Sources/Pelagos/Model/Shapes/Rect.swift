import Foundation

/// An SVG rect element
public struct Rect: GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var x: Length
    public var y: Length
    public var width: Length
    public var height: Length
    public var rx: Length?
    public var ry: Length?

    public init(
        id: String? = nil,
        x: Length = .zero,
        y: Length = .zero,
        width: Length,
        height: Length,
        rx: Length? = nil,
        ry: Length? = nil,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rx = rx
        self.ry = ry
        self.presentation = presentation
    }
}
