import CoreGraphics
import Foundation

struct MenuItem: Identifiable, Hashable {
    let id: String
    let name: String
    let imageName: String
    let price: Decimal
    let cluster: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat

    /// Food only. The plated photo stays on `imageName` for the order.
    var listImageName: String { imageName + "-bare" }
}

struct MenuCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let imageName: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let items: [MenuItem]
}

enum MenuCatalog {
    static let designWidth: CGFloat = 390
    static let designHeight: CGFloat = 844

    static let chocolate = item("chocolate", "Chocolate Cakes", "chocolate-cake", "8.40", 0, 0, 0, 0)
    static let cocoa = item("cocoa", "Hot Chocolate", "hot-chocolate", "4.20", 0, 0, 0, 0)
    static let muffin = item("muffin", "Muffins", "muffin", "4.20", 0, 0, 0, 0)
    static let applePie = item("pie", "Apple Pie", "apple-pie", "6.80", 0, 0, 0, 0)

    static let pastries = MenuCategory(
        id: "pastries",
        name: "Pastries",
        imageName: "apple-pie",
        x: 18,
        y: 300,
        size: 168,
        items: [
            muffin,
            applePie,
            item("pancakes", "Banana Pancakes", "banana-pancakes", "7.20", 0, 0, 0, 0),
            item("croissant", "Croissant", "croissant", "5.40", 0, 0, 0, 0)
        ]
    )

    static let coffees = MenuCategory(
        id: "coffees",
        name: "Coffees",
        imageName: "latte",
        x: 196,
        y: 96,
        size: 156,
        items: [
            item("espresso", "Espresso", "espresso", "3.50", 0, 0, 0, 0),
            item("latte", "Latte", "latte", "4.80", 0, 0, 0, 0),
            item("cappuccino", "Cappuccino", "cappuccino", "4.60", 0, 0, 0, 0),
            cocoa
        ]
    )

    static let cakes = MenuCategory(
        id: "cakes",
        name: "Cakes",
        imageName: "chocolate-cake",
        x: 150,
        y: 530,
        size: 172,
        items: [
            chocolate,
            item("cheesecake", "Cheesecake", "cheesecake", "7.50", 0, 0, 0, 0),
            item("velvet", "Red Velvet", "red-velvet", "7.80", 0, 0, 0, 0)
        ]
    )

    static let categories: [MenuCategory] = [coffees, pastries, cakes]

    static var allItems: [MenuItem] {
        categories.flatMap(\.items)
    }

    static func item(_ id: String) -> MenuItem? {
        allItems.first { $0.id == id }
    }

    private static func item(
        _ id: String,
        _ name: String,
        _ imageName: String,
        _ price: String,
        _ cluster: Int,
        _ x: CGFloat,
        _ y: CGFloat,
        _ size: CGFloat
    ) -> MenuItem {
        MenuItem(
            id: id,
            name: name,
            imageName: imageName,
            price: Decimal(string: price) ?? 0,
            cluster: cluster,
            x: x,
            y: y,
            size: size
        )
    }
}

extension MenuItem {
    var detail: String {
        switch id {
        case "chocolate":
            return "A rich dark chocolate cake with a soft crumb and a cocoa finish."
        case "cheesecake":
            return "Baked cheesecake on a biscuit base, topped with a fresh berry."
        case "velvet":
            return "Red velvet sponge layered with smooth cream-cheese frosting."
        case "muffin":
            return "A small butter muffin with a soft swirl of frosting."
        case "pie":
            return "Lattice apple pie with a golden crust and warm spiced filling."
        case "pancakes":
            return "A berry pancake bowl finished with granola and fresh fruit."
        case "croissant":
            return "A flaky butter croissant, baked until the edges turn golden."
        case "espresso":
            return "A short, dark espresso with a thick layer of crema."
        case "latte":
            return "Espresso stretched with steamed milk and a light foam top."
        case "cappuccino":
            return "Espresso under thick foam, dusted with a little cocoa."
        case "cocoa":
            return "Hot chocolate with marshmallows and a cinnamon stick."
        default:
            return "Made fresh in the cafe kitchen."
        }
    }
}
