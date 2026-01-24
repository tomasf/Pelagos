import Foundation

/// An SVG symbol element (reusable graphic)
struct Symbol: ContainerElement, Hashable, Sendable {
    var id: String?

    var viewBox: ViewBox?
    var preserveAspectRatio: PreserveAspectRatio?
    var children: [any GraphicElement]

    init(
        id: String? = nil,
        viewBox: ViewBox? = nil,
        preserveAspectRatio: PreserveAspectRatio? = nil,
        children: [any GraphicElement] = []
    ) {
        self.id = id
        self.viewBox = viewBox
        self.preserveAspectRatio = preserveAspectRatio
        self.children = children
    }

    static func == (lhs: Symbol, rhs: Symbol) -> Bool {
        lhs.id == rhs.id &&
        lhs.viewBox == rhs.viewBox &&
        lhs.preserveAspectRatio == rhs.preserveAspectRatio
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(viewBox)
        hasher.combine(preserveAspectRatio)
    }
}
