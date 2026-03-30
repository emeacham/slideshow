import XCTest
@testable import SlideshowCore

final class TransitionTypeTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(TransitionType.allCases.count, 4)
    }

    func testAllCasesPresent() {
        let cases = TransitionType.allCases
        XCTAssertTrue(cases.contains(.none))
        XCTAssertTrue(cases.contains(.fade))
        XCTAssertTrue(cases.contains(.slide))
        XCTAssertTrue(cases.contains(.zoom))
    }

    func testIdentifiable() {
        XCTAssertEqual(TransitionType.none.id,  "None")
        XCTAssertEqual(TransitionType.fade.id,  "Fade")
        XCTAssertEqual(TransitionType.slide.id, "Slide")
        XCTAssertEqual(TransitionType.zoom.id,  "Zoom")
    }

    func testDisplayName() {
        for type in TransitionType.allCases {
            XCTAssertEqual(type.displayName, type.rawValue)
        }
    }

    func testCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in TransitionType.allCases {
            let data = try encoder.encode(type)
            let decoded = try decoder.decode(TransitionType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    func testEquatable() {
        XCTAssertEqual(TransitionType.fade, TransitionType.fade)
        XCTAssertNotEqual(TransitionType.fade, TransitionType.slide)
    }
}
