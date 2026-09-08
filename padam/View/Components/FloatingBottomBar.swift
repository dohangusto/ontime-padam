//
//  FloatingBottomBar.swift
//  padam
//
//  Native Apple Maps style floating capsule toolbar with Plus, Star, and Ellipsis actions.
//

import SwiftUI

struct FloatingBottomBar: View {
    let source: WaterSource
    var isSaved: Bool
    var onToggleSave: () -> Void
    var onAddGuide: () -> Void
    var onOpenInMaps: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            Button(action: onAddGuide) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Button(action: onToggleSave) {
                Image(systemName: isSaved ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSaved ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Menu {
                Button(action: onOpenInMaps) {
                    Label("Buka di Apple Maps", systemImage: "map")
                }
                Button {
                    let text = "\(source.coordinate.latitude), \(source.coordinate.longitude)"
                    UIPasteboard.general.string = text
                } label: {
                    Label("Salin Koordinat", systemImage: "location.north.line")
                }
                Button {
                    UIPasteboard.general.string = "\(source.name), \(source.address)"
                } label: {
                    Label("Salin Alamat Lengkap", systemImage: "doc.on.doc")
                }
                ShareLink(
                    item: "\(source.name)\n\(source.address)\nKoordinat: \(source.coordinate.latitude), \(source.coordinate.longitude)"
                ) {
                    Label("Bagikan Lokasi", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    FloatingBottomBar(
        source: WaterSource(
            type: .posDamkar,
            name: "Pos Damkar Menteng",
            address: "Jl. Pegangsaan Timur No. 1",
            coordinate: Coordinate(latitude: -6.198, longitude: 106.845)
        ),
        isSaved: false,
        onToggleSave: {},
        onAddGuide: {},
        onOpenInMaps: {}
    )
    .padding()
    .background(.black)
}
