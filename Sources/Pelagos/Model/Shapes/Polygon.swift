import Foundation

/// An SVG polygon element
public struct Polygon: GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var points: [Point]

    public init(
        id: String? = nil,
        points: [Point] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.points = points
        self.presentation = presentation
    }
}
