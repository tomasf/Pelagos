import Foundation

/// An SVG filter element (stores raw filter primitives for now)
struct Filter: SVGElement, Hashable, Sendable {
    var id: String?

    var x: Length?
    var y: Length?
    var width: Length?
    var height: Length?
    var filterUnits: GradientUnits?
    var primitiveUnits: GradientUnits?

    /// Raw filter primitive elements (feGaussianBlur, feColorMatrix, etc.)
    var primitives: [FilterPrimitive]

    init(
        id: String? = nil,
        x: Length? = nil,
        y: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        filterUnits: GradientUnits? = nil,
        primitiveUnits: GradientUnits? = nil,
        primitives: [FilterPrimitive] = []
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.filterUnits = filterUnits
        self.primitiveUnits = primitiveUnits
        self.primitives = primitives
    }
}

/// A filter primitive element
enum FilterPrimitive: Hashable, Sendable {
    case gaussianBlur(input: String?, stdDeviation: Double, result: String?)
    case colorMatrix(input: String?, type: ColorMatrixType, values: [Double]?, result: String?)
    case offset(input: String?, dx: Double?, dy: Double?, result: String?)
    case blend(input: String?, input2: String?, mode: BlendMode?, result: String?)
    case composite(input: String?, input2: String?, operator_: CompositeOperator?, result: String?)
    case flood(floodColor: Color?, floodOpacity: Double?, result: String?)
    case merge(inputs: [String], result: String?)
    case morphology(input: String?, operator_: MorphologyOperator?, radius: Double?, result: String?)
    case turbulence(baseFrequency: Double?, numOctaves: Int?, seed: Int?, type: TurbulenceType?, result: String?)
    case unknown(name: String, attributes: [String: String])
}

enum ColorMatrixType: String, Hashable, Sendable {
    case matrix
    case saturate
    case hueRotate
    case luminanceToAlpha
}

enum BlendMode: String, Hashable, Sendable {
    case normal
    case multiply
    case screen
    case overlay
    case darken
    case lighten
    case colorDodge = "color-dodge"
    case colorBurn = "color-burn"
    case hardLight = "hard-light"
    case softLight = "soft-light"
    case difference
    case exclusion
    case hue
    case saturation
    case color
    case luminosity
}

enum CompositeOperator: String, Hashable, Sendable {
    case over
    case `in`
    case out
    case atop
    case xor
    case lighter
    case arithmetic
}

enum MorphologyOperator: String, Hashable, Sendable {
    case erode
    case dilate
}

enum TurbulenceType: String, Hashable, Sendable {
    case fractalNoise
    case turbulence
}
