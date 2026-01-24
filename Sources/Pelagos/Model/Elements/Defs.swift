import Foundation

/// An SVG defs container for reusable graphic elements
public struct Defs: ContainerElement, Hashable, Sendable {
    public var id: String?
    public var children: [any GraphicElement]

    public init(id: String? = nil, children: [any GraphicElement] = []) {
        self.id = id
        self.children = children
    }

    public static func == (lhs: Defs, rhs: Defs) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
