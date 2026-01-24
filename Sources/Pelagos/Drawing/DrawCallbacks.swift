import Foundation

public struct DrawContext: Sendable {
    public var presentation: PresentationAttributes
    public var resolvedPaint: ResolvedPaint
    public var transforms: [Transform]
    public var viewBox: ViewBox?
    public var viewSize: (width: Length?, height: Length?)
    public var definitions: Definitions

    public init(
        presentation: PresentationAttributes = PresentationAttributes(),
        resolvedPaint: ResolvedPaint = ResolvedPaint(),
        transforms: [Transform] = [],
        viewBox: ViewBox? = nil,
        viewSize: (width: Length?, height: Length?) = (nil, nil),
        definitions: Definitions = Definitions()
    ) {
        self.presentation = presentation
        self.resolvedPaint = resolvedPaint
        self.transforms = transforms
        self.viewBox = viewBox
        self.viewSize = viewSize
        self.definitions = definitions
    }
}

public struct ResolvedPaint: Sendable {
    public var fillColor: Color?
    public var strokeColor: Color?
    public var fillAlpha: Double
    public var strokeAlpha: Double
    public var fillRule: FillRule
    public var lineWidth: Double?
    public var lineCap: LineCap?
    public var lineJoin: LineJoin?
    public var miterLimit: Double?
    public var dashArray: [Double]?
    public var dashOffset: Double?

    public init(
        fillColor: Color? = nil,
        strokeColor: Color? = nil,
        fillAlpha: Double = 1,
        strokeAlpha: Double = 1,
        fillRule: FillRule = .nonzero,
        lineWidth: Double? = nil,
        lineCap: LineCap? = nil,
        lineJoin: LineJoin? = nil,
        miterLimit: Double? = nil,
        dashArray: [Double]? = nil,
        dashOffset: Double? = nil
    ) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.fillAlpha = fillAlpha
        self.strokeAlpha = strokeAlpha
        self.fillRule = fillRule
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        self.lineJoin = lineJoin
        self.miterLimit = miterLimit
        self.dashArray = dashArray
        self.dashOffset = dashOffset
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
    case drawRect(Rect, resolved: ResolvedRect)
    case drawCircle(Circle, resolved: ResolvedCircle)
    case drawEllipse(Ellipse, resolved: ResolvedEllipse)
    case drawLine(Line, resolved: ResolvedLine)
    case drawPolyline(Polyline, resolved: ResolvedPolyline)
    case drawPolygon(Polygon, resolved: ResolvedPolygon)
    case drawPath(Path)
    case drawText(Text, runs: [TextRun])
    case drawImage(Image, resolved: ResolvedImage?)
    case use(Use, resolved: (any GraphicElement)?)
    case defs(Defs)
}

public struct ResolvedImage: Sendable {
    public var data: Data
    public var mimeType: String?

    public init(data: Data, mimeType: String? = nil) {
        self.data = data
        self.mimeType = mimeType
    }
}

public struct ResolvedRect: Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var rx: Double
    public var ry: Double
}

public struct ResolvedCircle: Sendable {
    public var cx: Double
    public var cy: Double
    public var r: Double
}

public struct ResolvedEllipse: Sendable {
    public var cx: Double
    public var cy: Double
    public var rx: Double
    public var ry: Double
}

public struct ResolvedLine: Sendable {
    public var x1: Double
    public var y1: Double
    public var x2: Double
    public var y2: Double
}

public struct ResolvedPolyline: Sendable {
    public var points: [Point]
}

public struct ResolvedPolygon: Sendable {
    public var points: [Point]
}

public protocol DrawCallback: Sendable {
    func handle(event: DrawEvent, context: DrawContext) -> DrawDirective
}

public extension SVG {
    func walk(callback: DrawCallback, options: DrawOptions = DrawOptions()) {
        let resolvedPaint = resolvePaint(from: presentation)
        var rootContext = DrawContext(
            presentation: presentation,
            resolvedPaint: resolvedPaint,
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
            if walkSwitchChildren(switchNode.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.handle(event: .endSwitch(switchNode), context: childContext) != .stop
    }

        if let svg = element as? SVG {
        let resolvedPaint = resolvePaint(from: svg.presentation)
        var childContext = DrawContext(
            presentation: svg.presentation,
            resolvedPaint: resolvedPaint,
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
        let resolved = resolveRect(rect, context: leafContext)
        return callback.handle(event: .drawRect(rect, resolved: resolved), context: leafContext) != .stop
    }
    if let circle = element as? Circle {
        let resolved = resolveCircle(circle, context: leafContext)
        return callback.handle(event: .drawCircle(circle, resolved: resolved), context: leafContext) != .stop
    }
    if let ellipse = element as? Ellipse {
        let resolved = resolveEllipse(ellipse, context: leafContext)
        return callback.handle(event: .drawEllipse(ellipse, resolved: resolved), context: leafContext) != .stop
    }
    if let line = element as? Line {
        let resolved = resolveLine(line, context: leafContext)
        return callback.handle(event: .drawLine(line, resolved: resolved), context: leafContext) != .stop
    }
    if let polyline = element as? Polyline {
        let resolved = ResolvedPolyline(points: polyline.points)
        return callback.handle(event: .drawPolyline(polyline, resolved: resolved), context: leafContext) != .stop
    }
    if let polygon = element as? Polygon {
        let resolved = ResolvedPolygon(points: polygon.points)
        return callback.handle(event: .drawPolygon(polygon, resolved: resolved), context: leafContext) != .stop
    }
    if let path = element as? Path {
        return callback.handle(event: .drawPath(path), context: leafContext) != .stop
    }
    if let text = element as? Text {
        let runs = buildTextRuns(from: text.content, basePresentation: leafContext.presentation)
        return callback.handle(event: .drawText(text, runs: runs), context: leafContext) != .stop
    }
    if let image = element as? Image {
        let resolved = resolveImage(from: image.href)
        return callback.handle(event: .drawImage(image, resolved: resolved), context: leafContext) != .stop
    }

    return true
}

private func resolveImage(from href: String?) -> ResolvedImage? {
    guard let href, href.hasPrefix("data:") else { return nil }
    return decodeDataURL(href)
}

private func resolveRect(_ rect: Rect, context: DrawContext) -> ResolvedRect {
    let refs = resolveViewReferences(context)
    let x = resolveLength(rect.x, viewRef: refs.width, fontSize: refs.fontSize)
    let y = resolveLength(rect.y, viewRef: refs.height, fontSize: refs.fontSize)
    let width = resolveLength(rect.width, viewRef: refs.width, fontSize: refs.fontSize)
    let height = resolveLength(rect.height, viewRef: refs.height, fontSize: refs.fontSize)
    let rx = resolveLength(rect.rx ?? rect.ry, viewRef: refs.width, fontSize: refs.fontSize)
    let ry = resolveLength(rect.ry ?? rect.rx, viewRef: refs.height, fontSize: refs.fontSize)
    return ResolvedRect(x: x, y: y, width: width, height: height, rx: rx, ry: ry)
}

private func resolveCircle(_ circle: Circle, context: DrawContext) -> ResolvedCircle {
    let refs = resolveViewReferences(context)
    let cx = resolveLength(circle.cx, viewRef: refs.width, fontSize: refs.fontSize)
    let cy = resolveLength(circle.cy, viewRef: refs.height, fontSize: refs.fontSize)
    let r = resolveLength(circle.r, viewRef: min(refs.width, refs.height), fontSize: refs.fontSize)
    return ResolvedCircle(cx: cx, cy: cy, r: r)
}

private func resolveEllipse(_ ellipse: Ellipse, context: DrawContext) -> ResolvedEllipse {
    let refs = resolveViewReferences(context)
    let cx = resolveLength(ellipse.cx, viewRef: refs.width, fontSize: refs.fontSize)
    let cy = resolveLength(ellipse.cy, viewRef: refs.height, fontSize: refs.fontSize)
    let rx = resolveLength(ellipse.rx, viewRef: refs.width, fontSize: refs.fontSize)
    let ry = resolveLength(ellipse.ry, viewRef: refs.height, fontSize: refs.fontSize)
    return ResolvedEllipse(cx: cx, cy: cy, rx: rx, ry: ry)
}

private func resolveLine(_ line: Line, context: DrawContext) -> ResolvedLine {
    let refs = resolveViewReferences(context)
    let x1 = resolveLength(line.x1, viewRef: refs.width, fontSize: refs.fontSize)
    let y1 = resolveLength(line.y1, viewRef: refs.height, fontSize: refs.fontSize)
    let x2 = resolveLength(line.x2, viewRef: refs.width, fontSize: refs.fontSize)
    let y2 = resolveLength(line.y2, viewRef: refs.height, fontSize: refs.fontSize)
    return ResolvedLine(x1: x1, y1: y1, x2: x2, y2: y2)
}

private func resolveViewReferences(_ context: DrawContext) -> (width: Double, height: Double, fontSize: Double) {
    let width = context.viewBox?.width
        ?? context.viewSize.width?.resolvedValue()
        ?? 0
    let height = context.viewBox?.height
        ?? context.viewSize.height?.resolvedValue()
        ?? 0
    let fontSize = context.presentation.fontSize?.resolvedValue(viewport: height) ?? 16
    return (width, height, fontSize)
}

private func resolveLength(_ length: Length?, viewRef: Double, fontSize: Double) -> Double {
    guard let length else { return 0 }
    return length.resolvedValue(fontSize: fontSize, viewport: viewRef)
}

private func decodeDataURL(_ href: String) -> ResolvedImage? {
    let parts = href.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2 else { return nil }

    let meta = String(parts[0])
    let payload = String(parts[1])
    guard meta.contains("base64"),
          let data = Data(base64Encoded: payload) else {
        return nil
    }

    let mimeType = meta
        .dropFirst("data:".count)
        .split(separator: ";", maxSplits: 1)
        .first
        .map(String.init)

    return ResolvedImage(data: data, mimeType: mimeType)
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

    let resolvedPaint = resolvePaint(from: presentation)

    return DrawContext(
        presentation: presentation,
        resolvedPaint: resolvedPaint,
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

private func walkSwitchChildren(
    _ children: [any GraphicElement],
    callback: DrawCallback,
    context: inout DrawContext,
    options: DrawOptions
) -> Bool {
    guard let first = children.first else { return true }
    return walkElement(first, callback: callback, context: context, options: options)
}

private func resolvePaint(from presentation: PresentationAttributes) -> ResolvedPaint {
    let opacity = presentation.opacity ?? 1
    let fillOpacity = presentation.fillOpacity ?? 1
    let strokeOpacity = presentation.strokeOpacity ?? 1
    let fontSize = presentation.fontSize?.resolvedValue() ?? 16

    let fillColor = resolveFillColor(from: presentation.fill)
    let strokeColor = resolveStrokeColor(from: presentation.stroke)

    let miterLimit = presentation.strokeMiterLimit ?? 4

    return ResolvedPaint(
        fillColor: fillColor,
        strokeColor: strokeColor,
        fillAlpha: opacity * fillOpacity,
        strokeAlpha: opacity * strokeOpacity,
        fillRule: presentation.fillRule ?? .nonzero,
        lineWidth: presentation.strokeWidth?.resolvedValue(fontSize: fontSize),
        lineCap: presentation.strokeLineCap,
        lineJoin: presentation.strokeLineJoin,
        miterLimit: miterLimit,
        dashArray: presentation.strokeDashArray?.map { $0.resolvedValue(fontSize: fontSize) },
        dashOffset: presentation.strokeDashOffset?.resolvedValue(fontSize: fontSize)
    )
}

private func resolveFillColor(from fill: Fill?) -> Color? {
    switch fill {
    case .some(.none):
        return nil
    case .some(.color(let color)):
        return color
    case .some(.urlWithFallback(_, let fallback)):
        return fallback
    case .some(.url):
        return nil
    case nil:
        return .black
    }
}

private func resolveStrokeColor(from stroke: Fill?) -> Color? {
    switch stroke {
    case .some(.none):
        return nil
    case .some(.color(let color)):
        return color
    case .some(.urlWithFallback(_, let fallback)):
        return fallback
    case .some(.url):
        return nil
    case nil:
        return nil
    }
}
