//
//  MapClusteringTests.swift
//  padamTests
//
//  Verifies tiered pin visibility by zoom level (Pos DAMKAR > Sungai > Kolam Renang > Hidran),
//  dominant type calculations, and pin rendering.
//

import Testing
import Foundation
@testable import padam

@MainActor
struct MapClusteringTests {

    private func source(
        type: WaterSourceType = .hidran,
        name: String = "S",
        lat: Double = -6.20,
        lon: Double = 106.80
    ) -> WaterSource {
        WaterSource(
            type: type,
            name: name,
            address: "addr",
            coordinate: Coordinate(latitude: lat, longitude: lon)
        )
    }

    @Test("Zoomed out furthest (city overview) shows only Pos DAMKAR")
    func furthestZoomShowsOnlyPosDamkar() {
        let sources = [
            source(type: .posDamkar, name: "Pos 1"),
            source(type: .kali, name: "Sungai 1"),
            source(type: .kolamRenang, name: "Kolam 1"),
            source(type: .hidran, name: "Hidran 1")
        ]

        let clusters = MapClustering.cluster(sources, longitudeDelta: 0.30)
        #expect(clusters.count == 1)
        #expect(clusters[0].singleSource?.type == .posDamkar)
    }

    @Test("Mid-zoom reveals Sungai alongside Pos DAMKAR")
    func midZoomRevealsSungai() {
        let sources = [
            source(type: .posDamkar, name: "Pos 1"),
            source(type: .kali, name: "Sungai 1"),
            source(type: .kolamRenang, name: "Kolam 1"),
            source(type: .hidran, name: "Hidran 1")
        ]

        let clusters = MapClustering.cluster(sources, longitudeDelta: 0.12)
        #expect(clusters.count == 2)
        let types = Set(clusters.compactMap { $0.singleSource?.type })
        #expect(types == [.posDamkar, .kali])
    }

    @Test("Closer zoom reveals Kolam Renang")
    func closerZoomRevealsKolamRenang() {
        let sources = [
            source(type: .posDamkar, name: "Pos 1"),
            source(type: .kali, name: "Sungai 1"),
            source(type: .kolamRenang, name: "Kolam 1"),
            source(type: .hidran, name: "Hidran 1")
        ]

        let clusters = MapClustering.cluster(sources, longitudeDelta: 0.06)
        #expect(clusters.count == 3)
        let types = Set(clusters.compactMap { $0.singleSource?.type })
        #expect(types == [.posDamkar, .kali, .kolamRenang])
    }

    @Test("Zoomed in close reveals all pins including Hidran")
    func zoomedInRevealsAllPins() {
        let sources = [
            source(type: .posDamkar, name: "Pos 1"),
            source(type: .kali, name: "Sungai 1"),
            source(type: .kolamRenang, name: "Kolam 1"),
            source(type: .hidran, name: "Hidran 1")
        ]

        let clusters = MapClustering.cluster(sources, longitudeDelta: 0.03)
        #expect(clusters.count == 4)
        let types = Set(clusters.compactMap { $0.singleSource?.type })
        #expect(types == [.posDamkar, .kali, .kolamRenang, .hidran])
    }

    @Test("Dominant type is correctly identified in clusters")
    func dominantTypeCalculation() {
        let sources = [
            source(type: .hidran, lat: -6.190, lon: 106.850),
            source(type: .hidran, lat: -6.191, lon: 106.851),
            source(type: .posDamkar, lat: -6.192, lon: 106.852)
        ]

        let cluster = MapCluster(id: "c1", coordinate: Coordinate(latitude: -6.191, longitude: 106.851), sources: sources)
        #expect(cluster.dominantType == .hidran)
        #expect(cluster.count == 3)
    }

    @Test("Dominant type tie-breaker prioritizes higher reliability type")
    func dominantTypeTieBreaker() {
        // Equal counts: 1 pos damkar vs 1 hidran -> pos damkar has higher reliability priority
        let sources = [
            source(type: .hidran, lat: -6.190, lon: 106.850),
            source(type: .posDamkar, lat: -6.191, lon: 106.851)
        ]

        let cluster = MapCluster(id: "c2", coordinate: Coordinate(latitude: -6.190, longitude: 106.850), sources: sources)
        #expect(cluster.dominantType == .posDamkar)
    }

    @Test("Legacy grid clustering produces expected cluster counts")
    func legacyGridClustering() {
        let sources = [
            source(lat: -6.201, lon: 106.801),
            source(lat: -6.202, lon: 106.802),
            source(lat: -6.203, lon: 106.803)
        ]
        let clusters = MapClustering.cluster(sources, cellSizeDegrees: 0.05)
        #expect(clusters.count == 1)
        #expect(clusters[0].isCluster)
        #expect(clusters[0].count == 3)
    }
}
