import Foundation

public struct DrawContext: Sendable {
    public var presentation: PresentationAttributes
    public var transforms: [Transform]
    public var viewBox: ViewBox?
    public var viewSize: (width: Length?, height: Length?)
    public var definitions: Definitions

    public init(
        presentation: PresentationAttributes = PresentationAttributes(),
        transforms: [Transform] = [],
        viewBox: ViewBox? = nil,
        viewSize: (width: Length?, height: Length?) = (nil, nil),
        definitions: Definitions = Definitions()
    ) {
        self.presentation = presentation
        self.transforms = transforms
        self.viewBox = viewBox
        self.viewSize = viewSize
        self.definitions = definitions
    }
}

public struct DrawOptions: Sendable {
    public var resolveUseElements: Bool
    public var includeDefs: Bool
    public var inheritPresentation: Bool
    public var applyUseTranslation: Bool

    public init(
        resolveUseElements: Bool = true,
        includeDefs: Bool = false,
        inheritPresentation: Bool = true,
        applyUseTranslation: Bool = true
    ) {
        self.resolveUseElements = resolveUseElements
        self.includeDefs = includeDefs
        self.inheritPresentation = inheritPresentation
        self.applyUseTranslation = applyUseTranslation
    }
}

public enum DrawDirective: Sendable {
    case `continue`
    case skipChildren
    case stop
}

public struct TextRun: Hashable, Sendable {
    public var text: String
    public var presentation: PresentationAttributes

    public init(text: String, presentation: PresentationAttributes) {
        self.text = text
        self.presentation = presentation
    }
}

public enum DrawEvent: Sendable {
    case beginSVG(SVG)
    case endSVG(SVG)
    case beginGroup(Group)
    case endGroup(Group)
    case beginAnchor(Anchor)
    case endAnchor(Anchor)
    case beginSwitch(Switch)
    case endSwitch(Switch)
    case drawRect(Rect)
    case drawCircle(Circle)
    case drawEllipse(Ellipse)
    case drawLine(Line)
    case drawPolyline(Polyline)
    case drawPolygon(Polygon)
    case drawPath(Path)
    case drawText(Text, runs: [TextRun])
    case drawImage(Image)
    case use(Use, resolved: (any GraphicElement)?)
    case defs(Defs)
}

public protocol DrawCallback: Sendable {
    func handle(event: DrawEvent, context: DrawContext) -> DrawDirective
}

public extension SVG {
    func walk(callback: DrawCallback, options: DrawOptions = DrawOptions()) {
        var rootContext = DrawContext(
            presentation: presentation,
            transforms: presentation.transform ?? [],
            viewBox: viewBox,
            viewSize: (width, height),
            definitions: definitions
        )

        if options.includeDefs {
            for defs in definitions.defs {
                if callback.handle(event: .defs(defs), context: rootContext) == .stop {
                    return
                }
            }
        }

        let directive = callback.handle(event: .beginSVG(self), context: rootContext)
        if directive == .stop { return }

        if directive != .skipChildren {
            if walkChildren(children, callback: callback, context: &rootContext, options: options) == false {
                return
            }
        }

        _ = callback.handle(event: .endSVG(self), context: rootContext)
    }
}

private func walkChildren(
    _ children: [any GraphicElement],
    callback: DrawCallback,
    context: inout DrawContext,
    options: DrawOptions
) -> Bool {
    for child in children {
        if walkElement(child, callback: callback, context: context, options: options) == false {
            return false
        }
    }
    return true
}

private func walkElement(
    _ element: any GraphicElement,
    callback: DrawCallback,
    context: DrawContext,
    options: DrawOptions
) -> Bool {
    if let group = element as? Group {
        var childContext = inheritContext(context, element: group, options: options)
        let directive = callback.handle(event: .beginGroup(group), context: childContext)
        if directive == .stop { return false }
        if directive != .skipChildren {
            if walkChildren(group.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.handle(event: .endGroup(group), context: childContext) != .stop
    }

    if let anchor = element as? Anchor {
        var childContext = inheritContext(context, element: anchor, options: options)
        let directive = callback.handle(event: .beginAnchor(anchor), context: childContext)
        if directive == .stop { return false }
        if directive != .skipChildren {
            if walkChildren(anchor.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.handle(event: .endAnchor(anchor), context: childContext) != .stop
    }

    if let switchNode = element as? Switch {
        var childContext = inheritContext(context, element: switchNode, options: options)
        let directive = callback.handle(event: .beginSwitch(switchNode), context: childContext)
        if directive == .stop { return false }
        if directive != .skipChildren {
            if walkChildren(switchNode.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.handle(event: .endSwitch(switchNode), context: childContext) != .stop
    }

    if let svg = element as? SVG {
        var childContext = DrawContext(
            presentation: svg.presentation,
            transforms: svg.presentation.transform ?? [],
            viewBox: svg.viewBox,
            viewSize: (svg.width, svg.height),
            definitions: context.definitions
        )

        let directive = callback.handle(event: .beginSVG(svg), context: childContext)
        if directive == .stop { return false }
        if directive != .skipChildren {
            if walkChildren(svg.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.handle(event: .endSVG(svg), context: childContext) != .stop
    }

    if let use = element as? Use {
        var childContext = inheritContext(context, element: use, options: options)
        if options.applyUseTranslation {
            if let x = use.x?.value, let y = use.y?.value {
                childContext.transforms.append(.translate(x: x, y: y))
            } else if let x = use.x?.value {
                childContext.transforms.append(.translate(x: x, y: 0))
            } else if let y = use.y?.value {
                childContext.transforms.append(.translate(x: 0, y: y))
            }
        }

        let resolved = use.href.flatMap { context.definitions.elements[$0] }
        let directive = callback.handle(event: .use(use, resolved: resolved), context: childContext)
        if directive == .stop { return false }

        if options.resolveUseElements, directive != .skipChildren, let resolved {
            return walkElement(resolved, callback: callback, context: childContext, options: options)
        }
        return true
    }

    let leafContext = inheritContext(context, element: element, options: options)

    if let rect = element as? Rect {
        return callback.handle(event: .drawRect(rect), context: leafContext) != .stop
    }
    if let circle = element as? Circle {
        return callback.handle(event: .drawCircle(circle), context: leafContext) != .stop
    }
    if let ellipse = element as? Ellipse {
        return callback.handle(event: .drawEllipse(ellipse), context: leafContext) != .stop
    }
    if let line = element as? Line {
        return callback.handle(event: .drawLine(line), context: leafContext) != .stop
    }
    if let polyline = element as? Polyline {
        return callback.handle(event: .drawPolyline(polyline), context: leafContext) != .stop
    }
    if let polygon = element as? Polygon {
        return callback.handle(event: .drawPolygon(polygon), context: leafContext) != .stop
    }
    if let path = element as? Path {
        return callback.handle(event: .drawPath(path), context: leafContext) != .stop
    }
    if let text = element as? Text {
        let runs = buildTextRuns(from: text.content, basePresentation: leafContext.presentation)
        return callback.handle(event: .drawText(text, runs: runs), context: leafContext) != .stop
    }
    if let image = element as? Image {
        return callback.handle(event: .drawImage(image), context: leafContext) != .stop
    }

    return true
}

private func inheritContext(
    _ parent: DrawContext,
    element: any GraphicElement,
    options: DrawOptions
) -> DrawContext {
    var presentation = element.presentation
    if options.inheritPresentation {
        presentation = parent.presentation.merged(with: element.presentation)
    }

    var transforms = parent.transforms
    if let local = element.presentation.transform {
        transforms.append(contentsOf: local)
    }

    return DrawContext(
        presentation: presentation,
        transforms: transforms,
        viewBox: parent.viewBox,
        viewSize: parent.viewSize,
        definitions: parent.definitions
    )
}

private func buildTextRuns(from content: [TextContent], basePresentation: PresentationAttributes) -> [TextRun] {
    var runs: [TextRun] = []
    for item in content {
        switch item {
        case .text(let text):
            runs.append(TextRun(text: text, presentation: basePresentation))
        case .span(let tspan):
            let presentation = basePresentation.merged(with: tspan.presentation)
            runs.append(contentsOf: buildTextRuns(from: tspan.content, basePresentation: presentation))
        case .reference(let textPath):
            let presentation = basePresentation.merged(with: textPath.presentation)
            runs.append(TextRun(text: textPath.content, presentation: presentation))
        }
    }
    return runs
}
