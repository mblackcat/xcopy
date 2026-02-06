import Foundation
import AppKit

enum ClipboardItemType: String, Codable {
    case text
    case richText
    case image
    case fileURL
}

struct ClipboardItem: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let types: [ClipboardItemType]
    var textPreview: String?
    var blobFileName: String?
    var richTextBlobFileName: String?
    var sourceAppBundleID: String?
    var sourceAppName: String?
    var originalFileURL: String?

    var primaryType: ClipboardItemType {
        if types.contains(.image) { return .image }
        if types.contains(.fileURL) { return .fileURL }
        if types.contains(.richText) { return .richText }
        return .text
    }

    var displayText: String {
        if let text = textPreview, !text.isEmpty {
            return text
        }
        if types.contains(.image) {
            return "[Image]"
        }
        if let fileURL = originalFileURL {
            return fileURL
        }
        return "[Unknown]"
    }

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         types: [ClipboardItemType],
         textPreview: String? = nil,
         blobFileName: String? = nil,
         richTextBlobFileName: String? = nil,
         sourceAppBundleID: String? = nil,
         sourceAppName: String? = nil,
         originalFileURL: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.types = types
        self.textPreview = textPreview
        self.blobFileName = blobFileName
        self.richTextBlobFileName = richTextBlobFileName
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.originalFileURL = originalFileURL
    }
}
