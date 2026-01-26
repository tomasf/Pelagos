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

    // Position (for nested SVGs)
    var x: Length?
    var y: Length?

    var width: Length?
    var height: Length?
    var viewBox: ViewBox?
    var preserveAspectRatio: PreserveAspectRatio?

    var children: [any GraphicElement]
    var definitions: Definitions

    init(
        id: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        viewBox: ViewBox? = nil,
        preserveAspectRatio: PreserveAspectRatio? = nil,
        children: [any GraphicElement] = [],
        definitions: Definitions = Definitions(),
        presentation: PresentationAttributes = PresentationAttributes()
    ) {
        self.id = id
        self.x = x
        self.y = y
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
    /// When only one dimension is specified with a viewBox, the other dimension
    /// is computed to preserve the viewBox aspect ratio.
    /// Returns `nil` if neither width/height nor viewBox provide size information.
    public var size: (width: Double, height: Double)? {
        let explicitWidth = width?.resolvedValue(viewport: viewBox?.width)
        let explicitHeight = height?.resolvedValue(viewport: viewBox?.height)

        switch (explicitWidth, explicitHeight, viewBox) {
        case let (w?, h?, _):
            // Both dimensions specified
            return (width: w, height: h)
        case let (w?, nil, vb?) where vb.height > 0:
            // Only width specified - compute height from aspect ratio
            return (width: w, height: w * vb.height / vb.width)
        case let (nil, h?, vb?) where vb.width > 0:
            // Only height specified - compute width from aspect ratio
            return (width: h * vb.width / vb.height, height: h)
        case let (nil, nil, vb?):
            // No dimensions - use viewBox
            return (width: vb.width, height: vb.height)
        default:
            return nil
        }
    }

}
