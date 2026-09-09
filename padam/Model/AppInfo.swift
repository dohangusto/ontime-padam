//
//  AppInfo.swift
//  padam
//
//  Static app-level facts. Centralized so the data attribution is written once.
//

import Foundation

enum AppInfo {
    /// Must be shown somewhere visible in the app.
    static let dataAttribution = "Data: PemKot DKI Jakarta, 2024"
    static let accessibilityLocaleIdentifier = "id_ID"
}

enum AccessibilityText {
    static func coordinate(_ coordinate: Coordinate) -> String {
        let latitude = coordinate.latitude.formatted(.number.precision(.fractionLength(5)))
        let longitude = coordinate.longitude.formatted(.number.precision(.fractionLength(5)))
        return "Lintang \(latitude), bujur \(longitude)"
    }

    static func waterSource(_ source: WaterSource, distanceMeters: Double? = nil) -> String {
        var parts = [source.type.displayName, source.name]

        if !source.address.isEmpty {
            parts.append(source.address)
        }

        if let distanceMeters {
            parts.append("Jarak \(DistanceFormat.string(distanceMeters))")
        }

        if let kondisi = source.kondisi?.trimmingCharacters(in: .whitespacesAndNewlines), !kondisi.isEmpty {
            parts.append("Kondisi \(kondisi.capitalized)")
        }

        if source.type.isLowReliability {
            parts.append("Keandalan rendah")
        }

        return parts.joined(separator: ", ")
    }

    static func rankedSource(_ ranked: RankedWaterSource) -> String {
        var parts = [waterSource(ranked.source, distanceMeters: ranked.distanceMeters)]

        if ranked.isFar {
            parts.append("Titik ini jauh, lebih dari 3 kilometer")
        }

        return parts.joined(separator: ", ")
    }

    static func recentSearch(_ recent: RecentSearch) -> String {
        if recent.subtitle.isEmpty {
            return recent.title
        }

        return "\(recent.title), \(recent.subtitle)"
    }
}
