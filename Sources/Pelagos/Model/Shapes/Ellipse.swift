import Foundation

/// An SVG ellipse element
struct Ellipse: GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var cx: Length
    var cy: Length
    var rx: Length
    var ry: Length

    init(
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
