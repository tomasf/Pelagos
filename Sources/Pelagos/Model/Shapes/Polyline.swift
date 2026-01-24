import Foundation

/// An SVG polyline element
public struct Polyline: GraphicElement, Hashable, Sendable {
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
