//
//  RankingServiceTests.swift
//  padamTests
//
//  Verifies the core ranking rule exactly: correct ordering, fewer than 3
//  points, zero points of a type, points far outside the radius, and duplicate
//  coordinates.
//

import Testing
import Foundation
@testable import padam

@MainActor
struct RankingServiceTests {

    /// Jakarta-ish reference origin used across tests.
    let origin = Coordinate(latitude: -6.2000, longitude: 106.8000)

    /// Builds a source at an east offset (in degrees) from the origin so that a
    /// larger offset means a larger distance — handy for predictable ordering.
    func source(_ type: WaterSourceType, eastOffset: Double, name: String = "S") -> WaterSource {
        WaterSource(
            type: type,
            name: name,
            address: "addr",
            coordinate: Coordinate(latitude: origin.latitude, longitude: origin.longitude + eastOffset)
        )
    }

    @Test("Always returns exactly five groups in reliability order")
    func fiveGroupsInReliabilityOrder() {
        let result = RankingService.rank(sources: [], from: origin)
        #expect(result.count == 5)
        #expect(result.map(\.type) == [.kali, .got, .kolamRenang, .posDamkar, .hidran])
    }

    @Test("Type order is never overridden by distance")
    func typeOrderBeatsDistance() {
        // A hydrant sits right on the origin (0 m); a river is far away (~11 km).
        let sources = [
            source(.hidran, eastOffset: 0.0),
            source(.kali, eastOffset: 0.1)
        ]
        let result = RankingService.rank(sources: sources, from: origin)

        // Despite the hydrant being nearest, the river group still comes first.
        #expect(result.first?.type == .kali)
        #expect(result.first?.sources.first?.source.type == .kali)
        #expect(result.last?.type == .hidran)
    }

    @Test("Returns the 3 nearest per type, nearest first")
    func threeNearestPerTypeSorted() {
        let sources = [
            source(.posDamkar, eastOffset: 0.04, name: "D4"),
            source(.posDamkar, eastOffset: 0.01, name: "D1"),
            source(.posDamkar, eastOffset: 0.03, name: "D3"),
            source(.posDamkar, eastOffset: 0.02, name: "D2")
        ]
        let group = RankingService.rank(sources: sources, from: origin)
            .first { $0.type == .posDamkar }!

        #expect(group.sources.count == 3)
        #expect(group.sources.map(\.source.name) == ["D1", "D2", "D3"]) // D4 dropped, sorted
        // Distances must be non-decreasing.
        let distances = group.sources.map(\.distanceMeters)
        #expect(distances == distances.sorted())
    }

    @Test("Fewer than 3 points available returns all of them")
    func fewerThanThree() {
        let sources = [
            source(.posDamkar, eastOffset: 0.02, name: "D2"),
            source(.posDamkar, eastOffset: 0.01, name: "D1")
        ]
        let group = RankingService.rank(sources: sources, from: origin)
            .first { $0.type == .posDamkar }!
        #expect(group.sources.count == 2)
        #expect(group.sources.map(\.source.name) == ["D1", "D2"])
    }

    @Test("Zero points of a type yields an empty (but present) group")
    func zeroPointsOfType() {
        let sources = [source(.hidran, eastOffset: 0.01)]
        let result = RankingService.rank(sources: sources, from: origin)

        let kali = result.first { $0.type == .kali }!
        #expect(kali.isEmpty)
        #expect(kali.sources.isEmpty)
        // The missing types are still represented.
        #expect(result.contains { $0.type == .got })
        #expect(result.contains { $0.type == .kolamRenang })
    }

    @Test("Points beyond 3 km are still returned and marked far")
    func farPointsReturnedAndMarked() {
        // ~0.05 deg east ≈ 5.5 km (far); ~0.01 deg east ≈ 1.1 km (near).
        let sources = [
            source(.kali, eastOffset: 0.05, name: "Far"),
            source(.kali, eastOffset: 0.01, name: "Near")
        ]
        let group = RankingService.rank(sources: sources, from: origin)
            .first { $0.type == .kali }!

        #expect(group.sources.count == 2) // no radius filtering
        let near = group.sources.first { $0.source.name == "Near" }!
        let far = group.sources.first { $0.source.name == "Far" }!
        #expect(near.isFar == false)
        #expect(far.isFar == true)
    }

    @Test("All hydrants are marked low reliability; other types are not")
    func hydrantsLowReliability() {
        let sources = [
            source(.hidran, eastOffset: 0.01),
            source(.kali, eastOffset: 0.01),
            source(.posDamkar, eastOffset: 0.01)
        ]
        let result = RankingService.rank(sources: sources, from: origin)

        for group in result {
            for ranked in group.sources {
                #expect(ranked.isLowReliability == (group.type == .hidran))
            }
        }
    }

    @Test("Duplicate coordinates are both retained")
    func duplicateCoordinates() {
        let sources = [
            source(.got, eastOffset: 0.01, name: "A"),
            source(.got, eastOffset: 0.01, name: "B")
        ]
        let group = RankingService.rank(sources: sources, from: origin)
            .first { $0.type == .got }!
        #expect(group.sources.count == 2)
        #expect(group.sources.allSatisfy { $0.distanceMeters == group.sources[0].distanceMeters })
    }
}
