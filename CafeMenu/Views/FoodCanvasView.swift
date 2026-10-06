import SwiftUI
import UIKit

struct FoodCanvasView: View {
    var namespace: Namespace.ID

    @Environment(CafeSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(Array(MenuCatalog.categories.enumerated()), id: \.element.id) { index, category in
                    categoryButton(category, in: geo.size)
                        .position(center(of: category, in: geo.size))
                        .modifier(IdleFloat(enabled: !reduceMotion, delay: Double(index) * 0.18))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .overlay(alignment: .top) { chrome }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("canvas-screen")
        }
    }

    private var chrome: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                BasketButton {
                    withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                        session.paid = false
                        session.show(.cart)
                    }
                }
            }
            Text("Cafe")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Pick a category, then spin the dial.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func categoryButton(_ category: MenuCategory, in size: CGSize) -> some View {
        let scale = min(size.width / MenuCatalog.designWidth, size.height / MenuCatalog.designHeight)
        let diameter = category.size * scale
        return Button {
            session.activeCategory = category
            withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                session.show(.dial)
            }
        } label: {
            Group {
                if UIImage(named: category.imageName + "-bare") != nil {
                    Image(category.imageName + "-bare")
                        .resizable()
                        .scaledToFill()
                } else if UIImage(named: category.imageName) != nil {
                    Image(category.imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.12))
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
            .overlay(alignment: .bottom) {
                Text(category.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.55), in: Capsule())
                    .offset(y: 16)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityIdentifier("category-\(category.id)")
    }

    private func center(of category: MenuCategory, in size: CGSize) -> CGPoint {
        let scale = min(size.width / MenuCatalog.designWidth, size.height / MenuCatalog.designHeight)
        let xInset = (size.width - MenuCatalog.designWidth * scale) / 2
        let yInset = (size.height - MenuCatalog.designHeight * scale) / 2
        return CGPoint(
            x: xInset + (category.x + category.size / 2) * scale,
            y: yInset + (category.y + category.size / 2) * scale
        )
    }
}
