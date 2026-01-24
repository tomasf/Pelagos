import Foundation

/// An SVG ellipse element
public struct Ellipse: GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var cx: Length
    public var cy: Length
    public var rx: Length
    public var ry: Length

    public init(
        id: String? = nil,
        cx: Length = .zero,
        cy: Length = .zero,
        rx: Length,
        ry: Length,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.cx = cx
        self.cy = cy
        self.rx = rx
        self.ry = ry
        self.presentation = presentation
    }
}
