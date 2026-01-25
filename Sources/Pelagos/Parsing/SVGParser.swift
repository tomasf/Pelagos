import Foundation
import Nodal

/// Parser for SVG documents
struct SVGParser {
    init() {}

    // MARK: - Public API

    /// Parse SVG from a URL
    func parse(url: URL) throws -> SVG {
        let document = try Document(url: url)
        return try parse(document: document)
    }

    /// Parse SVG from data
    func parse(data: Data) throws -> SVG {
        let document = try Document(data: data)
        return try parse(document: document)
    }

    /// Parse SVG from a string
    func parse(string: String) throws -> SVG {
        let document = try Document(string: string)
        return try parse(document: document)
    }

    // MARK: - Internal Parsing

    private func parse(document: Document) throws -> SVG {
        guard let root = document.documentElement else {
            throw SVGParseError.noRootElement
        }

        if root.defaultNamespaceName == nil {
            root.declareNamespace(SVGNamespace.svg, forPrefix: nil)
        }

        guard root.expandedName == SVGElementName.svg else {
            throw SVGParseError.invalidRootElement(root.name)
        }

        var definitions = Definitions()
        var styleRules: [CSSRule] = []

        // First pass: collect styles
        collectStyles(from: root, styles: &styleRules)

        // Second pass: collect definitions and parse the tree
        collectDefinitions(from: root, into: &definitions, styleRules: styleRules, ancestors: [])
        collectDefsContainers(from: root, into: &definitions, styleRules: styleRules, ancestors: [])
        resolveReferences(in: &definitions)
        let children = try parseChildren(of: root, definitions: &definitions, styleRules: styleRules, ancestors: [])
        resolveReferences(in: &definitions)

        return SVG(
            id: root[attribute: "id"],
            width: AttributeParser.parseLength(root[attribute: "width"]),
            height: AttributeParser.parseLength(root[attribute: "height"]),
            viewBox: AttributeParser.parseViewBox(root[attribute: "viewBox"]),
            preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(root[attribute: "preserveAspectRatio"]),
            children: children,
            definitions: definitions,
            presentation: PresentationParser.parse(from: root, styleRules: styleRules, ancestors: [])
        )
    }

    // MARK: - Style Collection

    private func collectStyles(from node: Node, styles: inout [CSSRule]) {
        // Skip non-element nodes
        guard node.kind == .element else { return }

        // Collect style elements
        if node.expandedName == SVGElementName.style {
            let cssText = node.textContent
            let rules = CSSParser.parse(cssText)
            styles.append(contentsOf: rules)
        }

        // Recurse
        for child in node.elements {
            collectStyles(from: child, styles: &styles)
        }
    }

    // MARK: - Definition Collection

    private func collectDefinitions(from node: Node, into definitions: inout Definitions, styleRules: [CSSRule], ancestors: [Node]) {
        // Skip non-element nodes
        guard node.kind == .element else { return }
        let childAncestors = ancestors + [node]

        // Process defs container
        if node.expandedName == SVGElementName.defs {
            for child in node.elements {
                collectDefinition(from: child, into: &definitions, styleRules: styleRules, ancestors: childAncestors)
            }
        }

        // Recurse
        for child in node.elements {
            collectDefinitions(from: child, into: &definitions, styleRules: styleRules, ancestors: childAncestors)
        }
    }

    private func collectDefinition(from node: Node, into definitions: inout Definitions, styleRules: [CSSRule], ancestors: [Node]) {
        guard let id = node[attribute: "id"], !id.isEmpty else { return }

        if node.expandedName == SVGElementName.linearGradient {
            let stops = parseGradientStops(from: node)
            let gradient = ElementParsers.parseLinearGradient(from: node, stops: stops)
            definitions.gradients[id] = gradient

        } else if node.expandedName == SVGElementName.radialGradient {
            let stops = parseGradientStops(from: node)
            let gradient = ElementParsers.parseRadialGradient(from: node, stops: stops)
            definitions.gradients[id] = gradient

        } else if node.expandedName == SVGElementName.pattern {
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules, ancestors: ancestors)) ?? []
            let pattern = ElementParsers.parsePattern(from: node, children: children)
            definitions.patterns[id] = pattern

        } else if node.expandedName == SVGElementName.clipPath {
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules, ancestors: ancestors)) ?? []
            let clipPath = ElementParsers.parseClipPath(from: node, children: children)
            definitions.clipPaths[id] = clipPath

        } else if node.expandedName == SVGElementName.mask {
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules, ancestors: ancestors)) ?? []
            let mask = ElementParsers.parseMask(from: node, children: children)
            definitions.masks[id] = mask

        } else if node.expandedName == SVGElementName.filter {
            let primitives = parseFilterPrimitives(from: node)
            let filter = ElementParsers.parseFilter(from: node, primitives: primitives)
            definitions.filters[id] = filter

        } else if node.expandedName == SVGElementName.symbol {
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules, ancestors: ancestors)) ?? []
            let symbol = ElementParsers.parseSymbol(from: node, children: children)
            definitions.symbols[id] = symbol

        } else {
            // Store other elements with ids for use references
            if let graphic = try? parseElement(node, definitions: &definitions, styleRules: styleRules, ancestors: ancestors) {
                definitions.elements[id] = graphic
            }
        }
    }

    private func collectDefsContainers(from node: Node, into definitions: inout Definitions, styleRules: [CSSRule], ancestors: [Node]) {
        guard node.kind == .element else { return }
        let childAncestors = ancestors + [node]

        if node.expandedName == SVGElementName.defs {
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules, ancestors: childAncestors)) ?? []
            let defs = Defs(id: node[attribute: "id"], children: children)
            definitions.defs.append(defs)
        }

        for child in node.elements {
            collectDefsContainers(from: child, into: &definitions, styleRules: styleRules, ancestors: childAncestors)
        }
    }

    // MARK: - Element Parsing

    private func parseChildren(of parent: Node, definitions: inout Definitions, styleRules: [CSSRule], ancestors: [Node]) throws -> [any GraphicElement] {
        var children: [any GraphicElement] = []
        let childAncestors = ancestors + [parent]

        for child in parent.elements {
            // Skip defs, style, and non-graphic elements
            if child.expandedName == SVGElementName.defs || child.expandedName == SVGElementName.style ||
               child.expandedName == SVGElementName.desc || child.expandedName == SVGElementName.title ||
               child.expandedName == SVGElementName.metadata {
                continue
            }

            // Skip definition elements at top level (they're in defs)
            if child.expandedName == SVGElementName.linearGradient ||
               child.expandedName == SVGElementName.radialGradient ||
               child.expandedName == SVGElementName.pattern ||
               child.expandedName == SVGElementName.clipPath ||
               child.expandedName == SVGElementName.mask ||
               child.expandedName == SVGElementName.filter ||
               child.expandedName == SVGElementName.symbol {
                // Still collect them if they have ids
                if child[attribute: "id"] != nil {
                    collectDefinition(from: child, into: &definitions, styleRules: styleRules, ancestors: childAncestors)
                }
                continue
            }

            if let graphic = try? parseElement(child, definitions: &definitions, styleRules: styleRules, ancestors: childAncestors) {
                children.append(graphic)

                // Register if it has an id
                if let id = graphic.id {
                    definitions.elements[id] = graphic
                }
            }
        }

        return children
    }

    private func parseElement(_ node: Node, definitions: inout Definitions, styleRules: [CSSRule], ancestors: [Node]) throws -> (any GraphicElement)? {
        // Shapes
        if node.expandedName == SVGElementName.rect {
            return ElementParsers.parseRect(from: node, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.circle {
            return ElementParsers.parseCircle(from: node, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.ellipse {
            return ElementParsers.parseEllipse(from: node, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.line {
            return ElementParsers.parseLine(from: node, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.polyline {
            return ElementParsers.parsePolyline(from: node, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.polygon {
            return ElementParsers.parsePolygon(from: node, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.path {
            return try ElementParsers.parsePath(from: node, styleRules: styleRules, ancestors: ancestors)

        // Containers
        } else if node.expandedName == SVGElementName.g {
            let children = try parseChildren(of: node, definitions: &definitions, styleRules: styleRules, ancestors: ancestors)
            return ElementParsers.parseGroup(from: node, children: children, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.svg {
            // Nested SVG
            let children = try parseChildren(of: node, definitions: &definitions, styleRules: styleRules, ancestors: ancestors)
            return SVG(
                id: node[attribute: "id"],
                width: AttributeParser.parseLength(node[attribute: "width"]),
                height: AttributeParser.parseLength(node[attribute: "height"]),
                viewBox: AttributeParser.parseViewBox(node[attribute: "viewBox"]),
                preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(node[attribute: "preserveAspectRatio"]),
                children: children,
                definitions: Definitions(),
                presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
            )

        } else if node.expandedName == SVGElementName.anchor {
            let children = try parseChildren(of: node, definitions: &definitions, styleRules: styleRules, ancestors: ancestors)
            return ElementParsers.parseAnchor(from: node, children: children, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.switch {
            let children = try parseChildren(of: node, definitions: &definitions, styleRules: styleRules, ancestors: ancestors)
            return ElementParsers.parseSwitch(from: node, children: children, styleRules: styleRules, ancestors: ancestors)

        // References
        } else if node.expandedName == SVGElementName.use {
            return ElementParsers.parseUse(from: node, styleRules: styleRules, ancestors: ancestors)

        // Content
        } else if node.expandedName == SVGElementName.image {
            return ElementParsers.parseImage(from: node, styleRules: styleRules, ancestors: ancestors)

        } else if node.expandedName == SVGElementName.text {
            let content = parseTextContent(from: node, styleRules: styleRules, ancestors: ancestors)
            return ElementParsers.parseText(from: node, content: content, styleRules: styleRules, ancestors: ancestors)

        }

        // Unknown element - skip
        return nil
    }

    // MARK: - Reference Resolution

    private func resolveReferences(in definitions: inout Definitions) {
        for key in definitions.gradients.keys {
            var visited: Set<String> = []
            let resolved = resolveGradient(id: key, definitions: &definitions, visited: &visited)
            if let resolved {
                definitions.gradients[key] = resolved
            }
        }

        for key in definitions.patterns.keys {
            var visited: Set<String> = []
            let resolved = resolvePattern(id: key, definitions: &definitions, visited: &visited)
            if let resolved {
                definitions.patterns[key] = resolved
            }
        }
    }

    private func resolveGradient(id: String, definitions: inout Definitions, visited: inout Set<String>) -> (any GradientElement)? {
        guard let gradient = definitions.gradients[id] else { return nil }
        if visited.contains(id) { return gradient }
        visited.insert(id)

        if let linear = gradient as? LinearGradient {
            let resolved = resolveLinearGradient(linear, definitions: &definitions, visited: &visited)
            definitions.gradients[id] = resolved
            return resolved
        }

        if let radial = gradient as? RadialGradient {
            let resolved = resolveRadialGradient(radial, definitions: &definitions, visited: &visited)
            definitions.gradients[id] = resolved
            return resolved
        }

        return gradient
    }

    private func resolveLinearGradient(_ gradient: LinearGradient, definitions: inout Definitions, visited: inout Set<String>) -> LinearGradient {
        guard let href = gradient.href, !href.isEmpty,
              let referenced = resolveGradient(id: href, definitions: &definitions, visited: &visited) else {
            return gradient
        }

        var resolved = gradient

        if resolved.stops.isEmpty {
            resolved.stops = referenced.stops
        }

        if resolved.gradientUnits == nil {
            resolved.gradientUnits = referenced.gradientUnits
        }

        if resolved.gradientTransform == nil {
            resolved.gradientTransform = referenced.gradientTransform
        }

        if resolved.spreadMethod == nil {
            resolved.spreadMethod = referenced.spreadMethod
        }

        if let referenceLinear = referenced as? LinearGradient {
            if resolved.x1 == nil { resolved.x1 = referenceLinear.x1 }
            if resolved.y1 == nil { resolved.y1 = referenceLinear.y1 }
            if resolved.x2 == nil { resolved.x2 = referenceLinear.x2 }
            if resolved.y2 == nil { resolved.y2 = referenceLinear.y2 }
        }

        return resolved
    }

    private func resolveRadialGradient(_ gradient: RadialGradient, definitions: inout Definitions, visited: inout Set<String>) -> RadialGradient {
        guard let href = gradient.href, !href.isEmpty,
              let referenced = resolveGradient(id: href, definitions: &definitions, visited: &visited) else {
            return gradient
        }

        var resolved = gradient

        if resolved.stops.isEmpty {
            resolved.stops = referenced.stops
        }

        if resolved.gradientUnits == nil {
            resolved.gradientUnits = referenced.gradientUnits
        }

        if resolved.gradientTransform == nil {
            resolved.gradientTransform = referenced.gradientTransform
        }

        if resolved.spreadMethod == nil {
            resolved.spreadMethod = referenced.spreadMethod
        }

        if let referenceRadial = referenced as? RadialGradient {
            if resolved.cx == nil { resolved.cx = referenceRadial.cx }
            if resolved.cy == nil { resolved.cy = referenceRadial.cy }
            if resolved.r == nil { resolved.r = referenceRadial.r }
            if resolved.fx == nil { resolved.fx = referenceRadial.fx }
            if resolved.fy == nil { resolved.fy = referenceRadial.fy }
            if resolved.fr == nil { resolved.fr = referenceRadial.fr }
        }

        return resolved
    }

    private func resolvePattern(id: String, definitions: inout Definitions, visited: inout Set<String>) -> Pattern? {
        guard let pattern = definitions.patterns[id] else { return nil }
        if visited.contains(id) { return pattern }
        visited.insert(id)

        guard let href = pattern.href, !href.isEmpty,
              let referenced = resolvePattern(id: href, definitions: &definitions, visited: &visited) else {
            return pattern
        }

        var resolved = pattern
        if resolved.x == nil { resolved.x = referenced.x }
        if resolved.y == nil { resolved.y = referenced.y }
        if resolved.width == nil { resolved.width = referenced.width }
        if resolved.height == nil { resolved.height = referenced.height }
        if resolved.patternUnits == nil { resolved.patternUnits = referenced.patternUnits }
        if resolved.patternContentUnits == nil { resolved.patternContentUnits = referenced.patternContentUnits }
        if resolved.patternTransform == nil { resolved.patternTransform = referenced.patternTransform }
        if resolved.viewBox == nil { resolved.viewBox = referenced.viewBox }
        if resolved.preserveAspectRatio == nil { resolved.preserveAspectRatio = referenced.preserveAspectRatio }
        if resolved.children.isEmpty { resolved.children = referenced.children }

        definitions.patterns[id] = resolved
        return resolved
    }

    // MARK: - Gradient Stops

    private func parseGradientStops(from node: Node) -> [GradientStop] {
        var stops: [GradientStop] = []

        for child in node.elements {
            if child.expandedName == SVGElementName.stop, let stop = ElementParsers.parseGradientStop(from: child) {
                stops.append(stop)
            }
        }

        return stops
    }

    // MARK: - Filter Primitives

    private func parseFilterPrimitives(from node: Node) -> [FilterPrimitive] {
        var primitives: [FilterPrimitive] = []

        for child in node.elements {
            if let primitive = ElementParsers.parseFilterPrimitive(from: child) {
                primitives.append(primitive)
            }
        }

        return primitives
    }

    // MARK: - Text Content

    private func parseTextContent(from node: Node, styleRules: [CSSRule], ancestors: [Node]) -> [TextContent] {
        var content: [TextContent] = []
        let childAncestors = ancestors + [node]

        for child in node.children {
            if child.kind == .text || child.kind == .cdata {
                let text = normalizeTextContent(child.value)
                if !text.isEmpty {
                    content.append(.text(text))
                }
            } else if child.kind == .element {
                if child.expandedName == SVGElementName.tspan {
                    let innerContent = parseTextContent(from: child, styleRules: styleRules, ancestors: childAncestors)
                    let tspan = ElementParsers.parseTSpan(from: child, content: innerContent, styleRules: styleRules, ancestors: childAncestors)
                    content.append(.span(tspan))

                } else if child.expandedName == SVGElementName.textPath {
                    let text = child.textContent
                    let textPath = ElementParsers.parseTextPath(from: child, content: text, styleRules: styleRules, ancestors: childAncestors)
                    content.append(.reference(textPath))
                }
            }
        }

        return content
    }

    private func normalizeTextContent(_ text: String) -> String {
        let collapsed = text.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

public enum SVGParseError: Error {
    case noRootElement
    case invalidRootElement(String)
    case parsingFailed(String)
}

// MARK: - CSS Parsing (Basic)

struct CSSRule {
    var selector: String
    var properties: [String: String]
}

struct CSSParser {
    static func parse(_ css: String) -> [CSSRule] {
        var rules: [CSSRule] = []

        let strippedCSS = stripComments(from: css)

        // Very basic CSS parsing - extract rule blocks
        let rulePattern = #"([^{]+)\{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: rulePattern) else {
            return rules
        }

        let range = NSRange(strippedCSS.startIndex..., in: strippedCSS)
        let matches = regex.matches(in: strippedCSS, range: range)

        for match in matches {
            guard let selectorRange = Range(match.range(at: 1), in: strippedCSS),
                  let bodyRange = Range(match.range(at: 2), in: strippedCSS) else { continue }

            let selector = String(strippedCSS[selectorRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let body = String(strippedCSS[bodyRange])

            var properties: [String: String] = [:]
            let declarations = body.split(separator: ";")
            for declaration in declarations {
                let parts = declaration.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let property = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                properties[property] = value
            }

            rules.append(CSSRule(selector: selector, properties: properties))
        }

        return rules
    }

    private static func stripComments(from css: String) -> String {
        let pattern = #"/\*.*?\*/"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return css
        }
        let range = NSRange(css.startIndex..., in: css)
        return regex.stringByReplacingMatches(in: css, range: range, withTemplate: "")
    }
}

// MARK: - Node Extension for textContent

extension Node {
    var textContent: String {
        var result = ""
        for child in children {
            if child.kind == .text || child.kind == .cdata {
                result += child.value
            } else if child.kind == .element {
                result += child.textContent
            }
        }
        return result
    }
}
