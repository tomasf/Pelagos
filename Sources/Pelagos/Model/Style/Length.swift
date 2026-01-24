import Foundation

/// A length value with an optional unit
public struct Length: Hashable, Sendable {
    public enum Unit: String, Hashable, Sendable {
        case none = ""
        case px
        case em
        case ex
        case pt
        case pc
        case cm
        case mm
        case `in`
        case percent = "%"
    }

    public var value: Double
    public var unit: Unit

    public init(_ value: Double, _ unit: Unit = .none) {
        self.value = value
        self.unit = unit
    }

    public static let zero = Length(0)

    public static func px(_ value: Double) -> Length { Length(value, .px) }
    public static func em(_ value: Double) -> Length { Length(value, .em) }
    public static func percent(_ value: Double) -> Length { Length(value, .percent) }
}
