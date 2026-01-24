import Foundation

/// An SVG circle element
struct Circle: GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var cx: Length
    var cy: Length
    var r: Length

    init(
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
