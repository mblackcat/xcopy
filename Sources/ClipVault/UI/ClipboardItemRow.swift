import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let store: ClipboardStore

    var body: some View {
        HStack(spacing: 8) {
            typeIcon
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)

            if item.primaryType == .image, let thumbnail = store.thumbnailImage(for: item) {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayText)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .truncationMode(.tail)

                HStack(spacing: 4) {
                    Text(relativeTimestamp)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    if let appName = item.sourceAppName {
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(appName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.01))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var typeIcon: some View {
        switch item.primaryType {
        case .text:
            Image(systemName: "doc.text")
        case .richText:
            Image(systemName: "doc.richtext")
        case .image:
            Image(systemName: "photo")
        case .fileURL:
            if item.containsDirectory {
                Image(systemName: "folder.fill")
            } else {
                Image(systemName: "doc")
            }
        }
    }

    private var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }
}
