import SwiftUI

enum CafeMotion {
    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.84)
    static let fade = Animation.easeInOut(duration: 0.22)
    static let dialInteractive = Animation.interactiveSpring(response: 0.28, dampingFraction: 0.86, blendDuration: 0.12)
    static let dialSettle = Animation.spring(response: 0.52, dampingFraction: 0.82)

    static func curve(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : spring
    }

    static func dialTrack(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : dialInteractive
    }

    static func dialSnap(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : dialSettle
    }
}

struct IdleFloat: ViewModifier {
    var enabled: Bool
    var delay: Double
    @State private var raised = false

    func body(content: Content) -> some View {
        content
            .offset(y: enabled && raised ? -6 : 0)
            .onAppear {
                guard enabled else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                        raised = true
                    }
                }
            }
    }
}

struct CafeNoticeBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.cafeInk.opacity(0.92), in: Capsule())
            .overlay(Capsule().stroke(Color.cafeAccent.opacity(0.55), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
            .accessibilityIdentifier("notice-banner")
            .accessibilityLabel(message)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
