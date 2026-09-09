//
//  FindNearbyRow.swift
//  padam
//
//  Native Apple Maps style row for Find Nearby water source categories.
//

import SwiftUI

struct FindNearbyRow: View {
    let type: WaterSourceType
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Image(systemName: type.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(type.tint)
                    .frame(width: 28, alignment: .center)

                Text(type.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cari \(type.displayName) terdekat")
        .accessibilityHint("Menampilkan sumber air terdekat untuk kategori ini")
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(WaterSourceType.allCases) { type in
            FindNearbyRow(type: type, onSelect: {})
            Divider().padding(.leading, 56)
        }
    }
    .background(.black)
}
