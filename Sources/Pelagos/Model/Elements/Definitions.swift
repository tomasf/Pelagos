import Foundation

/// Container for reusable definitions (gradients, patterns, clipPaths, etc.)
struct Definitions: Hashable, Sendable {
    var defs: [Defs]
    var gradients: [String: any GradientElement]
    var patterns: [String: Pattern]
    var clipPaths: [String: ClipPath]
    var masks: [String: Mask]
    var filters: [String: Filter]
    var symbols: [String: Symbol]
    var elements: [String: any GraphicElement]

    init() {
        self.defs = []
        self.gradients = [:]
        self.patterns = [:]
        self.clipPaths = [:]
        self.masks = [:]
        self.filters = [:]
        self.symbols = [:]
        self.elements = [:]
    }

    static func == (lhs: Definitions, rhs: Definitions) -> Bool {
        // Equality based on keys only (container types don't support deep equality)
        lhs.defs.compactMap { $0.id }.sorted() == rhs.defs.compactMap { $0.id }.sorted() &&
        lhs.gradients.keys.sorted() == rhs.gradients.keys.sorted() &&
        lhs.patterns.keys.sorted() == rhs.patterns.keys.sorted() &&
        lhs.clipPaths.keys.sorted() == rhs.clipPaths.keys.sorted() &&
        lhs.masks.keys.sorted() == rhs.masks.keys.sorted() &&
        lhs.filters == rhs.filters &&
        lhs.symbols.keys.sorted() == rhs.symbols.keys.sorted() &&
        lhs.elements.keys.sorted() == rhs.elements.keys.sorted()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(defs.compactMap { $0.id }.sorted())
        hasher.combine(gradients.keys.sorted())
        hasher.combine(patterns.keys.sorted())
        hasher.combine(clipPaths.keys.sorted())
        hasher.combine(masks.keys.sorted())
        hasher.combine(filters)
        hasher.combine(symbols.keys.sorted())
        hasher.combine(elements.keys.sorted())
    }

    mutating func register(_ element: any SVGElement) {
        guard let id = element.id else { return }

        if let gradient = element as? any GradientElement {
            gradients[id] = gradient
        } else if let pattern = element as? Pattern {
            patterns[id] = pattern
        } else if let clipPath = element as? ClipPath {
            clipPaths[id] = clipPath
        } else if let mask = element as? Mask {
            masks[id] = mask
        } else if let filter = element as? Filter {
            filters[id] = filter
        } else if let symbol = element as? Symbol {
            symbols[id] = symbol
        } else if let graphic = element as? any GraphicElement {
            elements[id] = graphic
        }
    }
}
