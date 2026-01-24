import Foundation

/// The font-weight attribute value
enum FontWeight: Hashable, Sendable {
    case normal
    case bold
    case bolder
    case lighter
    case numeric(Int)

    static let w100 = FontWeight.numeric(100)
    static let w200 = FontWeight.numeric(200)
    static let w300 = FontWeight.numeric(300)
    static let w400 = FontWeight.numeric(400)
    static let w500 = FontWeight.numeric(500)
    static let w600 = FontWeight.numeric(600)
    static let w700 = FontWeight.numeric(700)
    static let w800 = FontWeight.numeric(800)
    static let w900 = FontWeight.numeric(900)
}
