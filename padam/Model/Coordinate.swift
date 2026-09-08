//
//  Coordinate.swift
//  padam
//
//  A lightweight, dependency-free geographic coordinate used by the ranking
//  logic so that ranking stays pure Swift/Foundation and fully unit-testable
//  without importing MapKit/CoreLocation.
//

import Foundation

struct Coordinate: Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Whether the coordinate is usable. Rejects non-finite values, out-of-range
    /// values, and the null-island (0, 0) point that usually indicates missing data.
    /// We never fabricate a location, so invalid coordinates are dropped upstream.
    var isValid: Bool {
        guard latitude.isFinite, longitude.isFinite else { return false }
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else { return false }
        if latitude == 0 && longitude == 0 { return false }
        return true
    }

    /// Straight-line (great-circle) distance in meters using the Haversine formula.
    func distance(to other: Coordinate) -> Double {
        let earthRadius = 6_371_000.0 // meters
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}
