import Foundation

/// The root SVG element
public struct SVG: ContainerElement, GraphicElement, Sendable {
    var id: String?
    var presentation: PresentationAttributes

    var width: Length?
    var height: Length?
    var viewBox: ViewBox?
    var preserveAspectRatio: PreserveAspectRatio?

    var children: [any GraphicElement]
    var definitions: Definitions

    init(
        id: String? = nil,
        width: Length? = nil,
        height: Length? = nil,
        viewBox: ViewBox? = nil,
        preserveAspectRatio: PreserveAspectRatio? = nil,
        children: [any GraphicElement] = [],
        definitions: Definitions = Definitions(),
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.viewBox = viewBox
        self.preserveAspectRatio = preserveAspectRatio
        self.children = children
        self.definitions = definitions
        self.presentation = presentation
    }

    /// Parse an SVG document from a URL.
    public init(url: URL) throws {
        self = try SVGParser().parse(url: url)
    }

    /// Parse an SVG document from raw data.
    public init(data: Data) throws {
        self = try SVGParser().parse(data: data)
    }

    /// Parse an SVG document from a string.
    public init(string: String) throws {
        self = try SVGParser().parse(string: string)
    }

    /// The resolved size of the SVG, using `width`/`height` or `viewBox` as fallback.
    public var size: (width: Double, height: Double)? {
        let resolvedWidth = width?.resolvedValue(viewport: viewBox?.width) ?? viewBox?.width
        let resolvedHeight = height?.resolvedValue(viewport: viewBox?.height) ?? viewBox?.height
        guard let resolvedWidth, let resolvedHeight else {
            return nil
        }
        return (width: resolvedWidth, height: resolvedHeight)
    }

}
