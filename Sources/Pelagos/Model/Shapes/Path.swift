import Foundation

/// An SVG path element
public struct Path: GraphicElement, Hashable, Sendable {
    public var id: String?
    public var presentation: PresentationAttributes

    public var segments: [PathSegment]

    public init(
        id: String? = nil,
        segments: [PathSegment] = [],
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.segments = segments
        self.presentation = presentation
    }
}
