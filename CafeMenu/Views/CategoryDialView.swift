import SwiftUI
import UIKit

struct CategoryDialView: View {
    let category: MenuCategory
    var namespace: Namespace.ID

    @Environment(CafeSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        DialBoard(
            title: category.name,
            items: category.items,
            plated: false,
            namespace: namespace,
            focusID: nil,
            accessibilityID: "dial-screen"
        ) { item in
            session.selected = item
            if session.add(item) {
                session.paid = false
                session.flyingID = item.id
                withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                    session.show(.cart)
                }
            } else {
                session.flash("Already in your cart")
            }
        } footer: {
            EmptyView()
        }
    }
}

struct DialBoard<Footer: View>: View {
    let title: String
    let items: [MenuItem]
    var plated: Bool
    var namespace: Namespace.ID
    var focusID: String?
    var accessibilityID: String
    var onFocusedTap: (MenuItem) -> Void
    @ViewBuilder var footer: () -> Footer

    @Environment(CafeSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dialBase: CGFloat = 0
    @State private var dialDrag: CGFloat = 0
    @State private var dragStartAngle: CGFloat?
    @State private var lastDragTime = Date()
    @State private var velocity: CGFloat = 0
    @State private var hub = CGPoint.zero

    private var position: CGFloat { dialBase + dialDrag }

    var body: some View {
        GeometryReader { geo in
            let layout = DialLayout(size: geo.size, liftsHub: plated)
            ZStack {
                if items.isEmpty {
                    Text("Nothing selected yet")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let delta = wrappedDelta(index: index, count: items.count)
                        dialItem(item, delta: delta, layout: layout)
                    }
                    if let selected = focusedItem(),
                       let index = items.firstIndex(where: { $0.id == selected.id }) {
                        let delta = wrappedDelta(index: index, count: items.count)
                        let point = layout.point(delta: delta)
                        let scale = 0.58 + max(0, 1 - abs(delta)) * 0.92
                        selectionCopy(selected, at: point, diameter: layout.itemDiameter * scale, in: layout)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .contentShape(Rectangle())
            .highPriorityGesture(dialGesture(layout: layout))
            .overlay(alignment: .top) { chrome }
            .overlay(alignment: .bottom) {
                footer()
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(accessibilityID)
            .onAppear { hub = layout.hub }
            .onChange(of: geo.size) { _, _ in hub = layout.hub }
        }
        .sensoryFeedback(.selection, trigger: Int(dialBase.rounded()))
        .onChange(of: focusID) { _, id in
            snap(to: id)
        }
        .onAppear { snap(to: focusID) }
    }

    private var chrome: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BackButton {
                    withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                        session.back()
                    }
                }
                Spacer()
                if plated {
                    Circle()
                        .fill(Color.cafeAvatar)
                        .frame(width: 36, height: 36)
                        .accessibilityHidden(true)
                } else {
                    BasketButton {
                        withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                            session.paid = false
                            session.show(.cart)
                        }
                    }
                }
            }
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.leading, 6)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func dialItem(_ item: MenuItem, delta: CGFloat, layout: DialLayout) -> some View {
        let point = layout.point(delta: delta)
        let focused = abs(delta) < 0.34
        let closeness = max(0, 1 - abs(delta))
        let scale = 0.58 + closeness * 0.92
        let diameter = layout.itemDiameter * scale
        // Path travel + self spin while scrolling.
        let orbitSpin = reduceMotion ? Angle.zero : .degrees(Double(position) * 72)
        let selfSpin = reduceMotion ? Angle.zero : .degrees(Double(delta) * 110)
        let flying = session.flyingID == item.id
        let isSource = plated ? session.screen != .dial : session.screen == .dial

        return PlatedFoodImage(item: item, plated: plated)
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .rotationEffect(orbitSpin + selfSpin)
            .shadow(color: .black.opacity(focused ? 0.52 : 0.28), radius: focused ? 22 : 8, y: 8)
            .modifier(FlyMatch(active: flying, id: item.id, namespace: namespace, isSource: isSource))
            .accessibilityLabel(item.name)
            .position(point)
            .animation(CafeMotion.dialTrack(reduceMotion: reduceMotion), value: position)
    }

    private func selectionCopy(_ item: MenuItem, at point: CGPoint, diameter: CGFloat, in layout: DialLayout) -> some View {
        let x = min(point.x + diameter * 0.52 + 86, layout.size.width - 72)
        return VStack(alignment: .leading, spacing: 5) {
            Text(item.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(item.detail)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
            Text(CafeFormat.usd(item.price))
                .font(.headline)
                .foregroundStyle(Color.cafeAccent)
        }
        .frame(width: 152, alignment: .leading)
        .shadow(color: .black.opacity(0.55), radius: 6, y: 2)
        .position(x: x, y: point.y)
        .id(item.id)
        .transition(.opacity)
        .animation(CafeMotion.fade, value: item.id)
        .allowsHitTesting(false)
    }

    private func dialGesture(layout: DialLayout) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard items.count > 1 else { return }
                let now = Date()
                let location = value.location
                let start = value.startLocation

                if dragStartAngle == nil {
                    // Ignore tiny moves so taps still work.
                    let travel = hypot(value.translation.width, value.translation.height)
                    guard travel > 10 else { return }
                    dragStartAngle = angle(from: layout.hub, to: start)
                    lastDragTime = now
                    velocity = 0
                }

                guard let startAngle = dragStartAngle else { return }
                let currentAngle = angle(from: layout.hub, to: location)
                let step = DialLayout.radiansPerItem
                var deltaAngle = currentAngle - startAngle
                if deltaAngle > .pi { deltaAngle -= 2 * .pi }
                if deltaAngle < -.pi { deltaAngle += 2 * .pi }

                let nextDrag = deltaAngle / step
                let dt = max(now.timeIntervalSince(lastDragTime), 0.001)
                velocity = (nextDrag - dialDrag) / CGFloat(dt)
                lastDragTime = now
                dialDrag = nextDrag
            }
            .onEnded { value in
                let travel = hypot(value.translation.width, value.translation.height)
                if dragStartAngle != nil {
                    let projected = dialBase + dialDrag + velocity * 0.18
                    let snapped = projected.rounded()
                    withAnimation(CafeMotion.dialSnap(reduceMotion: reduceMotion)) {
                        dialBase = snapped
                        dialDrag = 0
                    }
                } else if travel < 12, let item = focusedItem() {
                    onFocusedTap(item)
                } else {
                    dialDrag = 0
                }
                dragStartAngle = nil
                velocity = 0
            }
    }

    private func angle(from hub: CGPoint, to point: CGPoint) -> CGFloat {
        atan2(point.y - hub.y, point.x - hub.x)
    }

    private func focusedItem() -> MenuItem? {
        guard !items.isEmpty else { return nil }
        return items.enumerated().min { lhs, rhs in
            abs(wrappedDelta(index: lhs.offset, count: items.count))
                < abs(wrappedDelta(index: rhs.offset, count: items.count))
        }?.element
    }

    private func wrappedDelta(index: Int, count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        let span = CGFloat(count)
        var delta = CGFloat(index) - position
        delta = delta.truncatingRemainder(dividingBy: span)
        if delta > span / 2 { delta -= span }
        if delta <= -span / 2 { delta += span }
        return delta
    }

    private func snap(to id: String?) {
        guard let id, let index = items.firstIndex(where: { $0.id == id }) else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dialBase = CGFloat(index)
            dialDrag = 0
        }
    }
}

struct PlatedFoodImage: View {
    let item: MenuItem
    var plated: Bool

    var body: some View {
        let name = plated ? item.imageName : item.listImageName
        if UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
        } else if UIImage(named: item.imageName) != nil {
            Image(item.imageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle().fill(Color.white.opacity(0.12))
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityLabel("Image missing for \(item.name)")
        }
    }
}

private struct FlyMatch: ViewModifier {
    var active: Bool
    var id: String
    var namespace: Namespace.ID
    var isSource: Bool

    func body(content: Content) -> some View {
        if active {
            content.matchedGeometryEffect(id: "fly-\(id)", in: namespace, isSource: isSource)
        } else {
            content
        }
    }
}

private struct DialLayout {
    let size: CGSize
    var liftsHub = false

    static let radiansPerItem: CGFloat = 2 * .pi / 4.5

    var itemDiameter: CGFloat { min(136, size.width * 0.34) }

    var hub: CGPoint {
        CGPoint(x: size.width - itemDiameter * 0.15, y: size.height * (liftsHub ? 0.42 : 0.52))
    }

    var radius: CGFloat {
        let backFullyHidden = size.width - hub.x + itemDiameter * 0.72
        let frontFullyVisible = hub.x - itemDiameter * 0.82 - 18
        let preferred = size.height * (liftsHub ? 0.26 : 0.31)
        return min(max(preferred, backFullyHidden), max(frontFullyVisible, backFullyHidden))
    }

    func point(delta: CGFloat) -> CGPoint {
        let radians = .pi + delta * Self.radiansPerItem
        return CGPoint(
            x: hub.x + CGFloat(cos(radians)) * radius,
            y: hub.y + CGFloat(sin(radians)) * radius
        )
    }
}
