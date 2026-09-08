//
//  MapClusteringTests.swift
//  padamTests
//
//  Verifies zoom-based aggregation: fine zoom keeps points separate, coarse zoom
//  merges nearby points, and cell size scales with the visible span.
//

import Testing
import Foundation
@testable import padam

@MainActor
struct MapClusteringTests {

    private func source(lat: Double, lon: Double) -> WaterSource {
        WaterSource(type: .hidran, name: "H", address: "a",
                    coordinate: Coordinate(latitude: lat, longitude: lon))
    }

    @Test("Cell size zero (fully zoomed in) makes every point its own pin")
    func zeroCellSizeAllSingles() {
        let sources = [source(lat: -6.20, lon: 106.80), source(lat: -6.2001, lon: 106.8001)]
        let clusters = MapClustering.cluster(sources, cellSizeDegrees: 0)
        #expect(clusters.count == 2)
        #expect(clusters.allSatisfy { !$0.isCluster })
    }

    @Test("Nearby points merge into one cluster at coarse cell size")
    func nearbyPointsMerge() {
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

    @Test("Distant points stay in separate cells")
    func distantPointsSeparate() {
        let sources = [source(lat: -6.20, lon: 106.80), source(lat: -6.40, lon: 107.00)]
        let clusters = MapClustering.cluster(sources, cellSizeDegrees: 0.05)
        #expect(clusters.count == 2)
    }

    @Test("Cell size grows with the visible span (more aggregation when zoomed out)")
    func cellSizeScalesWithSpan() {
        let zoomedIn = MapClustering.cellSize(forLongitudeSpan: 0.02)
        let zoomedOut = MapClustering.cellSize(forLongitudeSpan: 0.5)
        #expect(zoomedOut > zoomedIn)
        #expect(MapClustering.cellSize(forLongitudeSpan: 0) == 0)
    }

    @Test("Cluster coordinate is the average of its members")
    func clusterCoordinateIsAverage() {
        let sources = [source(lat: -6.20, lon: 106.80), source(lat: -6.30, lon: 106.90)]
        let cluster = MapClustering.cluster(sources, cellSizeDegrees: 1.0).first { $0.isCluster }
        #expect(cluster != nil)
        #expect(abs(cluster!.coordinate.latitude - (-6.25)) < 0.0001)
        #expect(abs(cluster!.coordinate.longitude - 106.85) < 0.0001)
    }
}
