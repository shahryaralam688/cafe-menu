import SwiftUI

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.cafeInk)
                .frame(width: 44, height: 44)
                .background(Color.white, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("back-button")
        .accessibilityLabel("Back")
    }
}

struct BasketButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "basket")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.4), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("basket-button")
        .accessibilityLabel("Cart")
    }
}
