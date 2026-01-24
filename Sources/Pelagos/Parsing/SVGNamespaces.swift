import Foundation
import Nodal

enum SVGNamespace {
    static let svg = "http://www.w3.org/2000/svg"
    static let xlink = "http://www.w3.org/1999/xlink"
}

enum SVGElementName {
    static let svg = ExpandedName(namespaceName: SVGNamespace.svg, localName: "svg")
    static let g = ExpandedName(namespaceName: SVGNamespace.svg, localName: "g")
    static let defs = ExpandedName(namespaceName: SVGNamespace.svg, localName: "defs")
    static let style = ExpandedName(namespaceName: SVGNamespace.svg, localName: "style")
    static let desc = ExpandedName(namespaceName: SVGNamespace.svg, localName: "desc")
    static let title = ExpandedName(namespaceName: SVGNamespace.svg, localName: "title")
    static let metadata = ExpandedName(namespaceName: SVGNamespace.svg, localName: "metadata")

    static let rect = ExpandedName(namespaceName: SVGNamespace.svg, localName: "rect")
    static let circle = ExpandedName(namespaceName: SVGNamespace.svg, localName: "circle")
    static let ellipse = ExpandedName(namespaceName: SVGNamespace.svg, localName: "ellipse")
    static let line = ExpandedName(namespaceName: SVGNamespace.svg, localName: "line")
    static let polyline = ExpandedName(namespaceName: SVGNamespace.svg, localName: "polyline")
    static let polygon = ExpandedName(namespaceName: SVGNamespace.svg, localName: "polygon")
    static let path = ExpandedName(namespaceName: SVGNamespace.svg, localName: "path")

    static let linearGradient = ExpandedName(namespaceName: SVGNamespace.svg, localName: "linearGradient")
    static let radialGradient = ExpandedName(namespaceName: SVGNamespace.svg, localName: "radialGradient")
    static let pattern = ExpandedName(namespaceName: SVGNamespace.svg, localName: "pattern")
    static let clipPath = ExpandedName(namespaceName: SVGNamespace.svg, localName: "clipPath")
    static let mask = ExpandedName(namespaceName: SVGNamespace.svg, localName: "mask")
    static let filter = ExpandedName(namespaceName: SVGNamespace.svg, localName: "filter")
    static let symbol = ExpandedName(namespaceName: SVGNamespace.svg, localName: "symbol")
    static let stop = ExpandedName(namespaceName: SVGNamespace.svg, localName: "stop")

    static let anchor = ExpandedName(namespaceName: SVGNamespace.svg, localName: "a")
    static let `switch` = ExpandedName(namespaceName: SVGNamespace.svg, localName: "switch")
    static let use = ExpandedName(namespaceName: SVGNamespace.svg, localName: "use")
    static let image = ExpandedName(namespaceName: SVGNamespace.svg, localName: "image")
    static let text = ExpandedName(namespaceName: SVGNamespace.svg, localName: "text")
    static let tspan = ExpandedName(namespaceName: SVGNamespace.svg, localName: "tspan")
    static let textPath = ExpandedName(namespaceName: SVGNamespace.svg, localName: "textPath")
}

enum SVGAttributeName {
    static let href = ExpandedName(namespaceName: SVGNamespace.xlink, localName: "href")
}

extension Node {
    func xlinkAttribute(_ localName: String) -> String? {
        self[attribute: ExpandedName(namespaceName: SVGNamespace.xlink, localName: localName)]
    }

    func attribute(localName: String, prefix: String?) -> String? {
        guard let prefix else {
            return self[attribute: localName]
        }
        guard let namespaceURI = namespacesInScope[prefix] else { return nil }
        return self[attribute: ExpandedName(namespaceName: namespaceURI, localName: localName)]
    }
}
