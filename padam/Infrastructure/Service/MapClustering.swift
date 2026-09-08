//
//  MapClustering.swift
//  padam
//
//  Zoom-based aggregation so zoomed-out views aren't flooded with pins. Pure
//  logic (no MapKit) kept out of the ViewModel so it can be unit-tested.
//
//  Approach: snap each point to a square grid whose cell size scales with the
//  visible longitude span (i.e. the zoom level). Cells with one point render as
//  a single pin; cells with more render as a count bubble.
//

import Foundation

struct MapCluster: Identifiable, Hashable {
    /// Stable identity derived from the grid cell, so pins don't churn while panning.
    let id: String
    let coordinate: Coordinate
    let sources: [WaterSource]

    var count: Int { sources.count }
    var isCluster: Bool { sources.count > 1 }
    /// The single source when this isn't a cluster.
    var singleSource: WaterSource? { sources.count == 1 ? sources.first : nil }
}

enum MapClustering {
    /// Target number of grid cells across the visible span. Higher = finer clusters.
    static let cellsAcrossSpan = 10.0

    /// Cell size (in degrees) for a given visible longitude span. Larger span
    /// (zoomed out) → larger cells → more aggregation.
    static func cellSize(forLongitudeSpan span: Double) -> Double {
        guard span.isFinite, span > 0 else { return 0 }
        return span / cellsAcrossSpan
    }

    /// Groups sources into clusters for the given cell size. A cell size of 0 (or
    /// invalid) means "fully zoomed in": every source is its own pin.
    static func cluster(_ sources: [WaterSource], cellSizeDegrees: Double) -> [MapCluster] {
        guard cellSizeDegrees > 0 else {
            return sources.map {
                MapCluster(id: $0.id.uuidString, coordinate: $0.coordinate, sources: [$0])
            }
        }

        var buckets: [String: [WaterSource]] = [:]
        for source in sources {
            let gx = Int((source.coordinate.longitude / cellSizeDegrees).rounded(.down))
            let gy = Int((source.coordinate.latitude / cellSizeDegrees).rounded(.down))
            buckets["\(gx):\(gy)", default: []].append(source)
        }

        return buckets.map { key, group in
            let avgLat = group.reduce(0) { $0 + $1.coordinate.latitude } / Double(group.count)
            let avgLon = group.reduce(0) { $0 + $1.coordinate.longitude } / Double(group.count)
            return MapCluster(
                id: key,
                coordinate: Coordinate(latitude: avgLat, longitude: avgLon),
                sources: group
            )
        }
    }
}
