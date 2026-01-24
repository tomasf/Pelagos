import Foundation

/// An SVG rect element
struct Rect: GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var x: Length
    var y: Length
    var width: Length
    var height: Length
    var rx: Length?
    var ry: Length?

    init(
        id: String? = nil,
        x: Length = .zero,
        y: Length = .zero,
        width: Length,
        height: Length,
        rx: Length? = nil,
        ry: Length? = nil,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rx = rx
        self.ry = ry
        self.presentation = presentation
    }
}
