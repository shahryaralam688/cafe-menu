import Foundation
import Observation

enum AppScreen: Equatable {
    case canvas
    case dial
    case ar
    case cart
}

@Observable
final class CafeSession {
    private(set) var stack: [AppScreen] = [.canvas]
    var activeCategory: MenuCategory?
    var selected: MenuItem?
    var flyingID: String?
    var cart: [MenuItem] = [MenuCatalog.chocolate, MenuCatalog.cocoa, MenuCatalog.muffin]
    var paid = false
    var notice: String?

    var screen: AppScreen { stack.last ?? .canvas }

    /// 0 categories, 1 dial, 2 cart. AR stays over the cart panel.
    var stage: Int {
        switch screen {
        case .canvas: 0
        case .dial: 1
        case .cart, .ar: 2
        }
    }

    var total: Decimal {
        cart.reduce(0) { $0 + $1.price }
    }

    @discardableResult
    func add(_ item: MenuItem) -> Bool {
        guard !cart.contains(where: { $0.id == item.id }) else { return false }
        cart.append(item)
        return true
    }

    func show(_ next: AppScreen) {
        if next == .canvas {
            stack = [.canvas]
            return
        }
        if stack.last == next { return }
        if let index = stack.lastIndex(of: next) {
            stack = Array(stack.prefix(through: index))
            return
        }
        stack.append(next)
    }

    func back() {
        guard stack.count > 1 else {
            flash("You are already on the menu")
            return
        }
        let leaving = stack.removeLast()
        if leaving == .cart {
            paid = false
        }
    }

    func flash(_ message: String) {
        notice = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            if notice == message {
                notice = nil
            }
        }
    }

    func pay() -> Bool {
        guard !cart.isEmpty else {
            flash("Your cart is empty")
            return false
        }
        guard !paid else {
            flash("Payment already completed")
            return false
        }
        paid = true
        return true
    }
}
