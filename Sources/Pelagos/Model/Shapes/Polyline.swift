import Foundation

/// An SVG polyline element
struct Polyline: GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var points: [Point]

    init(
        id: String? = nil,
        points: [Point] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.points = points
        self.presentation = presentation
    }
}
