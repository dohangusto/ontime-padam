//
//  MapAnnotations.swift
//  padam
//
//  Small annotation views used on the map: aggregated cluster bubbles, single
//  water-source pins, and the fire-location marker.
//

import SwiftUI

/// A cluster bubble showing how many sources it aggregates.
struct ClusterBubbleView: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(8)
            .frame(minWidth: 32, minHeight: 32)
            .background(Color.accentColor, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(radius: 2)
    }
}

/// A single water-source pin, tinted and iconed by type.
struct SourcePinView: View {
    let type: WaterSourceType
    var isSelected: Bool = false

    var body: some View {
        Image(systemName: type.symbolName)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(7)
            .background(type.tint, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: isSelected ? 3 : 1.5))
            .scaleEffect(isSelected ? 1.25 : 1)
            .shadow(radius: isSelected ? 4 : 1)
    }
}

/// The fire location the operator is refilling for.
struct FireMarkerView: View {
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .padding(8)
            .background(.red, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(radius: 3)
    }
}
