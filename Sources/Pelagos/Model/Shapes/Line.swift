import Foundation

/// An SVG line element
struct Line: GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var x1: Length
    var y1: Length
    var x2: Length
    var y2: Length

    init(
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
