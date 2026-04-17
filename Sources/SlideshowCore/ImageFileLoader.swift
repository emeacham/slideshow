// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import Foundation

public struct ImageFileLoader {

    public static let videoExtensions: Set<String> = ["webm"]

    public static let supportedExtensions: Set<String> = Set([
        "jpg", "jpeg", "png", "gif", "bmp",
        "tiff", "tif", "heic", "heif", "webp",
    ]).union(videoExtensions)

    public static func loadImages(from directory: URL) throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        return contents
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
}
