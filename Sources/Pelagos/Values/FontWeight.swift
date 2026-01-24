import Foundation

/// The font-weight attribute value
public enum FontWeight: Hashable, Sendable {
    case normal
    case bold
    case bolder
    case lighter
    case numeric(Int)

    public static let w100 = FontWeight.numeric(100)
    public static let w200 = FontWeight.numeric(200)
    public static let w300 = FontWeight.numeric(300)
    public static let w400 = FontWeight.numeric(400)
    public static let w500 = FontWeight.numeric(500)
    public static let w600 = FontWeight.numeric(600)
    public static let w700 = FontWeight.numeric(700)
    public static let w800 = FontWeight.numeric(800)
    public static let w900 = FontWeight.numeric(900)
}
