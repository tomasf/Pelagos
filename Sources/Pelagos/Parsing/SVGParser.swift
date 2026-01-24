import Foundation
import Nodal

/// Parser for SVG documents
public struct SVGParser {
    public init() {}

    // MARK: - Public API

    /// Parse SVG from a URL
    public func parse(url: URL) throws -> SVG {
        let document = try Document(url: url)
        return try parse(document: document)
    }

    /// Parse SVG from data
    public func parse(data: Data) throws -> SVG {
        let document = try Document(data: data)
        return try parse(document: document)
    }

    /// Parse SVG from a string
    public func parse(string: String) throws -> SVG {
        let document = try Document(string: string)
        return try parse(document: document)
    }

    // MARK: - Internal Parsing

    private func parse(document: Document) throws -> SVG {
        guard let root = document.documentElement else {
            throw SVGParseError.noRootElement
        }

        guard root.name == "svg" else {
            throw SVGParseError.invalidRootElement(root.name)
        }

        var definitions = Definitions()
        var styleRules: [CSSRule] = []

        // First pass: collect styles
        collectStyles(from: root, styles: &styleRules)

        // Second pass: collect definitions and parse the tree
        collectDefinitions(from: root, into: &definitions, styleRules: styleRules)
        collectDefsContainers(from: root, into: &definitions, styleRules: styleRules)
        let children = try parseChildren(of: root, definitions: &definitions, styleRules: styleRules)

        return SVG(
            id: root[attribute: "id"],
            width: AttributeParser.parseLength(root[attribute: "width"]),
            height: AttributeParser.parseLength(root[attribute: "height"]),
            viewBox: AttributeParser.parseViewBox(root[attribute: "viewBox"]),
            preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(root[attribute: "preserveAspectRatio"]),
            children: children,
            definitions: definitions,
            presentation: PresentationParser.parse(from: root, styleRules: styleRules)
        )
    }

    // MARK: - Style Collection

    private func collectStyles(from node: Node, styles: inout [CSSRule]) {
        // Skip non-element nodes
        guard node.kind == .element else { return }

        // Collect style elements
        if node.name == "style" {
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

    private func collectDefinitions(from node: Node, into definitions: inout Definitions, styleRules: [CSSRule]) {
        // Skip non-element nodes
        guard node.kind == .element else { return }

        // Process defs container
        if node.name == "defs" {
            for child in node.elements {
                collectDefinition(from: child, into: &definitions, styleRules: styleRules)
            }
        }

        // Recurse
        for child in node.elements {
            collectDefinitions(from: child, into: &definitions, styleRules: styleRules)
        }
    }

    private func collectDefinition(from node: Node, into definitions: inout Definitions, styleRules: [CSSRule]) {
        guard let id = node[attribute: "id"], !id.isEmpty else { return }

        switch node.name {
        case "linearGradient":
            let stops = parseGradientStops(from: node)
            let gradient = ElementParsers.parseLinearGradient(from: node, stops: stops)
            definitions.gradients[id] = gradient

        case "radialGradient":
            let stops = parseGradientStops(from: node)
            let gradient = ElementParsers.parseRadialGradient(from: node, stops: stops)
            definitions.gradients[id] = gradient

        case "pattern":
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules)) ?? []
            let pattern = ElementParsers.parsePattern(from: node, children: children)
            definitions.patterns[id] = pattern

        case "clipPath":
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules)) ?? []
            let clipPath = ElementParsers.parseClipPath(from: node, children: children)
            definitions.clipPaths[id] = clipPath

        case "mask":
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules)) ?? []
            let mask = ElementParsers.parseMask(from: node, children: children)
            definitions.masks[id] = mask

        case "filter":
            let primitives = parseFilterPrimitives(from: node)
            let filter = ElementParsers.parseFilter(from: node, primitives: primitives)
            definitions.filters[id] = filter

        case "symbol":
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules)) ?? []
            let symbol = ElementParsers.parseSymbol(from: node, children: children)
            definitions.symbols[id] = symbol

        default:
            // Store other elements with ids for use references
            if let graphic = try? parseElement(node, definitions: &definitions, styleRules: styleRules) {
                definitions.elements[id] = graphic
            }
        }
    }

    private func collectDefsContainers(from node: Node, into definitions: inout Definitions, styleRules: [CSSRule]) {
        guard node.kind == .element else { return }

        if node.name == "defs" {
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs, styleRules: styleRules)) ?? []
            let defs = Defs(id: node[attribute: "id"], children: children)
            definitions.defs.append(defs)
        }

        for child in node.elements {
            collectDefsContainers(from: child, into: &definitions, styleRules: styleRules)
        }
    }

    // MARK: - Element Parsing

    private func parseChildren(of parent: Node, definitions: inout Definitions, styleRules: [CSSRule]) throws -> [any GraphicElement] {
        var children: [any GraphicElement] = []

        for child in parent.elements {
            // Skip defs, style, and non-graphic elements
            if child.name == "defs" || child.name == "style" || child.name == "desc" ||
               child.name == "title" || child.name == "metadata" {
                continue
            }

            // Skip definition elements at top level (they're in defs)
            if ["linearGradient", "radialGradient", "pattern", "clipPath", "mask", "filter", "symbol"].contains(child.name) {
                // Still collect them if they have ids
                if child[attribute: "id"] != nil {
                    collectDefinition(from: child, into: &definitions, styleRules: styleRules)
                }
                continue
            }

            if let graphic = try? parseElement(child, definitions: &definitions, styleRules: styleRules) {
                children.append(graphic)

                // Register if it has an id
                if let id = graphic.id {
                    definitions.elements[id] = graphic
                }
            }
        }

        return children
    }

    private func parseElement(_ node: Node, definitions: inout Definitions, styleRules: [CSSRule]) throws -> (any GraphicElement)? {
        switch node.name {
        // Shapes
        case "rect":
            return ElementParsers.parseRect(from: node, styleRules: styleRules)

        case "circle":
            return ElementParsers.parseCircle(from: node, styleRules: styleRules)

        case "ellipse":
            return ElementParsers.parseEllipse(from: node, styleRules: styleRules)

        case "line":
            return ElementParsers.parseLine(from: node, styleRules: styleRules)

        case "polyline":
            return ElementParsers.parsePolyline(from: node, styleRules: styleRules)

        case "polygon":
            return ElementParsers.parsePolygon(from: node, styleRules: styleRules)

        case "path":
            return try ElementParsers.parsePath(from: node, styleRules: styleRules)

        // Containers
        case "g":
            let children = try parseChildren(of: node, definitions: &definitions, styleRules: styleRules)
            return ElementParsers.parseGroup(from: node, children: children, styleRules: styleRules)

        case "svg":
            // Nested SVG
            let children = try parseChildren(of: node, definitions: &definitions, styleRules: styleRules)
            return SVG(
                id: node[attribute: "id"],
                width: AttributeParser.parseLength(node[attribute: "width"]),
                height: AttributeParser.parseLength(node[attribute: "height"]),
                viewBox: AttributeParser.parseViewBox(node[attribute: "viewBox"]),
                preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(node[attribute: "preserveAspectRatio"]),
                children: children,
                definitions: Definitions(),
                presentation: PresentationParser.parse(from: node, styleRules: styleRules)
            )

        case "a":
            let children = try parseChildren(of: node, definitions: &definitions, styleRules: styleRules)
            return ElementParsers.parseAnchor(from: node, children: children, styleRules: styleRules)

        case "switch":
            let children = try parseChildren(of: node, definitions: &definitions, styleRules: styleRules)
            return ElementParsers.parseSwitch(from: node, children: children, styleRules: styleRules)

        // References
        case "use":
            return ElementParsers.parseUse(from: node, styleRules: styleRules)

        // Content
        case "image":
            return ElementParsers.parseImage(from: node, styleRules: styleRules)

        case "text":
            let content = parseTextContent(from: node, styleRules: styleRules)
            return ElementParsers.parseText(from: node, content: content, styleRules: styleRules)

        default:
            // Unknown element - skip
            return nil
        }
    }

    // MARK: - Gradient Stops

    private func parseGradientStops(from node: Node) -> [GradientStop] {
        var stops: [GradientStop] = []

        for child in node.elements {
            if child.name == "stop", let stop = ElementParsers.parseGradientStop(from: child) {
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

    private func parseTextContent(from node: Node, styleRules: [CSSRule]) -> [TextContent] {
        var content: [TextContent] = []

        for child in node.children {
            if child.kind == .text || child.kind == .cdata {
                let text = child.value
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    content.append(.text(text))
                }
            } else if child.kind == .element {
                switch child.name {
                case "tspan":
                    let innerContent = parseTextContent(from: child, styleRules: styleRules)
                    let tspan = ElementParsers.parseTSpan(from: child, content: innerContent, styleRules: styleRules)
                    content.append(.span(tspan))

                case "textPath":
                    let text = child.textContent
                    let textPath = ElementParsers.parseTextPath(from: child, content: text, styleRules: styleRules)
                    content.append(.reference(textPath))

                default:
                    break
                }
            }
        }

        return content
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

        // Very basic CSS parsing - extract rule blocks
        let rulePattern = #"([^{]+)\{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: rulePattern) else {
            return rules
        }

        let range = NSRange(css.startIndex..., in: css)
        let matches = regex.matches(in: css, range: range)

        for match in matches {
            guard let selectorRange = Range(match.range(at: 1), in: css),
                  let bodyRange = Range(match.range(at: 2), in: css) else { continue }

            let selector = String(css[selectorRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let body = String(css[bodyRange])

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
