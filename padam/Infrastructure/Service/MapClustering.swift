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
    /// Zoom threshold (in longitude span delta).
    /// Above this threshold: hide all points and display "Perbesar untuk melihat titik" hint.
    /// Below or equal to this threshold: reveal individual water-source pins.
    static let zoomThreshold: Double = 0.08

    /// Determines if the visible span is too far zoomed out to display individual points.
    static func isZoomedOut(longitudeSpan: Double) -> Bool {
        longitudeSpan > zoomThreshold
    }

    /// Legacy cell size helper for backwards compatibility.
    static let cellsAcrossSpan = 6.0

    static func cellSize(forLongitudeSpan span: Double) -> Double {
        guard span.isFinite, span > 0 else { return 0 }
        return span / cellsAcrossSpan
    }

    /// Primary clustering method implementing zoom-based tiered visibility:
    /// - Filters sources based on type priority for the current longitude span.
    ///   (Pos DAMKAR > Sungai > Kolam Renang/Got > Hidran)
    /// - Renders each visible source as an individual pin.
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
