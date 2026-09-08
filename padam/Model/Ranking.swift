//
//  Ranking.swift
//  padam
//
//  Core ranking logic, deliberately kept out of any ViewModel so it can be
//  unit-tested without touching UI. Pure Swift/Foundation — no MapKit.
//
//  Ranking rule (implemented exactly):
//    1. Take the 3 nearest points for EACH of the 5 types. No radius filter —
//       always return 3 per type if 3 exist.
//    2. Group by type, ordered by reliability priority:
//         kali → got → kolam renang → pos damkar → hidran
//    3. Within each group, sort by distance (nearest first).
//    4. Mark any point beyond 3 km as "far".
//    5. Mark all hydrants as "low reliability".
//

import Foundation

/// A water source paired with its straight-line distance from the fire location,
/// plus the display markers the results screen relies on.
struct RankedWaterSource: Identifiable, Hashable, Sendable {
    let source: WaterSource
    let distanceMeters: Double

    var id: UUID { source.id }
    var type: WaterSourceType { source.type }

    /// Display marker only — "far" points are NEVER filtered out.
    var isFar: Bool { distanceMeters > RankingService.farThresholdMeters }

    /// All hydrants are low reliability, regardless of distance or condition.
    var isLowReliability: Bool { source.type.isLowReliability }
}

/// One type's results. Always present for all five types, even when empty.
struct RankedGroup: Identifiable, Sendable {
    let type: WaterSourceType
    let sources: [RankedWaterSource]

    var id: WaterSourceType { type }
    var isEmpty: Bool { sources.isEmpty }
}

enum RankingService {
    /// Distance beyond which a point is marked "far". Display marker, not a filter.
    static let farThresholdMeters: Double = 3_000

    /// Maximum points returned per type.
    static let maxPerType = 3

    /// Ranks all water sources relative to a fire location.
    ///
    /// Returns exactly five groups in reliability order. Within each group the
    /// nearest `maxPerType` sources are returned, sorted nearest-first. Distance
    /// never reorders the groups themselves.
    static func rank(sources: [WaterSource], from origin: Coordinate) -> [RankedGroup] {
        // Group once, then assemble in reliability order so distance can never
        // override type priority.
        let byType = Dictionary(grouping: sources, by: \.type)

        return WaterSourceType.reliabilityOrdered.map { type in
            let ranked = (byType[type] ?? [])
                .map { RankedWaterSource(source: $0, distanceMeters: origin.distance(to: $0.coordinate)) }
                .sorted { $0.distanceMeters < $1.distanceMeters }
                .prefix(maxPerType)
            return RankedGroup(type: type, sources: Array(ranked))
        }
    }
}
