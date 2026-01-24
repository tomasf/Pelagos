import Foundation

/// Container for reusable definitions (gradients, patterns, clipPaths, etc.)
public struct Definitions: Hashable, Sendable {
    public var defs: [Defs]
    public var gradients: [String: any GradientElement]
    public var patterns: [String: Pattern]
    public var clipPaths: [String: ClipPath]
    public var masks: [String: Mask]
    public var filters: [String: Filter]
    public var symbols: [String: Symbol]
    public var elements: [String: any GraphicElement]

    public init() {
        self.defs = []
        self.gradients = [:]
        self.patterns = [:]
        self.clipPaths = [:]
        self.masks = [:]
        self.filters = [:]
        self.symbols = [:]
        self.elements = [:]
    }

    public static func == (lhs: Definitions, rhs: Definitions) -> Bool {
        // Simple equality based on keys
        lhs.defs.compactMap { $0.id }.sorted() == rhs.defs.compactMap { $0.id }.sorted() &&
        lhs.gradients.keys.sorted() == rhs.gradients.keys.sorted() &&
        lhs.patterns == rhs.patterns &&
        lhs.clipPaths == rhs.clipPaths &&
        lhs.masks == rhs.masks &&
        lhs.filters == rhs.filters &&
        lhs.symbols.keys.sorted() == rhs.symbols.keys.sorted() &&
        lhs.elements.keys.sorted() == rhs.elements.keys.sorted()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(defs.compactMap { $0.id }.sorted())
        hasher.combine(gradients.keys.sorted())
        hasher.combine(patterns)
        hasher.combine(clipPaths)
        hasher.combine(masks)
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
