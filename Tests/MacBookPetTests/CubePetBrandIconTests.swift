import AppKit
import XCTest
@testable import MacBookPet

final class CubePetBrandIconTests: XCTestCase {
    func testPreparedStatusImageUsesMenuBarTemplateSizing() {
        let source = NSImage(size: NSSize(width: 72, height: 72))
        let image = CubePetBrandIcon.preparedStatusImage(from: source)

        XCTAssertEqual(image.size, NSSize(width: 18, height: 18))
        XCTAssertTrue(image.isTemplate)
        XCTAssertEqual(image.accessibilityDescription, "CubePet")
    }
}
