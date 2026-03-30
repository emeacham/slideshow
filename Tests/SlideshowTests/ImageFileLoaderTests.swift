import XCTest
@testable import SlideshowCore

final class ImageFileLoaderTests: XCTestCase {

    // MARK: - supportedExtensions

    func testSupportedExtensionsContainsCommonFormats() {
        let ext = ImageFileLoader.supportedExtensions
        XCTAssertTrue(ext.contains("jpg"))
        XCTAssertTrue(ext.contains("jpeg"))
        XCTAssertTrue(ext.contains("png"))
        XCTAssertTrue(ext.contains("gif"))
        XCTAssertTrue(ext.contains("bmp"))
        XCTAssertTrue(ext.contains("tiff"))
        XCTAssertTrue(ext.contains("tif"))
        XCTAssertTrue(ext.contains("heic"))
        XCTAssertTrue(ext.contains("heif"))
        XCTAssertTrue(ext.contains("webp"))
    }

    func testUnsupportedExtensionsExcluded() {
        let ext = ImageFileLoader.supportedExtensions
        XCTAssertFalse(ext.contains("mp4"))
        XCTAssertFalse(ext.contains("txt"))
        XCTAssertFalse(ext.contains("pdf"))
        XCTAssertFalse(ext.contains("mov"))
    }

    // MARK: - loadImages(from:)

    func testLoadImagesFiltersToSupportedFormats() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let files = ["photo.jpg", "image.PNG", "clip.mp4", "notes.txt", "art.heic"]
        try files.forEach { try Data().write(to: dir.appendingPathComponent($0)) }

        let urls = try ImageFileLoader.loadImages(from: dir)
        let names = Set(urls.map { $0.lastPathComponent })

        XCTAssertTrue(names.contains("photo.jpg"))
        XCTAssertTrue(names.contains("image.PNG"))
        XCTAssertTrue(names.contains("art.heic"))
        XCTAssertFalse(names.contains("clip.mp4"))
        XCTAssertFalse(names.contains("notes.txt"))
    }

    func testLoadImagesReturnsSortedByFilename() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let files = ["zebra.jpg", "apple.jpg", "mango.png", "banana.gif"]
        try files.forEach { try Data().write(to: dir.appendingPathComponent($0)) }

        let urls = try ImageFileLoader.loadImages(from: dir)
        let names = urls.map { $0.lastPathComponent }

        XCTAssertEqual(names, ["apple.jpg", "banana.gif", "mango.png", "zebra.jpg"])
    }

    func testLoadImagesReturnsEmptyForEmptyDirectory() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let urls = try ImageFileLoader.loadImages(from: dir)
        XCTAssertTrue(urls.isEmpty)
    }

    func testLoadImagesThrowsForNonexistentDirectory() {
        let fake = URL(fileURLWithPath: "/nonexistent/path/\(UUID().uuidString)")
        XCTAssertThrowsError(try ImageFileLoader.loadImages(from: fake))
    }

    func testLoadImagesSkipsHiddenFiles() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        try Data().write(to: dir.appendingPathComponent("visible.jpg"))
        try Data().write(to: dir.appendingPathComponent(".hidden.jpg"))

        let urls = try ImageFileLoader.loadImages(from: dir)
        let names = urls.map { $0.lastPathComponent }

        XCTAssertTrue(names.contains("visible.jpg"))
        XCTAssertFalse(names.contains(".hidden.jpg"))
    }

    func testLoadImagesIsCaseInsensitiveForExtensions() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let files = ["A.JPG", "b.Png", "c.TIFF", "d.jpeg"]
        try files.forEach { try Data().write(to: dir.appendingPathComponent($0)) }

        let urls = try ImageFileLoader.loadImages(from: dir)
        XCTAssertEqual(urls.count, 4)
    }

    // MARK: - Helpers

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
