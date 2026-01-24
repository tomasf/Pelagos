import Foundation

/// An SVG defs container for reusable graphic elements
struct Defs: ContainerElement, Hashable, Sendable {
    var id: String?
    var children: [any GraphicElement]

    init(id: String? = nil, children: [any GraphicElement] = []) {
        self.id = id
        self.children = children
    }

    static func == (lhs: Defs, rhs: Defs) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
