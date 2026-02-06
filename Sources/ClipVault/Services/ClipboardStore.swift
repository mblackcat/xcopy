import Foundation
import AppKit
import Combine

class ClipboardStore: ObservableObject {
    @Published var items: [ClipboardItem] = []
    var maxRecords: Int
    var isInternalWrite = false

    private let storageURL: URL
    private let blobsURL: URL
    private let indexURL: URL
    private let fileManager = FileManager.default

    init(maxRecords: Int) {
        self.maxRecords = maxRecords

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        storageURL = appSupport.appendingPathComponent(Constants.storageDirectoryName)
        blobsURL = storageURL.appendingPathComponent(Constants.blobsDirectoryName)
        indexURL = storageURL.appendingPathComponent(Constants.indexFileName)

        try? fileManager.createDirectory(at: blobsURL, withIntermediateDirectories: true)
        loadIndex()
    }

    func addItem(from pasteboard: NSPasteboard) {
        let types = pasteboard.types ?? []
        var itemTypes: [ClipboardItemType] = []
        var textPreview: String?
        var blobFileName: String?
        var richTextBlobFileName: String?
        var originalFileURL: String?

        let frontApp = NSWorkspace.shared.frontmostApplication
        let sourceAppBundleID = frontApp?.bundleIdentifier
        let sourceAppName = frontApp?.localizedName

        // Check for file URLs
        if types.contains(.fileURL),
           let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           let url = urls.first {
            itemTypes.append(.fileURL)
            originalFileURL = url.path
            textPreview = url.lastPathComponent
        }

        // Check for images
        if types.contains(.tiff) || types.contains(.png) {
            if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
                itemTypes.append(.image)
                let fileName = UUID().uuidString + ".png"
                let blobPath = blobsURL.appendingPathComponent(fileName)
                try? imageData.write(to: blobPath)
                blobFileName = fileName
            }
        }

        // Check for rich text
        if types.contains(.rtf) {
            if let rtfData = pasteboard.data(forType: .rtf) {
                itemTypes.append(.richText)
                let fileName = UUID().uuidString + ".rtf"
                let rtfPath = blobsURL.appendingPathComponent(fileName)
                try? rtfData.write(to: rtfPath)
                richTextBlobFileName = fileName
            }
        }

        // Check for plain text
        if let text = pasteboard.string(forType: .string) {
            if !itemTypes.contains(.text) {
                itemTypes.append(.text)
            }
            textPreview = String(text.prefix(500))
        }

        guard !itemTypes.isEmpty else { return }

        // Deduplicate: remove previous identical text items
        if let preview = textPreview {
            items.removeAll { $0.textPreview == preview && $0.types == itemTypes }
        }

        let item = ClipboardItem(
            types: itemTypes,
            textPreview: textPreview,
            blobFileName: blobFileName,
            richTextBlobFileName: richTextBlobFileName,
            sourceAppBundleID: sourceAppBundleID,
            sourceAppName: sourceAppName,
            originalFileURL: originalFileURL
        )

        items.insert(item, at: 0)
        pruneIfNeeded()
        saveIndex()
    }

    func writeToPasteboard(_ item: ClipboardItem) {
        isInternalWrite = true
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        var wroteContent = false

        // Write image blob
        if let blobName = item.blobFileName {
            let blobPath = blobsURL.appendingPathComponent(blobName)
            if let data = try? Data(contentsOf: blobPath) {
                pasteboard.setData(data, forType: .png)
                wroteContent = true
            }
        }

        // Write rich text blob
        if let rtfName = item.richTextBlobFileName {
            let rtfPath = blobsURL.appendingPathComponent(rtfName)
            if let data = try? Data(contentsOf: rtfPath) {
                pasteboard.setData(data, forType: .rtf)
                wroteContent = true
            }
        }

        // Write file URL
        if let fileURLString = item.originalFileURL {
            let url = URL(fileURLWithPath: fileURLString)
            pasteboard.writeObjects([url as NSURL])
            wroteContent = true
        }

        // Write plain text
        if let text = item.textPreview {
            pasteboard.setString(text, forType: .string)
            wroteContent = true
        }

        if !wroteContent {
            isInternalWrite = false
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        // Remove blob files
        if let blobName = item.blobFileName {
            let blobPath = blobsURL.appendingPathComponent(blobName)
            try? fileManager.removeItem(at: blobPath)
        }
        if let rtfName = item.richTextBlobFileName {
            let rtfPath = blobsURL.appendingPathComponent(rtfName)
            try? fileManager.removeItem(at: rtfPath)
        }
        items.removeAll { $0.id == item.id }
        saveIndex()
    }

    func clearAll() {
        for item in items {
            if let blobName = item.blobFileName {
                try? fileManager.removeItem(at: blobsURL.appendingPathComponent(blobName))
            }
            if let rtfName = item.richTextBlobFileName {
                try? fileManager.removeItem(at: blobsURL.appendingPathComponent(rtfName))
            }
        }
        items.removeAll()
        saveIndex()
    }

    func updateMaxRecords(_ newMax: Int) {
        maxRecords = newMax
        pruneIfNeeded()
        saveIndex()
    }

    func thumbnailImage(for item: ClipboardItem) -> NSImage? {
        guard let blobName = item.blobFileName else { return nil }
        let blobPath = blobsURL.appendingPathComponent(blobName)
        guard let data = try? Data(contentsOf: blobPath),
              let image = NSImage(data: data) else { return nil }

        let thumbSize = NSSize(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
        let thumbnail = NSImage(size: thumbSize)
        thumbnail.lockFocus()
        let aspect = min(thumbSize.width / image.size.width, thumbSize.height / image.size.height)
        let drawSize = NSSize(width: image.size.width * aspect, height: image.size.height * aspect)
        let origin = NSPoint(x: (thumbSize.width - drawSize.width) / 2,
                             y: (thumbSize.height - drawSize.height) / 2)
        image.draw(in: NSRect(origin: origin, size: drawSize))
        thumbnail.unlockFocus()
        return thumbnail
    }

    // MARK: - Persistence

    private func loadIndex() {
        guard fileManager.fileExists(atPath: indexURL.path) else { return }
        do {
            let data = try Data(contentsOf: indexURL)
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            NSLog("ClipVault: Failed to load index: \(error)")
        }
    }

    private func saveIndex() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            try data.write(to: indexURL, options: .atomic)
        } catch {
            NSLog("ClipVault: Failed to save index: \(error)")
        }
    }

    private func pruneIfNeeded() {
        while items.count > maxRecords {
            let removed = items.removeLast()
            if let blobName = removed.blobFileName {
                try? fileManager.removeItem(at: blobsURL.appendingPathComponent(blobName))
            }
            if let rtfName = removed.richTextBlobFileName {
                try? fileManager.removeItem(at: blobsURL.appendingPathComponent(rtfName))
            }
        }
    }
}
