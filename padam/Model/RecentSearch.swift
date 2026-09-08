//
//  RecentSearch.swift
//  padam
//
//  Model representing recent searches and search history in the Apple Maps style sheet.
//

import SwiftUI
import Foundation

struct RecentSearch: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
    let coordinate: Coordinate
    let iconSystemName: String
    let iconTintName: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        coordinate: Coordinate,
        iconSystemName: String = "magnifyingglass",
        iconTintName: String = "gray",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.iconSystemName = iconSystemName
        self.iconTintName = iconTintName
        self.timestamp = timestamp
    }

    var iconTint: Color {
        switch iconTintName {
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        case "green": return .green
        case "teal": return .teal
        case "purple": return .purple
        default: return .secondary
        }
    }

    /// Realistic initial sample items matching the reference screenshot (IMG_4788 / IMG_4789).
    static let defaults: [RecentSearch] = [
        RecentSearch(
            title: "National Monument",
            subtitle: "Central Jakarta",
            coordinate: Coordinate(latitude: -6.175392, longitude: 106.827153),
            iconSystemName: "star.fill",
            iconTintName: "blue"
        ),
        RecentSearch(
            title: "Thamrin City",
            subtitle: "Jl. Thamrin Boulevard, Central Jakarta",
            coordinate: Coordinate(latitude: -6.1950, longitude: 106.8190),
            iconSystemName: "bag.fill",
            iconTintName: "yellow"
        ),
        RecentSearch(
            title: "Thamrin Residence",
            subtitle: "Central Jakarta",
            coordinate: Coordinate(latitude: -6.1970, longitude: 106.8185),
            iconSystemName: "magnifyingglass",
            iconTintName: "gray"
        )
    ]
}
