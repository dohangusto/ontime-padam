//
//  ResultsSheetView.swift
//  padam
//
//  Results state — the screen that fulfills the whole promise. All five type
//  groups are visible at once. At medium height each group shows its top entry;
//  expanding to large reveals the full list (up to 3 per type).
//

import SwiftUI

struct ResultsSheetView: View {
    let groups: [RankedGroup]
    let isExpanded: Bool
    var onSelect: (WaterSource) -> Void
    var onChangeLocation: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(groups) { group in
                        GroupBlock(
                            group: group,
                            isExpanded: isExpanded,
                            onSelect: onSelect
                        )
                    }
                    DataAttributionFooter()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onChangeLocation) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(8)
                    .background(.quaternary, in: Circle())
            }
            .buttonStyle(.plain)

            Label("Lokasi kebakaran", systemImage: "flame.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }
}

/// One reliability group. Shows its top entry (or all three when expanded), and
/// clearly flags the empty deferred categories rather than hiding them.
private struct GroupBlock: View {
    let group: RankedGroup
    let isExpanded: Bool
    var onSelect: (WaterSource) -> Void

    var body: some View {
        if isExpanded {
            expandedBlock
        } else {
            compactRow
        }
    }

    /// Dense one-glance row so all five groups fit at the medium detent without
    /// scrolling — the results screen's most important requirement.
    private var compactRow: some View {
        Button {
            if let top = group.sources.first { onSelect(top.source) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: group.type.symbolName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(group.type.tint, in: Circle())

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(group.type.displayName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        if group.type.isLowReliability {
                            Text("keandalan rendah")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                    if let top = group.sources.first {
                        Text(top.source.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Belum ada data")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 4)

                if let top = group.sources.first {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(DistanceFormat.string(top.distanceMeters))
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                        if top.isFar {
                            Text("jauh")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(group.isEmpty)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    /// Rich block used at the large detent: full 3-per-type list with addresses.
    private var expandedBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: group.type.symbolName)
                    .font(.footnote.bold())
                    .foregroundStyle(group.type.tint)
                Text(group.type.displayName)
                    .font(.subheadline.weight(.bold))
                if group.type.isLowReliability {
                    Text("keandalan rendah")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                Spacer()
                if !group.isEmpty {
                    Text("\(group.sources.count) terdekat")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if group.isEmpty {
                Text("Belum ada data")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(group.sources) { ranked in
                    Button {
                        onSelect(ranked.source)
                    } label: {
                        RankedSourceRow(ranked: ranked, showsAddress: true)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
#Preview("Results – medium (top per group)") {
    ResultsSheetView(groups: PreviewSamples.groups, isExpanded: false,
                     onSelect: { _ in }, onChangeLocation: {})
}

#Preview("Results – large (full list)") {
    ResultsSheetView(groups: PreviewSamples.groups, isExpanded: true,
                     onSelect: { _ in }, onChangeLocation: {})
}
#endif
