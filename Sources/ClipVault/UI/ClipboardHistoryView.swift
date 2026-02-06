import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var store: ClipboardStore
    let onSelect: (ClipboardItem) -> Void
    @State private var searchText = ""

    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return store.items
        }
        return store.items.filter { item in
            item.displayText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard history…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Items list
            if filteredItems.isEmpty {
                Spacer()
                Text(store.items.isEmpty ? "No clipboard history" : "No matching items")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredItems) { item in
                            ClipboardItemRow(item: item, store: store)
                                .onTapGesture {
                                    onSelect(item)
                                }
                                .contextMenu {
                                    Button("Delete") {
                                        store.deleteItem(item)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // Footer
            HStack {
                Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                if !store.items.isEmpty {
                    Button("Clear All") {
                        store.clearAll()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(width: Constants.panelWidth, height: Constants.panelHeight)
    }
}
