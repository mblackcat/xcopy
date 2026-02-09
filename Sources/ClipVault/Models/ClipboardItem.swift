import Foundation
import AppKit

enum ClipboardItemType: String, Codable {
    case text
    case richText
    case image
    case fileURL
}

struct ClipboardItem: Identifiable {
    let id: UUID
    let timestamp: Date
    let types: [ClipboardItemType]
    var textPreview: String?
    var blobFileName: String?
    var richTextBlobFileName: String?
    var sourceAppBundleID: String?
    var sourceAppName: String?
    var originalFileURLs: [String]?

    var primaryType: ClipboardItemType {
        if types.contains(.image) { return .image }
        if types.contains(.fileURL) { return .fileURL }
        if types.contains(.richText) { return .richText }
        return .text
    }

    var displayText: String {
        if let urls = originalFileURLs, !urls.isEmpty {
            if urls.count == 1 {
                return (urls[0] as NSString).lastPathComponent
            }
            return "\(urls.count) files: " + urls.map { ($0 as NSString).lastPathComponent }.joined(separator: ", ")
        }
        if let text = textPreview, !text.isEmpty {
            return text
        }
        if types.contains(.image) {
            return "[Image]"
        }
        return "[Unknown]"
    }

    /// Whether any stored file URL points to a directory
    var containsDirectory: Bool {
        guard let urls = originalFileURLs else { return false }
        return urls.contains { path in
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
        }
    }

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         types: [ClipboardItemType],
         textPreview: String? = nil,
         blobFileName: String? = nil,
         richTextBlobFileName: String? = nil,
         sourceAppBundleID: String? = nil,
         sourceAppName: String? = nil,
         originalFileURLs: [String]? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.types = types
        self.textPreview = textPreview
        self.blobFileName = blobFileName
        self.richTextBlobFileName = richTextBlobFileName
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.originalFileURLs = originalFileURLs
    }
}

// MARK: - Codable with backward compatibility

extension ClipboardItem: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, types, textPreview, blobFileName, richTextBlobFileName
        case sourceAppBundleID, sourceAppName
        case originalFileURLs
        case originalFileURL // legacy single-URL field
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        types = try c.decode([ClipboardItemType].self, forKey: .types)
        textPreview = try c.decodeIfPresent(String.self, forKey: .textPreview)
        blobFileName = try c.decodeIfPresent(String.self, forKey: .blobFileName)
        richTextBlobFileName = try c.decodeIfPresent(String.self, forKey: .richTextBlobFileName)
        sourceAppBundleID = try c.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
        sourceAppName = try c.decodeIfPresent(String.self, forKey: .sourceAppName)

        // Try new array field first, fall back to legacy single-URL field
        if let urls = try c.decodeIfPresent([String].self, forKey: .originalFileURLs) {
            originalFileURLs = urls
        } else if let url = try c.decodeIfPresent(String.self, forKey: .originalFileURL) {
            originalFileURLs = [url]
        } else {
            originalFileURLs = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encode(types, forKey: .types)
        try c.encodeIfPresent(textPreview, forKey: .textPreview)
        try c.encodeIfPresent(blobFileName, forKey: .blobFileName)
        try c.encodeIfPresent(richTextBlobFileName, forKey: .richTextBlobFileName)
        try c.encodeIfPresent(sourceAppBundleID, forKey: .sourceAppBundleID)
        try c.encodeIfPresent(sourceAppName, forKey: .sourceAppName)
        try c.encodeIfPresent(originalFileURLs, forKey: .originalFileURLs)
    }
}
