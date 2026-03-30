import XCTest
@testable import SlideshowCore

final class SlideshowControllerTests: XCTestCase {

    private func makeURLs(_ count: Int) -> [URL] {
        (1...count).map { URL(string: "file:///images/img\($0).jpg")! }
    }

    // MARK: - Initialization

    func testDefaultInit() {
        let c = SlideshowController()
        XCTAssertFalse(c.hasImages)
        XCTAssertEqual(c.totalCount, 0)
        XCTAssertEqual(c.currentIndex, 0)
        XCTAssertNil(c.currentImageURL)
        XCTAssertEqual(c.slideDelay, 3.0)
        XCTAssertEqual(c.transitionType, .fade)
    }

    func testInitWithImages() {
        let urls = makeURLs(5)
        let c = SlideshowController(imageURLs: urls)
        XCTAssertTrue(c.hasImages)
        XCTAssertEqual(c.totalCount, 5)
        XCTAssertEqual(c.currentIndex, 0)
        XCTAssertEqual(c.currentImageURL, urls[0])
    }

    func testInitClampsOutOfBoundsIndex() {
        let urls = makeURLs(3)
        let c = SlideshowController(imageURLs: urls, currentIndex: 99)
        XCTAssertEqual(c.currentIndex, 2)
    }

    // MARK: - advance()

    func testAdvanceMovesForward() {
        var c = SlideshowController(imageURLs: makeURLs(5))
        c.advance()
        XCTAssertEqual(c.currentIndex, 1)
    }

    func testAdvanceWrapsAroundAtEnd() {
        var c = SlideshowController(imageURLs: makeURLs(3), currentIndex: 2)
        c.advance()
        XCTAssertEqual(c.currentIndex, 0, "Should wrap to first image")
    }

    func testAdvanceOnSingleImage() {
        var c = SlideshowController(imageURLs: makeURLs(1))
        c.advance()
        XCTAssertEqual(c.currentIndex, 0, "Single image stays at 0")
    }

    func testAdvanceOnEmptyDoesNothing() {
        var c = SlideshowController()
        c.advance()
        XCTAssertEqual(c.currentIndex, 0)
    }

    // MARK: - goBack()

    func testGoBackMovesBackward() {
        var c = SlideshowController(imageURLs: makeURLs(5), currentIndex: 3)
        c.goBack()
        XCTAssertEqual(c.currentIndex, 2)
    }

    func testGoBackWrapsAroundAtStart() {
        var c = SlideshowController(imageURLs: makeURLs(4))
        c.goBack()
        XCTAssertEqual(c.currentIndex, 3, "Should wrap to last image")
    }

    func testGoBackOnEmptyDoesNothing() {
        var c = SlideshowController()
        c.goBack()
        XCTAssertEqual(c.currentIndex, 0)
    }

    // MARK: - goToIndex()

    func testGoToValidIndex() {
        var c = SlideshowController(imageURLs: makeURLs(5))
        c.goToIndex(4)
        XCTAssertEqual(c.currentIndex, 4)
    }

    func testGoToInvalidIndexDoesNothing() {
        var c = SlideshowController(imageURLs: makeURLs(5))
        c.goToIndex(10)
        XCTAssertEqual(c.currentIndex, 0, "Out-of-bounds index should be ignored")
    }

    func testGoToNegativeIndexDoesNothing() {
        var c = SlideshowController(imageURLs: makeURLs(5), currentIndex: 2)
        c.goToIndex(-1)
        XCTAssertEqual(c.currentIndex, 2, "Negative index should be ignored")
    }

    // MARK: - loadImages()

    func testLoadImagesResetsIndex() {
        var c = SlideshowController(imageURLs: makeURLs(5), currentIndex: 4)
        c.loadImages(makeURLs(3))
        XCTAssertEqual(c.currentIndex, 0)
        XCTAssertEqual(c.totalCount, 3)
    }

    func testLoadEmptyArrayClearsImages() {
        var c = SlideshowController(imageURLs: makeURLs(5))
        c.loadImages([])
        XCTAssertFalse(c.hasImages)
        XCTAssertNil(c.currentImageURL)
    }

    // MARK: - currentImageURL

    func testCurrentImageURLReturnsCorrectURL() {
        let urls = makeURLs(5)
        var c = SlideshowController(imageURLs: urls)
        c.goToIndex(3)
        XCTAssertEqual(c.currentImageURL, urls[3])
    }

    // MARK: - Round-trip navigation

    func testFullCircleAdvance() {
        let count = 4
        var c = SlideshowController(imageURLs: makeURLs(count))
        for _ in 0..<count { c.advance() }
        XCTAssertEqual(c.currentIndex, 0, "Full circle should return to start")
    }

    func testFullCircleGoBack() {
        let count = 4
        var c = SlideshowController(imageURLs: makeURLs(count))
        for _ in 0..<count { c.goBack() }
        XCTAssertEqual(c.currentIndex, 0, "Full reverse circle should return to start")
    }
}
