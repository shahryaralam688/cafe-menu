import XCTest

final class CafeMenuUITests: XCTestCase {
    func testCategoryDialCartAndPay() {
        let app = XCUIApplication()
        app.launch()

        let cakes = app.buttons["Cakes"]
        XCTAssertTrue(cakes.waitForExistence(timeout: 8))
        cakes.tap()

        let chocolate = app.images["Chocolate Cakes"]
        XCTAssertTrue(chocolate.waitForExistence(timeout: 5))

        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.32, dy: 0.42))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.58))
        start.press(forDuration: 0.05, thenDragTo: end)

        XCTAssertTrue(app.staticTexts["Red Velvet"].waitForExistence(timeout: 4))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.46)).tap()

        let added = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '24.60'")).firstMatch
        XCTAssertTrue(added.waitForExistence(timeout: 4))

        let back = app.buttons.matching(identifier: "back-button").allElementsBoundByIndex.first { $0.isHittable }
        XCTAssertNotNil(back)
        back?.tap()
        XCTAssertTrue(app.staticTexts["Cakes"].waitForExistence(timeout: 4))

        let cart = app.buttons.matching(identifier: "basket-button").allElementsBoundByIndex.first { $0.isHittable }
        XCTAssertNotNil(cart)
        cart?.tap()
        app.buttons["Make Payment"].tap()
        XCTAssertTrue(app.buttons["Paid"].waitForExistence(timeout: 4))
    }
}
