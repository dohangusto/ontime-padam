//
//  WaterSourceStyle.swift
//  padam
//
//  Centralized visual styling for water-source types and ranking markers, so
//  colors/icons/labels are defined once and stay consistent across the map and
//  the sheet. Icons are SF Symbol placeholders (see WaterSourceType.symbolName).
//

import SwiftUI

extension WaterSourceType {
    /// Tint used for pins and badges. Distinct per type so the operator can tell
    /// them apart at a glance; hydrants deliberately use a cautionary tone.
    var tint: Color {
        switch self {
        case .kali: return .blue
        case .got: return .teal
        case .kolamRenang: return .cyan
        case .posDamkar: return .gray
        case .hidran: return .orange
        }
    }
}

extension ConditionState {
    /// Semantic tint. Bound to *meaning*: green only ever means usable, red means
    /// unusable, amber means unverified. Never wire a status color at a call site.
    var tint: Color {
        switch self {
        case .usable: return .green
        case .unknown: return .secondary
        case .unusable: return .red
        }
    }

    /// Paired icon so the state is never conveyed by color alone (colorblind /
    /// glanceability). A checkmark for safe, a question for unknown, a warning
    /// triangle for unusable.
    var symbolName: String {
        switch self {
        case .usable: return "checkmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        case .unusable: return "exclamationmark.triangle.fill"
        }
    }
}

/// Formats a straight-line distance for the radio-facing UI.
enum DistanceFormat {
    static func string(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }
}
