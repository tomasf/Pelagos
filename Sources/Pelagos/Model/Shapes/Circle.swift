import Foundation

/// An SVG circle element
public struct Circle: GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var cx: Length
    public var cy: Length
    public var r: Length

    public init(
        id: String? = nil,
        cx: Length = .zero,
        cy: Length = .zero,
        r: Length,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.cx = cx
        self.cy = cy
        self.r = r
        self.presentation = presentation
    }
}
