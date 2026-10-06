import SwiftUI

struct FoodPhoto: View {
    let item: MenuItem
    var diameter: CGFloat
    var namespace: Namespace.ID

    var body: some View {
        Image(item.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
            .matchedGeometryEffect(id: item.id, in: namespace)
            .accessibilityIdentifier("food-\(item.id)")
            .accessibilityLabel(item.name)
    }
}

struct FoodOrb: View {
    let item: MenuItem
    var diameter: CGFloat
    var namespace: Namespace.ID
    var floats: Bool
    var delay: Double

    var body: some View {
        FoodPhoto(item: item, diameter: diameter, namespace: namespace)
            .overlay(alignment: .bottom) {
                Text(item.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.55), in: Capsule())
                    .offset(y: 14)
                    .accessibilityHidden(true)
            }
            .modifier(IdleFloat(enabled: floats, delay: delay))
    }
}
