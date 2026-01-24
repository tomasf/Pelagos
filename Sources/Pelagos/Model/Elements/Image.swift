import Foundation

/// An SVG image element
struct Image: GraphicElement, Hashable, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var href: String?
    var x: Length?
    var y: Length?
    var width: Length?
    var height: Length?
    var preserveAspectRatio: PreserveAspectRatio?

    init(
        id: String? = nil,
        href: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        preserveAspectRatio: PreserveAspectRatio? = nil,
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.href = href
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.preserveAspectRatio = preserveAspectRatio
        self.presentation = presentation
    }
}
