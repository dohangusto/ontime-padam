//
//  ResultsSheetView.swift
//  padam
//
//  Results state — unified with Apple Maps native design language:
//  - Top header with circular back button, Fire location title & subtitle, and change location button.
//  - Unified Inset Grouped card container with consistent circular icon badges, typography, and dividers.
//  - Dense, one-glance view at .medium detent and rich multi-source view at .large detent.
//

import SwiftUI

struct ResultsSheetView: View {
    let groups: [RankedGroup]
    var locationTitle: String = "Lokasi Kebakaran"
    var locationSubtitle: String = "Titik acuan rekomendasi sumber air"
    var isSmall: Bool = false
    var isExpanded: Bool = false
    var onSelect: (WaterSource) -> Void
    var onChangeLocation: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, isSmall ? 10 : 12)
                .padding(.bottom, isSmall ? 10 : 8)

            if !isSmall {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if isExpanded {
                            expandedResultsList
                        } else {
                            compactOverviewCard
                        }

                        DataAttributionFooter()
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                }
                .scrollDisabled(!isExpanded)
            }
        }
        .frame(maxHeight: .infinity, alignment: isSmall ? .center : .top)
    }

    // MARK: Header (Share Button, Title & Subtitle, Exit Button)

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ShareLink(
                item: "\(locationTitle)\n\(locationSubtitle)\nSumber Air Terdekat:\n" +
                      groups.compactMap { group -> String? in
                          guard let top = group.sources.first else { return nil }
                          return "• \(group.type.displayName): \(top.source.name) (\(DistanceFormat.string(top.distanceMeters)))"
                      }.joined(separator: "\n")
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                Text(locationTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(locationSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            Button(action: onChangeLocation) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Compact Overview Card (.medium detent)

    private var compactOverviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Rekomendasi Terdekat")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("5 Kategori")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    CompactGroupRow(group: group) { source in
                        onSelect(source)
                    }

                    if index < groups.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
        }
    }

    // MARK: Expanded Results List (.large detent)

    private var expandedResultsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Semua Sumber Air Terdekat")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    // Category Section Header
                    HStack(spacing: 8) {
                        Image(systemName: group.type.symbolName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(group.type.tint)

                        Text(group.type.displayName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)

                        if group.type.isLowReliability {
                            Text("keandalan rendah")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15), in: Capsule())
                        }

                        Spacer()

                        if !group.isEmpty {
                            Text("\(group.sources.count) titik")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)

                    // Card of sources for this category
                    VStack(spacing: 0) {
                        if group.isEmpty {
                            HStack {
                                Text("Belum ada data tersedia di wilayah ini")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        } else {
                            ForEach(Array(group.sources.enumerated()), id: \.element.id) { index, ranked in
                                Button {
                                    onSelect(ranked.source)
                                } label: {
                                    HStack(alignment: .center, spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(group.type.tint.opacity(0.18))
                                                .frame(width: 36, height: 36)

                                            Image(systemName: group.type.symbolName)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(group.type.tint)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(ranked.source.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)

                                            if !ranked.source.address.isEmpty {
                                                Text(ranked.source.address)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer(minLength: 8)

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(DistanceFormat.string(ranked.distanceMeters))
                                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                                .foregroundStyle(.primary)

                                            if ranked.isFar {
                                                Text("jauh")
                                                    .font(.caption2.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if index < group.sources.count - 1 {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                    }
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                }
            }
        }
    }
}

// MARK: Compact Group Row Component

private struct CompactGroupRow: View {
    let group: RankedGroup
    var onSelect: (WaterSource) -> Void

    var body: some View {
        Button {
            if let top = group.sources.first {
                onSelect(top.source)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(group.type.tint.opacity(0.18))
                        .frame(width: 36, height: 36)

                    Image(systemName: group.type.symbolName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(group.type.tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(group.type.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if group.type.isLowReliability {
                            Text("keandalan rendah")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.15), in: Capsule())
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

                Spacer(minLength: 8)

                if let top = group.sources.first {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(DistanceFormat.string(top.distanceMeters))
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)

                        if top.isFar {
                            Text("jauh")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                } else {
                    Text("--")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(group.isEmpty)
    }
}

#if DEBUG
#Preview("Results – Compact") {
    ResultsSheetView(
        groups: PreviewSamples.groups,
        locationTitle: "Monas",
        locationSubtitle: "Jakarta Pusat",
        isExpanded: false,
        onSelect: { _ in },
        onChangeLocation: {}
    )
    .background(.black)
}

#Preview("Results – Expanded") {
    ResultsSheetView(
        groups: PreviewSamples.groups,
        locationTitle: "Monas",
        locationSubtitle: "Jakarta Pusat",
        isExpanded: true,
        onSelect: { _ in },
        onChangeLocation: {}
    )
    .background(.black)
}
#endif
