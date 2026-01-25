import Foundation

/// The root element of an SVG document.
///
/// Use `SVG` to parse and render SVG documents. Create an instance from a file,
/// data, or string, then render it using an ``SVGRenderer`` implementation.
///
/// ## Parsing SVG Documents
///
/// ```swift
/// // From a file
/// let svg = try SVG(url: fileURL)
///
/// // From a string
/// let svg = try SVG(string: "<svg>...</svg>")
///
/// // From data
/// let svg = try SVG(data: svgData)
/// ```
///
/// ## Rendering
///
/// ```swift
/// // Render to a Core Graphics context
/// svg.render(to: cgContext)
///
/// // Render with a custom renderer
/// svg.render(with: myRenderer)
///
/// // Render at a specific size
/// svg.render(with: renderer, size: (width: 800, height: 600))
/// ```
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

    /// Parses an SVG document from a file URL.
    /// - Parameter url: The file URL pointing to an SVG document.
    /// - Throws: An error if the file cannot be read or parsed.
    public init(url: URL) throws {
        self = try SVGParser().parse(url: url)
    }

    /// Parses an SVG document from raw data.
    /// - Parameter data: The SVG document data (UTF-8 encoded).
    /// - Throws: An error if the data cannot be parsed.
    public init(data: Data) throws {
        self = try SVGParser().parse(data: data)
    }

    /// Parses an SVG document from a string.
    /// - Parameter string: The SVG document as a string.
    /// - Throws: An error if the string cannot be parsed.
    public init(string: String) throws {
        self = try SVGParser().parse(string: string)
    }

    /// The intrinsic size of the SVG document.
    ///
    /// Returns the size specified by the `width` and `height` attributes,
    /// falling back to the `viewBox` dimensions if those are not specified.
    /// Returns `nil` if neither width/height nor viewBox provide size information.
    public var size: (width: Double, height: Double)? {
        let resolvedWidth = width?.resolvedValue(viewport: viewBox?.width) ?? viewBox?.width
        let resolvedHeight = height?.resolvedValue(viewport: viewBox?.height) ?? viewBox?.height
        guard let resolvedWidth, let resolvedHeight else {
            return nil
        }
        return (width: resolvedWidth, height: resolvedHeight)
    }

}
