//
//  RecentSearchRow.swift
//  padam
//
//  Native Apple Maps style row for recent searches and saved locations.
//

import SwiftUI

struct RecentSearchRow: View {
    let recent: RecentSearch
    var onSelect: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(recent.iconTint.opacity(0.18))
                        .frame(width: 36, height: 36)

                    Image(systemName: recent.iconSystemName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(recent.iconTint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(recent.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !recent.subtitle.isEmpty {
                        Text(recent.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Menu {
                    Button(role: .destructive) {
                        onDelete?()
                    } label: {
                        Label("Hapus dari Recents", systemImage: "trash")
                    }
                    Button {
                        UIPasteboard.general.string = "\(recent.title), \(recent.subtitle)"
                    } label: {
                        Label("Salin Alamat", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pilihan lainnya untuk \(recent.title)")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AccessibilityText.recentSearch(recent))
        .accessibilityHint("Ketuk dua kali untuk menggunakan lokasi ini")
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(RecentSearch.defaults) { item in
            RecentSearchRow(recent: item, onSelect: {}, onDelete: {})
            Divider().padding(.leading, 60)
        }
    }
    .background(.black)
}
