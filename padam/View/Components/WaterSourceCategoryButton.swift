//
//  WaterSourceCategoryButton.swift
//  padam
//
//  Native Apple Maps style circular category button for the "Sumber Air >" section.
//

import SwiftUI

struct WaterSourceCategoryButton: View {
    let type: WaterSourceType
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(type.tint.opacity(0.18))
                        .frame(width: 64, height: 64)

                    Image(systemName: type.symbolName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(type.tint)
                }

                Text(type.displayName)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(WaterSourceType.allCases) { type in
            WaterSourceCategoryButton(type: type, action: {})
        }
    }
    .padding()
    .background(.black)
}
