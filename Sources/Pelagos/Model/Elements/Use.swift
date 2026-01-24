import Foundation

/// An SVG use element that references another element
struct Use: GraphicElement, ReferencingElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var href: String?
    var x: Length?
    var y: Length?
    var width: Length?
    var height: Length?

    init(
        id: String? = nil,
        href: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.href = href
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.presentation = presentation
    }
}
