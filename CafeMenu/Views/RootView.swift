import SwiftUI

struct RootView: View {
    @State private var session = CafeSession()
    @Namespace private var foodNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Image("slate-bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            GeometryReader { geo in
                HStack(spacing: 0) {
                    FoodCanvasView(namespace: foodNamespace)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(session.screen == .canvas)
                        .accessibilityHidden(session.screen != .canvas)

                    Group {
                        if let category = session.activeCategory {
                            CategoryDialView(category: category, namespace: foodNamespace)
                                .id(category.id)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .allowsHitTesting(session.screen == .dial)
                    .accessibilityHidden(session.screen != .dial)

                    CartView(namespace: foodNamespace)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(session.screen == .cart)
                        .accessibilityHidden(session.screen != .cart)
                }
                .offset(x: -CGFloat(session.stage) * geo.size.width)
                .animation(CafeMotion.curve(reduceMotion: reduceMotion), value: session.stage)
            }

            if session.screen == .ar {
                ARPlacementView(namespace: foodNamespace)
                    .transition(.opacity)
            }

            if let notice = session.notice {
                VStack {
                    CafeNoticeBanner(message: notice)
                        .padding(.top, 58)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(20)
            }
        }
        .environment(session)
        .preferredColorScheme(.dark)
        .animation(CafeMotion.curve(reduceMotion: reduceMotion), value: session.screen)
        .animation(CafeMotion.fade, value: session.notice)
        .sensoryFeedback(.impact(weight: .medium), trigger: session.screen)
        .onChange(of: session.screen) { _, screen in
            guard screen == .cart else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(560))
                session.flyingID = nil
            }
        }
    }
}
