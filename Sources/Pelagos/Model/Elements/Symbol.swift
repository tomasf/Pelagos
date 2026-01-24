import Foundation

/// An SVG symbol element (reusable graphic)
public struct Symbol: ContainerElement, Hashable, Sendable {
    public var id: String?

    public var viewBox: ViewBox?
    public var preserveAspectRatio: PreserveAspectRatio?
    public var children: [any GraphicElement]

    public init(
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

    public static func == (lhs: Symbol, rhs: Symbol) -> Bool {
        lhs.id == rhs.id &&
        lhs.viewBox == rhs.viewBox &&
        lhs.preserveAspectRatio == rhs.preserveAspectRatio
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(viewBox)
        hasher.combine(preserveAspectRatio)
    }
}
