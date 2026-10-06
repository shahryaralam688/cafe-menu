import SwiftUI

struct CartView: View {
    var namespace: Namespace.ID

    @Environment(CafeSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        DialBoard(
            title: "Your Cart Items",
            items: session.cart,
            plated: true,
            namespace: namespace,
            focusID: session.flyingID ?? session.selected?.id,
            accessibilityID: "cart-screen"
        ) { item in
            session.selected = item
            withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                session.show(.ar)
            }
        } footer: {
            VStack(spacing: 6) {
                Text("Grand Total")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
                Text(CafeFormat.usd(session.total))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.cafeAccent)
                    .accessibilityIdentifier("price-label")
                payButton
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var payButton: some View {
        Button {
            withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                _ = session.pay()
            }
        } label: {
            HStack {
                Text(session.paid ? "Paid" : "Make Payment")
                    .font(.headline)
                Spacer()
                Image(systemName: session.paid ? "checkmark" : "chevron.right.2")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(Color.cafeInk, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(session.paid)
        .accessibilityIdentifier(session.paid ? "paid-label" : "pay-button")
    }
}
