import Testing
@testable import Pelagos

@Suite("Pelagos Tests")
struct PelagosTests {
    @Test func versionExists() {
        #expect(!Pelagos.version.isEmpty)
    }
}

@Suite("Length Parsing")
struct LengthParsingTests {
    @Test func parsesNumbers() {
        let length = AttributeParser.parseLength("42")
        #expect(length?.value == 42)
        #expect(length?.unit == Length.Unit.none)
    }

    @Test func parsesPixels() {
        let length = AttributeParser.parseLength("100px")
        #expect(length?.value == 100)
        #expect(length?.unit == .px)
    }

    @Test func parsesPercent() {
        let length = AttributeParser.parseLength("50%")
        #expect(length?.value == 50)
        #expect(length?.unit == .percent)
    }

    @Test func parsesEm() {
        let length = AttributeParser.parseLength("1.5em")
        #expect(length?.value == 1.5)
        #expect(length?.unit == .em)
    }
}

@Suite("Color Parsing")
struct ColorParsingTests {
    @Test func parsesNone() {
        let color = AttributeParser.parseColor("none")
        #expect(color == Color.none)
    }

    @Test func parsesCurrentColor() {
        let color = AttributeParser.parseColor("currentColor")
        #expect(color == .currentColor)
    }

    @Test func parsesHex3() {
        let color = AttributeParser.parseColor("#f00")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 255)
            #expect(g == 0)
            #expect(b == 0)
        } else {
            Issue.record("Expected RGB color")
        }
    }

    @Test func parsesHex6() {
        let color = AttributeParser.parseColor("#00ff00")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 0)
            #expect(g == 255)
            #expect(b == 0)
        } else {
            Issue.record("Expected RGB color")
        }
    }

    @Test func parsesNamedColor() {
        let color = AttributeParser.parseColor("red")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 255)
            #expect(g == 0)
            #expect(b == 0)
        } else {
            Issue.record("Expected RGB color")
        }
    }

    @Test func parsesRgbFunction() {
        let color = AttributeParser.parseColor("rgb(128, 64, 32)")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 128)
            #expect(g == 64)
            #expect(b == 32)
        } else {
            Issue.record("Expected RGB color")
        }
    }
}

@Suite("Transform Parsing")
struct TransformParsingTests {
    @Test func parsesTranslate() {
        let transforms = AttributeParser.parseTransform("translate(10, 20)")
        #expect(transforms?.count == 1)
        if case .translate(let x, let y) = transforms?.first {
            #expect(x == 10)
            #expect(y == 20)
        } else {
            Issue.record("Expected translate transform")
        }
    }

    @Test func parsesScale() {
        let transforms = AttributeParser.parseTransform("scale(2)")
        #expect(transforms?.count == 1)
        if case .scale(let x, let y) = transforms?.first {
            #expect(x == 2)
            #expect(y == 2)
        } else {
            Issue.record("Expected scale transform")
        }
    }

    @Test func parsesRotate() {
        let transforms = AttributeParser.parseTransform("rotate(45)")
        #expect(transforms?.count == 1)
        if case .rotate(let angle, let cx, let cy) = transforms?.first {
            #expect(angle == 45)
            #expect(cx == nil)
            #expect(cy == nil)
        } else {
            Issue.record("Expected rotate transform")
        }
    }

    @Test func parsesMultipleTransforms() {
        let transforms = AttributeParser.parseTransform("translate(10, 20) rotate(45) scale(2, 3)")
        #expect(transforms?.count == 3)
    }
}

@Suite("Path Parsing")
struct PathParsingTests {
    @Test func parsesMoveTo() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 10 20")
        #expect(segments.count == 1)
        if case .moveTo(let point) = segments.first {
            #expect(point.x == 10)
            #expect(point.y == 20)
        } else {
            Issue.record("Expected moveTo")
        }
    }

    @Test func parsesLineTo() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 L 100 200")
        #expect(segments.count == 2)
        if case .lineTo(let point) = segments[1] {
            #expect(point.x == 100)
            #expect(point.y == 200)
        } else {
            Issue.record("Expected lineTo")
        }
    }

    @Test func parsesCurveTo() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 C 10 20 30 40 50 60")
        #expect(segments.count == 2)
        if case .curveTo(let c1, let c2, let end) = segments[1] {
            #expect(c1.x == 10)
            #expect(c1.y == 20)
            #expect(c2.x == 30)
            #expect(c2.y == 40)
            #expect(end.x == 50)
            #expect(end.y == 60)
        } else {
            Issue.record("Expected curveTo")
        }
    }

    @Test func parsesArc() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 A 5 5 0 0 1 10 10")
        #expect(segments.count == 2)
        if case .arcTo(let rx, let ry, let xRot, let large, let sweep, let end) = segments[1] {
            #expect(rx == 5)
            #expect(ry == 5)
            #expect(xRot == 0)
            #expect(large == false)
            #expect(sweep == true)
            #expect(end.x == 10)
            #expect(end.y == 10)
        } else {
            Issue.record("Expected arcTo")
        }
    }

    @Test func parsesClosePath() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 L 10 10 Z")
        #expect(segments.count == 3)
        if case .closePath = segments[2] {
            // Success
        } else {
            Issue.record("Expected closePath")
        }
    }
}

@Suite("SVG Parsing")
struct SVGParsingTests {
    @Test func parsesSimpleSVG() throws {
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

    @Test func parsesShapes() throws {
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

    @Test func parsesGroups() throws {
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

    @Test func parsesGradients() throws {
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
        } else {
            Issue.record("Expected LinearGradient")
        }
    }

    @Test func parsesUseElement() throws {
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
        } else {
            Issue.record("Expected Use")
        }
    }

    @Test func parsesPath() throws {
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

    @Test func parsesText() throws {
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
            }
        } else {
            Issue.record("Expected Text")
        }
    }
}
