//
//  WaterSourceType.swift
//  padam
//
//  The five categories of water sources the app models. Two of them
//  (kali/sungai, got, kolam renang) have no bundled data yet and must
//  render gracefully as empty groups — never hidden from the type system.
//

import Foundation

enum WaterSourceType: String, CaseIterable, Identifiable, Codable, Sendable {
    case kali          // rivers / sungai
    case got           // drains
    case kolamRenang   // swimming pools
    case posDamkar     // fire stations
    case hidran        // hydrants

    var id: String { rawValue }

    /// Reliability ranking (NOT a user preference). Lower value = higher reliability.
    /// Rivers rank highest (effectively unlimited volume); hydrants rank lowest
    /// (many in Jakarta are damaged or low-flow). Distance must never override this.
    var reliabilityPriority: Int {
        switch self {
        case .kali: return 0
        case .got: return 1
        case .kolamRenang: return 2
        case .posDamkar: return 3
        case .hidran: return 4
        }
    }

    /// All types ordered by reliability priority (highest reliability first):
    /// kali → got → kolam renang → pos damkar → hidran.
    static var reliabilityOrdered: [WaterSourceType] {
        allCases.sorted { $0.reliabilityPriority < $1.reliabilityPriority }
    }

    /// Hydrants are always treated as low reliability.
    var isLowReliability: Bool { self == .hidran }

    var displayName: String {
        switch self {
        case .kali: return "Sungai"
        case .got: return "Got"
        case .kolamRenang: return "Kolam Renang"
        case .posDamkar: return "Pos DAMKAR"
        case .hidran: return "Hidran"
        }
    }

    /// Centralized SF Symbol placeholder. Custom icons will replace these later;
    /// keeping the reference in one place makes swapping trivial.
    var symbolName: String {
        switch self {
        case .kali: return "water.waves"
        case .got: return "drop.degreesign"
        case .kolamRenang: return "figure.pool.swim"
        case .posDamkar: return "building.2.fill"
        case .hidran: return "fire.extinguisher.fill"
        }
    }

    /// Maximum longitude span delta at which this type becomes visible during map browsing.
    /// Priority order from most zoomed out to closest: Pos DAMKAR (any) > Sungai (0.16) > Kolam/Got (0.08) > Hidran (0.04).
    var maxVisibleLongitudeSpan: Double {
        switch self {
        case .posDamkar: return .infinity
        case .kali: return 0.16
        case .got: return 0.08
        case .kolamRenang: return 0.08
        case .hidran: return 0.04
        }
    }

    /// True if this water source type should be visible for the given map longitude span.
    func isVisible(atLongitudeSpan span: Double) -> Bool {
        span <= maxVisibleLongitudeSpan
    }
}
