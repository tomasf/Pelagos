import Foundation

/// An SVG line element
public struct Line: GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var x1: Length
    public var y1: Length
    public var x2: Length
    public var y2: Length

    public init(
        id: String? = nil,
        x1: Length = .zero,
        y1: Length = .zero,
        x2: Length = .zero,
        y2: Length = .zero,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.presentation = presentation
    }
}
