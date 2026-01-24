import Foundation

/// An SVG path element
struct Path: GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var segments: [PathSegment]

    init(
        id: String? = nil,
        segments: [PathSegment] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.segments = segments
        self.presentation = presentation
    }
}
