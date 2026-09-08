//
//  CoordinateTests.swift
//  padamTests
//
//  Sanity checks for the pure Haversine distance and coordinate validation.
//

import Testing
import Foundation
@testable import padam

@MainActor
struct CoordinateTests {

    @Test("Distance to self is zero")
    func zeroDistance() {
        let c = Coordinate(latitude: -6.2, longitude: 106.8)
        #expect(c.distance(to: c) == 0)
    }

    @Test("One degree of latitude is roughly 111 km")
    func oneDegreeLatitude() {
        let a = Coordinate(latitude: -6.0, longitude: 106.8)
        let b = Coordinate(latitude: -7.0, longitude: 106.8)
        let d = a.distance(to: b)
        #expect(abs(d - 111_000) < 1_500) // within ~1.5 km tolerance
    }

    @Test("Validation rejects null-island, non-finite, and out-of-range values")
    func validation() {
        #expect(Coordinate(latitude: -6.2, longitude: 106.8).isValid)
        #expect(!Coordinate(latitude: 0, longitude: 0).isValid)
        #expect(!Coordinate(latitude: .nan, longitude: 106.8).isValid)
        #expect(!Coordinate(latitude: 91, longitude: 106.8).isValid)
        #expect(!Coordinate(latitude: -6.2, longitude: 181).isValid)
    }
}
