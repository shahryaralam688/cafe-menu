import SwiftUI

extension Color {
    static let cafeInk = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
    static let cafeAccent = Color(red: 0xF3 / 255, green: 0xA8 / 255, blue: 0xC0 / 255)
    static let cafeStroke = Color(red: 1, green: 0.28, blue: 0.55)
    static let cafeAvatar = Color(red: 0.79, green: 0.64, blue: 0.48)
}

enum CafeFormat {
    static func usd(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}
