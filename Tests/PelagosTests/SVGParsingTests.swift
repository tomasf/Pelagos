import Testing
@testable import Pelagos

@Suite("SVG Parsing")
struct SVGParsingTests {
    @Test func `parses SVG with dimensions and viewBox`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg width="100" height="100" viewBox="0 0 100 100">
                <rect x="10" y="10" width="80" height="80" fill="red"/>
            </svg>
            """)

        #expect(svg.width?.value == 100)
        #expect(svg.height?.value == 100)
        #expect(svg.viewBox?.width == 100)
        #expect(svg.children.count == 1)
    }

    @Test func `parses basic shape elements`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <rect x="10" y="20" width="30" height="40"/>
                <circle cx="50" cy="50" r="25"/>
                <ellipse cx="100" cy="100" rx="20" ry="30"/>
                <line x1="0" y1="0" x2="100" y2="100"/>
            </svg>
            """)

        #expect(svg.children.count == 4)
    }

    @Test func `parses rect element with all attributes`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <rect id="myRect" x="10" y="20" width="100" height="50" rx="5" ry="5"/>
            </svg>
            """)

        if let rect = svg.children.first as? Rect {
            #expect(rect.id == "myRect")
            #expect(rect.x.value == 10)
            #expect(rect.y.value == 20)
            #expect(rect.width.value == 100)
            #expect(rect.height.value == 50)
            #expect(rect.rx?.value == 5)
            #expect(rect.ry?.value == 5)
        } else {
            Issue.record("Expected Rect")
        }
    }

    @Test func `parses group element with children`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <g id="group1" fill="blue">
                    <rect width="10" height="10"/>
                    <rect x="20" width="10" height="10"/>
                </g>
            </svg>
            """)

        #expect(svg.children.count == 1)
        if let group = svg.children.first as? Group {
            #expect(group.id == "group1")
            #expect(group.children.count == 2)
        } else {
            Issue.record("Expected Group")
        }
    }

    @Test func `parses linear gradient in defs`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <defs>
                    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" stop-color="red"/>
                        <stop offset="100%" stop-color="blue"/>
                    </linearGradient>
                </defs>
                <rect fill="url(#grad1)" width="100" height="100"/>
            </svg>
            """)

        #expect(svg.definitions.gradients["grad1"] != nil)
        if let gradient = svg.definitions.gradients["grad1"] as? LinearGradient {
            #expect(gradient.stops.count == 2)
            #expect(gradient.stops[0].offset == 0)
            #expect(gradient.stops[1].offset == 1)
        } else {
            Issue.record("Expected LinearGradient")
        }
    }

    @Test func `parses radial gradient in defs`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <defs>
                    <radialGradient id="grad2" cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stop-color="white"/>
                        <stop offset="100%" stop-color="black"/>
                    </radialGradient>
                </defs>
            </svg>
            """)

        if let gradient = svg.definitions.gradients["grad2"] as? RadialGradient {
            #expect(gradient.stops.count == 2)
        } else {
            Issue.record("Expected RadialGradient")
        }
    }

    @Test func `parses use element with href`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <defs>
                    <rect id="myRect" width="50" height="50"/>
                </defs>
                <use href="#myRect" x="10" y="10"/>
            </svg>
            """)

        #expect(svg.children.count == 1)
        if let use = svg.children.first as? Use {
            #expect(use.href == "myRect")
            #expect(use.x?.value == 10)
            #expect(use.y?.value == 10)
        } else {
            Issue.record("Expected Use")
        }
    }

    @Test func `parses use element with xlink href`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg xmlns:xlink="http://www.w3.org/1999/xlink">
                <defs>
                    <circle id="dot" r="5"/>
                </defs>
                <use xlink:href="#dot" x="50" y="50"/>
            </svg>
            """)

        if let use = svg.children.first as? Use {
            #expect(use.href == "dot")
        } else {
            Issue.record("Expected Use")
        }
    }

    @Test func `parses path element with d attribute`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <path d="M 10 10 L 90 10 L 90 90 L 10 90 Z" fill="green"/>
            </svg>
            """)

        if let path = svg.children.first as? Path {
            #expect(path.segments.count == 5)
        } else {
            Issue.record("Expected Path")
        }
    }

    @Test func `parses text element with content`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <text x="10" y="50" font-size="24">Hello World</text>
            </svg>
            """)

        if let text = svg.children.first as? Text {
            #expect(text.presentation.fontSize?.value == 24)
            if case .text(let str) = text.content.first {
                #expect(str == "Hello World")
            } else {
                Issue.record("Expected text content")
            }
        } else {
            Issue.record("Expected Text")
        }
    }

    @Test func `parses presentation attributes`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <rect fill="red" stroke="black" stroke-width="2" opacity="0.5"/>
            </svg>
            """)

        if let rect = svg.children.first as? Rect {
            #expect(rect.presentation.strokeWidth?.value == 2)
            #expect(rect.presentation.opacity == 0.5)
        } else {
            Issue.record("Expected Rect")
        }
    }

    @Test func `parses style attribute`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <rect style="fill: blue; stroke-width: 3px"/>
            </svg>
            """)

        if let rect = svg.children.first as? Rect {
            if case .color(let color) = rect.presentation.fill {
                #expect(color == Color.namedColors["blue"])
            } else {
                Issue.record("Expected blue fill")
            }
            #expect(rect.presentation.strokeWidth?.value == 3)
        } else {
            Issue.record("Expected Rect")
        }
    }

    @Test func `parses clipPath in defs`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <defs>
                    <clipPath id="clip1">
                        <circle cx="50" cy="50" r="40"/>
                    </clipPath>
                </defs>
            </svg>
            """)

        #expect(svg.definitions.clipPaths["clip1"] != nil)
        #expect(svg.definitions.clipPaths["clip1"]?.children.count == 1)
    }

    @Test func `parses nested groups`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <g id="outer">
                    <g id="inner">
                        <rect width="10" height="10"/>
                    </g>
                </g>
            </svg>
            """)

        if let outer = svg.children.first as? Group {
            #expect(outer.id == "outer")
            if let inner = outer.children.first as? Group {
                #expect(inner.id == "inner")
                #expect(inner.children.count == 1)
            } else {
                Issue.record("Expected inner Group")
            }
        } else {
            Issue.record("Expected outer Group")
        }
    }

    @Test func `parses polyline element`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <polyline points="0,0 10,10 20,0 30,10"/>
            </svg>
            """)

        if let polyline = svg.children.first as? Polyline {
            #expect(polyline.points.count == 4)
            #expect(polyline.points[0].x == 0)
            #expect(polyline.points[1].x == 10)
        } else {
            Issue.record("Expected Polyline")
        }
    }

    @Test func `parses polygon element`() throws {
        let parser = SVGParser()
        let svg = try parser.parse(string: """
            <svg>
                <polygon points="50,0 100,100 0,100"/>
            </svg>
            """)

        if let polygon = svg.children.first as? Polygon {
            #expect(polygon.points.count == 3)
        } else {
            Issue.record("Expected Polygon")
        }
    }
}
