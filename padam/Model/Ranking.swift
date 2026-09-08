//
//  Ranking.swift
//  padam
//
//  Core ranking logic, deliberately kept out of any ViewModel so it can be
//  unit-tested without touching UI. Pure Swift/Foundation — no MapKit.
//
//  Ranking rule (implemented exactly):
//    1. For each of the 5 types, classify points by condition:
//         usable / unknown / unusable  (see ConditionState).
//    2. Take the 3 nearest points per type from {usable, unknown} only.
//       Unusable points are collected separately, never ranked as options.
//    3. Group by type, ordered by reliability priority:
//         kali → got → kolam renang → pos damkar → hidran
//    4. Within each group, sort by distance (nearest first). Where distance is
//       close (within `distanceTieToleranceMeters`), prefer usable over unknown.
//    5. Mark any point beyond 3 km as "far".
//    6. Mark all hydrants as "low reliability" (type-level), independent of the
//       per-point condition above.
//
//  Note the two distinct reliability signals, which callers must not conflate:
//    - Type-level reliability  (isLowReliability) — hydrants as a category.
//    - Point-level condition   (condition)        — this specific point.
//

import Foundation

/// A water source paired with its straight-line distance from the fire location,
/// plus the display markers the results screen relies on.
struct RankedWaterSource: Identifiable, Hashable, Sendable {
    let source: WaterSource
    let distanceMeters: Double

    var id: UUID { source.id }
    var type: WaterSourceType { source.type }

    /// Per-point usability, classified from the raw `kondisi` field in one place.
    var condition: ConditionState { ConditionState.classify(source.kondisi) }

    /// Display marker only — "far" points are NEVER filtered out.
    var isFar: Bool { distanceMeters > RankingService.farThresholdMeters }

    /// Type-level signal: all hydrants are low reliability regardless of distance
    /// or condition. Distinct from `condition`.
    var isLowReliability: Bool { source.type.isLowReliability }
}

/// One type's results. Always present for all five types, even when empty.
struct RankedGroup: Identifiable, Sendable {
    let type: WaterSourceType
    /// The ranked options: nearest usable/unknown points, capped at `maxPerType`.
    let sources: [RankedWaterSource]
    /// Points recorded as unusable — shown for reference (so operators don't
    /// re-check a dead hydrant) but never offered as an option.
    let unusable: [RankedWaterSource]

    init(type: WaterSourceType, sources: [RankedWaterSource], unusable: [RankedWaterSource] = []) {
        self.type = type
        self.sources = sources
        self.unusable = unusable
    }

    var id: WaterSourceType { type }

    /// Empty of *usable options*. There may still be unusable points on record.
    var isEmpty: Bool { sources.isEmpty }

    var hasUnusable: Bool { !unusable.isEmpty }
}

enum RankingService {
    /// Distance beyond which a point is marked "far". Display marker, not a filter.
    static let farThresholdMeters: Double = 3_000

    /// Maximum points returned per type.
    static let maxPerType = 3

    /// Distance window (metres) within which two candidates are considered "close"
    /// enough that a usable point is preferred over an unknown one.
    static let distanceTieToleranceMeters: Double = 100

    /// Ranks all water sources relative to a fire location.
    ///
    /// Returns exactly five groups in reliability order. Within each group the
    /// nearest `maxPerType` usable/unknown sources are returned; unusable points
    /// are separated out. Distance never reorders the groups themselves.
    static func rank(sources: [WaterSource], from origin: Coordinate) -> [RankedGroup] {
        // Group once, then assemble in reliability order so distance can never
        // override type priority.
        let byType = Dictionary(grouping: sources, by: \.type)

        return WaterSourceType.reliabilityOrdered.map { type in
            let ranked = (byType[type] ?? [])
                .map { RankedWaterSource(source: $0, distanceMeters: origin.distance(to: $0.coordinate)) }

            // Unusable points are collected for reference, sorted nearest-first,
            // but never enter the ranked options.
            let unusable = ranked
                .filter { $0.condition == .unusable }
                .sorted { $0.distanceMeters < $1.distanceMeters }

            // Candidates = usable + unknown. Sorted nearest-first, with usable
            // preferred over unknown when distances are close.
            let candidates = ranked
                .filter { $0.condition.isCandidate }
                .sorted(by: candidateOrder)
                .prefix(maxPerType)

            return RankedGroup(type: type, sources: Array(candidates), unusable: unusable)
        }
    }

    /// Strict weak ordering for candidates: nearest first, but within a distance
    /// tolerance bucket a usable point outranks an unknown one. Bucketing keeps
    /// the comparator transitive (a plain "close" check would not be).
    private static func candidateOrder(_ a: RankedWaterSource, _ b: RankedWaterSource) -> Bool {
        let bucketA = (a.distanceMeters / distanceTieToleranceMeters).rounded(.down)
        let bucketB = (b.distanceMeters / distanceTieToleranceMeters).rounded(.down)
        if bucketA != bucketB { return bucketA < bucketB }

        let priorityA = a.condition == .usable ? 0 : 1
        let priorityB = b.condition == .usable ? 0 : 1
        if priorityA != priorityB { return priorityA < priorityB }

        return a.distanceMeters < b.distanceMeters
    }
}
