//
//  MapClustering.swift
//  padam
//
//  Option 2A: Clean map at coarse zoom. Above the zoom threshold, points are
//  hidden to keep the map clean for orientation, and a hint pill is shown.
//  When zoomed in below the threshold, individual water-source pins are shown.
//

import Foundation

struct MapCluster: Identifiable, Hashable {
    let id: String
    let coordinate: Coordinate
    let title: String?
    let sources: [WaterSource]
    let dominantType: WaterSourceType

    var count: Int { sources.count }
    var isCluster: Bool { sources.count > 1 }
    var singleSource: WaterSource? { sources.count == 1 ? sources.first : nil }

    init(
        id: String,
        coordinate: Coordinate,
        title: String? = nil,
        sources: [WaterSource]
    ) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.sources = sources
        self.dominantType = Self.calculateDominantType(in: sources)
    }

    static func calculateDominantType(in sources: [WaterSource]) -> WaterSourceType {
        guard let first = sources.first else { return .hidran }
        var counts: [WaterSourceType: Int] = [:]
        for s in sources {
            counts[s.type, default: 0] += 1
        }
        return counts.max { a, b in
            if a.value != b.value {
                return a.value < b.value
            }
            return a.key.reliabilityPriority > b.key.reliabilityPriority
        }?.key ?? first.type
    }
}

enum MapClustering {
    /// The 4-tier administrative clustering levels from zoom out to zoom in.
    enum AdministrativeTier: String, CaseIterable {
        case wilayah      // 1. Cluster berdasarkan wilayah (zoom out)
        case kecamatan    // 2. Cluster berdasarkan kecamatan
        case kelurahan    // 3. Cluster berdasarkan kelurahan
        case individual   // 4. Tampilkan semuanya (zoom in)
    }

    /// Determines the administrative clustering tier based on the map's visible longitude span.
    static func tier(forLongitudeDelta delta: Double) -> AdministrativeTier {
        if delta > 0.20 {
            return .wilayah
        } else if delta > 0.07 {
            return .kecamatan
        } else if delta > 0.022 {
            return .kelurahan
        } else {
            return .individual
        }
    }

    /// Legacy zoom threshold helper.
    static let zoomThreshold: Double = 0.08

    /// Determines if the visible span is too far zoomed out.
    static func isZoomedOut(longitudeSpan: Double) -> Bool {
        longitudeSpan > zoomThreshold
    }

    /// Legacy cell size helper for backwards compatibility.
    static let cellsAcrossSpan = 6.0

    static func cellSize(forLongitudeSpan span: Double) -> Double {
        guard span.isFinite, span > 0 else { return 0 }
        return span / cellsAcrossSpan
    }

    /// Primary clustering method for IDLE / Initial App State:
    /// Implements tiered visibility by type from zoom out to zoom in:
    /// - Zoom out: Pos DAMKAR > Sungai > Kolam Renang/Got > Hidran
    /// - Zoom in: All types visible
    static func cluster(_ sources: [WaterSource], longitudeDelta: Double) -> [MapCluster] {
        guard !sources.isEmpty else { return [] }

        // Filter sources based on tiered visibility priority for the given zoom span
        let visibleSources = sources.filter { $0.type.isVisible(atLongitudeSpan: longitudeDelta) }

        return visibleSources.map {
            MapCluster(
                id: "single-\($0.id.uuidString)",
                coordinate: $0.coordinate,
                title: $0.name,
                sources: [$0]
            )
        }
    }

    /// Category-specific clustering when browsing a selected category from the bottom sheet.
    /// Implements the 4-tier administrative clustering hierarchy:
    /// 1. Cluster berdasarkan wilayah (zoom out)
    /// 2. Cluster berdasarkan kecamatan
    /// 3. Cluster berdasarkan kelurahan
    /// 4. Tampilkan semuanya (zoom in)
    static func clusterCategory(_ sources: [WaterSource], longitudeDelta: Double) -> [MapCluster] {
        clusterByAdministrativeHierarchy(sources, longitudeDelta: longitudeDelta)
    }

    /// Clusters a collection of water sources according to the 4 administrative zoom tiers.
    static func clusterByAdministrativeHierarchy(_ sources: [WaterSource], longitudeDelta: Double) -> [MapCluster] {
        guard !sources.isEmpty else { return [] }

        let currentTier = tier(forLongitudeDelta: longitudeDelta)

        switch currentTier {
        case .individual:
            return sources.map {
                MapCluster(
                    id: "single-\($0.id.uuidString)",
                    coordinate: $0.coordinate,
                    title: $0.name,
                    sources: [$0]
                )
            }

        case .wilayah:
            var buckets: [String: [WaterSource]] = [:]
            for s in sources {
                let key = s.administrativeRegion
                buckets[key, default: []].append(s)
            }
            return createClusters(from: buckets, tierPrefix: "wilayah")

        case .kecamatan:
            var buckets: [String: (title: String, sources: [WaterSource])] = [:]
            for s in sources {
                let key = "\(s.administrativeRegion)_\(s.administrativeKecamatan)"
                if buckets[key] == nil {
                    buckets[key] = (title: s.administrativeKecamatan, sources: [s])
                } else {
                    buckets[key]?.sources.append(s)
                }
            }
            return createClustersWithCustomTitles(from: buckets, tierPrefix: "kecamatan")

        case .kelurahan:
            var buckets: [String: (title: String, sources: [WaterSource])] = [:]
            for s in sources {
                let key = "\(s.administrativeRegion)_\(s.administrativeKecamatan)_\(s.administrativeKelurahan)"
                if buckets[key] == nil {
                    buckets[key] = (title: s.administrativeKelurahan, sources: [s])
                } else {
                    buckets[key]?.sources.append(s)
                }
            }
            return createClustersWithCustomTitles(from: buckets, tierPrefix: "kelurahan")
        }
    }

    private static func createClusters(
        from buckets: [String: [WaterSource]],
        tierPrefix: String
    ) -> [MapCluster] {
        return buckets.map { key, group in
            if group.count == 1, let single = group.first {
                return MapCluster(
                    id: "single-\(single.id.uuidString)",
                    coordinate: single.coordinate,
                    title: single.name,
                    sources: [single]
                )
            }

            let avgLat = group.reduce(0.0) { $0 + $1.coordinate.latitude } / Double(group.count)
            let avgLon = group.reduce(0.0) { $0 + $1.coordinate.longitude } / Double(group.count)

            return MapCluster(
                id: "\(tierPrefix)-\(key)",
                coordinate: Coordinate(latitude: avgLat, longitude: avgLon),
                title: key,
                sources: group
            )
        }
    }

    private static func createClustersWithCustomTitles(
        from buckets: [String: (title: String, sources: [WaterSource])],
        tierPrefix: String
    ) -> [MapCluster] {
        return buckets.map { key, item in
            let group = item.sources
            if group.count == 1, let single = group.first {
                return MapCluster(
                    id: "single-\(single.id.uuidString)",
                    coordinate: single.coordinate,
                    title: single.name,
                    sources: [single]
                )
            }

            let avgLat = group.reduce(0.0) { $0 + $1.coordinate.latitude } / Double(group.count)
            let avgLon = group.reduce(0.0) { $0 + $1.coordinate.longitude } / Double(group.count)

            return MapCluster(
                id: "\(tierPrefix)-\(key)",
                coordinate: Coordinate(latitude: avgLat, longitude: avgLon),
                title: item.title,
                sources: group
            )
        }
    }

    /// Fallback grid-based clustering for testing or custom cell sizes.
    static func cluster(_ sources: [WaterSource], cellSizeDegrees: Double) -> [MapCluster] {
        guard cellSizeDegrees > 0 else {
            return sources.map {
                MapCluster(id: "single-\($0.id.uuidString)", coordinate: $0.coordinate, title: $0.name, sources: [$0])
            }
        }

        var buckets: [String: [WaterSource]] = [:]
        for source in sources {
            let gx = Int((source.coordinate.longitude / cellSizeDegrees).rounded(.down))
            let gy = Int((source.coordinate.latitude / cellSizeDegrees).rounded(.down))
            buckets["\(gx):\(gy)", default: []].append(source)
        }

        return buckets.map { key, group in
            if group.count == 1, let single = group.first {
                return MapCluster(
                    id: "single-\(single.id.uuidString)",
                    coordinate: single.coordinate,
                    title: single.name,
                    sources: [single]
                )
            }

            let avgLat = group.reduce(0.0) { $0 + $1.coordinate.latitude } / Double(group.count)
            let avgLon = group.reduce(0.0) { $0 + $1.coordinate.longitude } / Double(group.count)
            return MapCluster(
                id: "grid-\(key)",
                coordinate: Coordinate(latitude: avgLat, longitude: avgLon),
                title: group.first?.name,
                sources: group
            )
        }
    }
}
