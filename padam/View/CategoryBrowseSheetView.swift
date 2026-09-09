//
//  CategoryBrowseSheetView.swift
//  padam
//
//  Category browsing screen:
//  Displays all water sources of a selected category (e.g. Sungai, Pos DAMKAR,
//  Kolam Renang, Hidran) grouped by administrative region (Jakarta Pusat,
//  Jakarta Selatan, Jakarta Barat, Jakarta Timur, Jakarta Utara, Kepulauan Seribu)
//  in expandable dropdown accordions.
//

import SwiftUI

struct CategoryBrowseSheetView: View {
    let type: WaterSourceType
    let sources: [WaterSource]
    let isAvailable: Bool
    var referenceCoordinate: Coordinate
    var isSmall: Bool = false
    var isFullyExpanded: Bool = false
    var onSelect: (WaterSource) -> Void
    var onBack: () -> Void

    @State private var filterQuery: String = ""
    @State private var expandedRegions: Set<String> = []

    private static let standardRegionsOrder = [
        "Jakarta Pusat",
        "Jakarta Utara",
        "Jakarta Barat",
        "Jakarta Selatan",
        "Jakarta Timur",
        "Kepulauan Seribu",
        "Lainnya"
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, isSmall ? 10 : 12)
                .padding(.bottom, isSmall ? 8 : 10)

            if !isSmall {
                if isAvailable && !sources.isEmpty {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if !isAvailable || sources.isEmpty {
                            emptyDatasetCard
                        } else if filteredGroupedSources.isEmpty {
                            emptySearchCard
                        } else {
                            regionalAccordionList
                        }

                        DataAttributionFooter()
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
                .scrollDisabled(!isFullyExpanded)
            }
        }
        .frame(maxHeight: .infinity, alignment: isSmall ? .center : .top)
        .onAppear {
            // Only open the top-most dropdown list by default; leave the rest collapsed
            if expandedRegions.isEmpty, let topRegion = orderedRegions.first {
                expandedRegions = [topRegion]
            }
        }
    }

    // MARK: Header (Back Button, Category Icon, Title, Badge)

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")
            .accessibilityHint("Kembali ke pencarian sumber air")

            ZStack {
                Circle()
                    .fill(type.tint.opacity(0.18))
                    .frame(width: 36, height: 36)

                Image(systemName: type.symbolName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(type.tint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(type.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    if type.isLowReliability {
                        Text("keandalan rendah")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                    }
                }

                Text(isAvailable ? "\(sources.count) titik terdaftar di Jakarta" : "Dataset belum dimuat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer()
        }
    }

    // MARK: Search / Filter Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Cari di \(type.displayName)...", text: $filterQuery)
                .font(.subheadline)
                .autocorrectionDisabled()

            if !filterQuery.isEmpty {
                Button {
                    filterQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hapus filter pencarian")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
    }

    // MARK: Regional Accordion List

    private var regionalAccordionList: some View {
        VStack(spacing: 12) {
            ForEach(orderedRegions, id: \.self) { region in
                if let items = filteredGroupedSources[region], !items.isEmpty {
                    RegionAccordionCard(
                        region: region,
                        type: type,
                        items: items,
                        referenceCoordinate: referenceCoordinate,
                        isExpanded: expandedRegions.contains(region),
                        onToggle: { toggleRegion(region) },
                        onSelect: onSelect
                    )
                }
            }
        }
    }

    // MARK: Empty States

    private var emptyDatasetCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("Dataset Belum Tersedia")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Data \(type.displayName) belum dimuat atau belum tersedia dalam sistem.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
        .accessibilityElement(children: .combine)
    }

    private var emptySearchCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26))
                .foregroundStyle(.secondary)

            Text("Tidak ditemukan titik untuk \"\(filterQuery)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
        .accessibilityElement(children: .combine)
    }

    // MARK: Helpers & Grouping

    private var groupedSources: [String: [WaterSource]] {
        Dictionary(grouping: sources, by: { $0.administrativeRegion })
    }

    private var filteredGroupedSources: [String: [WaterSource]] {
        let matchingSources: [WaterSource]
        if filterQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            matchingSources = sources
        } else {
            let q = filterQuery.lowercased()
            matchingSources = sources.filter {
                $0.name.lowercased().contains(q) ||
                $0.address.lowercased().contains(q) ||
                ($0.kecamatan?.lowercased().contains(q) ?? false) ||
                ($0.kelurahan?.lowercased().contains(q) ?? false) ||
                $0.administrativeRegion.lowercased().contains(q)
            }
        }
        return Dictionary(grouping: matchingSources, by: { $0.administrativeRegion })
    }

    private var orderedRegions: [String] {
        let keys = Set(filteredGroupedSources.keys)
        var result: [String] = []
        for reg in Self.standardRegionsOrder {
            if keys.contains(reg) {
                result.append(reg)
            }
        }
        // Append any non-standard regions
        let remaining = keys.subtracting(Set(Self.standardRegionsOrder)).sorted()
        result.append(contentsOf: remaining)
        return result
    }

    private func toggleRegion(_ region: String) {
        withAnimation(.snappy(duration: 0.25)) {
            if expandedRegions.contains(region) {
                expandedRegions.remove(region)
            } else {
                expandedRegions.insert(region)
            }
        }
    }
}

// MARK: Region Accordion Card Component

private struct RegionAccordionCard: View {
    let region: String
    let type: WaterSourceType
    let items: [WaterSource]
    let referenceCoordinate: Coordinate
    let isExpanded: Bool
    var onToggle: () -> Void
    var onSelect: (WaterSource) -> Void

    private var sortedItems: [WaterSource] {
        items.sorted {
            referenceCoordinate.distance(to: $0.coordinate) < referenceCoordinate.distance(to: $1.coordinate)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Accordion Header Button
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(type.tint)
                        .frame(width: 28, height: 28)
                        .background(type.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(region)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(items.count) titik")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08), in: Capsule())

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(regionAccessibilityLabel)
            .accessibilityHint(isExpanded ? "Ketuk dua kali untuk menyembunyikan daftar \(region)" : "Ketuk dua kali untuk menampilkan daftar \(region)")

            // Dropdown List of Water Sources
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, source in
                        Divider()
                            .padding(.leading, 48)

                        CategorySourceItemRow(
                            source: source,
                            type: type,
                            referenceCoordinate: referenceCoordinate,
                            onSelect: { onSelect(source) }
                        )
                    }
                }
                .background(Color.white.opacity(0.03))
            }
        }
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
    }

    private var regionAccessibilityLabel: String {
        "\(region), \(items.count) titik \(type.displayName)"
    }
}

// MARK: Category Source Item Row

private struct CategorySourceItemRow: View {
    let source: WaterSource
    let type: WaterSourceType
    let referenceCoordinate: Coordinate
    var onSelect: () -> Void

    private var distance: Double {
        referenceCoordinate.distance(to: source.coordinate)
    }

    private var status: ConditionState {
        ConditionState(kondisi: source.kondisi)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                // Status icon badge
                ZStack {
                    Circle()
                        .fill(status.tint.opacity(0.18))
                        .frame(width: 28, height: 28)

                    Image(systemName: status.symbolName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(status.tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(source.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let subtitle = locationSubtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(DistanceFormat.string(distance))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(status.label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(status.tint)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sourceAccessibilityLabel)
        .accessibilityHint("Ketuk dua kali untuk membuka detail sumber air")
    }

    private var locationSubtitle: String? {
        let parts = [source.kelurahan, source.kecamatan].compactMap { $0 }.filter { !$0.isEmpty }
        if !parts.isEmpty {
            return parts.joined(separator: ", ")
        }
        return source.address.isEmpty ? nil : source.address
    }

    private var sourceAccessibilityLabel: String {
        var parts = [
            AccessibilityText.waterSource(source, distanceMeters: distance),
            "Status \(status.label)"
        ]

        if let locationSubtitle, !locationSubtitle.isEmpty {
            parts.append(locationSubtitle)
        }

        return parts.joined(separator: ", ")
    }
}
