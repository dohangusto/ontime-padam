//
//  RankedSourceRow.swift
//  padam
//
//  Row describing one ranked water source. Deliberately differentiates hydrants
//  (low reliability) and "far" points so uniform styling never implies every
//  type is equally dependable.
//

import SwiftUI

struct RankedSourceRow: View {
    let ranked: RankedWaterSource
    var showsAddress = true

    private var source: WaterSource { ranked.source }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SourcePinView(type: source.type)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(source.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(DistanceFormat.string(ranked.distanceMeters))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if showsAddress, !source.address.isEmpty {
                    Text(source.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !markers.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(markers, id: \.self) { MarkerBadge(marker: $0) }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var markers: [Marker] {
        var result: [Marker] = []
        if ranked.isLowReliability { result.append(.lowReliability) }
        if ranked.isFar { result.append(.far) }
        return result
    }

    enum Marker: Hashable {
        case lowReliability
        case far

        var label: String {
            switch self {
            case .lowReliability: return "Keandalan rendah"
            case .far: return "Jauh (>3 km)"
            }
        }
        var systemImage: String {
            switch self {
            case .lowReliability: return "exclamationmark.triangle.fill"
            case .far: return "location.slash"
            }
        }
        var tint: Color {
            switch self {
            case .lowReliability: return .orange
            case .far: return .secondary
            }
        }
    }
}

private struct MarkerBadge: View {
    let marker: RankedSourceRow.Marker

    var body: some View {
        Label(marker.label, systemImage: marker.systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(marker.tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(marker.tint.opacity(0.15), in: Capsule())
    }
}
