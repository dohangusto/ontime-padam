//
//  ConditionState.swift
//  padam
//
//  Single source of truth for turning a raw `kondisi` field into a meaning the
//  rest of the app can reason about. This is deliberately the ONLY place the
//  string → state mapping happens: colors, icons, ranking and copy all derive
//  from this enum so an unusable point can never accidentally read as "safe".
//
//  Pure Foundation (no SwiftUI) so it stays unit-testable. The visual mapping
//  (color/symbol) lives in the View layer — see WaterSourceStyle.swift.
//

import Foundation

/// The usability of a specific water-source point, derived from its recorded
/// field condition. Distinct from *type-level* reliability (e.g. hydrants as a
/// category) — the two signals must never be conflated.
enum ConditionState: Sendable, Hashable {
    /// Recorded as working (e.g. "BISA DIGUNAKAN", "BAIK").
    case usable
    /// No condition recorded, blank, or ambiguous/mixed. The safe default —
    /// we never upgrade an unknown to "usable".
    case unknown
    /// Recorded as not working (e.g. "TIDAK BISA DIGUNAKAN", "RUSAK").
    case unusable

    init(kondisi: String? = nil) {
        self = Self.classify(kondisi)
    }

    /// Classifies a raw `kondisi` string. Missing, blank or unrecognised values
    /// resolve to `.unknown` — never to `.usable`.
    static func classify(_ raw: String?) -> ConditionState {
        guard let raw else { return .unknown }
        // Some records combine states with a pipe, e.g. "BAIK | RUSAK".
        let tokens = raw
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return .unknown }

        var hasUsable = false
        var hasUnusable = false
        var hasUnrecognised = false
        for token in tokens {
            switch token {
            case "BISA DIGUNAKAN", "BAIK":
                hasUsable = true
            case "TIDAK BISA DIGUNAKAN", "RUSAK":
                hasUnusable = true
            default:
                hasUnrecognised = true
            }
        }

        // Anything ambiguous — an unrecognised token, or a mix of working and
        // broken — is treated as unknown rather than guessed either way.
        if hasUnrecognised { return .unknown }
        if hasUsable && hasUnusable { return .unknown }
        if hasUnusable { return .unusable }
        if hasUsable { return .usable }
        return .unknown
    }

    /// True when this point may be offered as an option. Unusable points are
    /// excluded from recommendations and ranking candidates.
    var isCandidate: Bool { self != .unusable }

    /// Short Indonesian label for the state. Single-word / concise standard
    /// terms for Indonesian infrastructure that fit narrow column displays.
    var label: String {
        switch self {
        case .usable: return "Aktif"
        case .unknown: return "Tak diketahui"
        case .unusable: return "Rusak"
        }
    }
}
