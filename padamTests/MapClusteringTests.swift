//
//  MapClusteringTests.swift
//  padamTests
//
//  Verifies the 4-tier administrative clustering hierarchy from zoom out to zoom in:
//  1. Cluster berdasarkan wilayah (zoom out)
//  2. Cluster berdasarkan kecamatan
//  3. Cluster berdasarkan kelurahan
//  4. Tampilkan semuanya (zoom in)
//

import Testing
import Foundation
@testable import padam

@MainActor
struct MapClusteringTests {

    private func source(
        type: WaterSourceType = .hidran,
        name: String = "S",
        address: String = "Jl. Merdeka",
        lat: Double = -6.20,
        lon: Double = 106.80,
        wilayah: String? = nil,
        kecamatan: String? = nil,
        kelurahan: String? = nil
    ) -> WaterSource {
        WaterSource(
            type: type,
            name: name,
            address: address,
            coordinate: Coordinate(latitude: lat, longitude: lon),
            wilayah: wilayah,
            kecamatan: kecamatan,
            kelurahan: kelurahan
        )
    }

    // MARK: - Idle / Initial App State Tests (Tiered Visibility by Type)

    @Test("Idle: Zoomed out furthest (city overview) shows only Pos DAMKAR")
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

    @Test("Idle: Mid-zoom reveals Sungai alongside Pos DAMKAR")
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

    @Test("Idle: Closer zoom reveals Kolam Renang")
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

    @Test("Idle: Zoomed in close reveals all pins including Hidran")
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

    // MARK: - Category Browsing Tests (4-Tier Administrative Hierarchy)

    @Test("Tier identification maps longitudeDelta to correct administrative tier")
    func tierIdentification() {
        #expect(MapClustering.tier(forLongitudeDelta: 0.42) == .wilayah)
        #expect(MapClustering.tier(forLongitudeDelta: 0.25) == .wilayah)
        #expect(MapClustering.tier(forLongitudeDelta: 0.15) == .kecamatan)
        #expect(MapClustering.tier(forLongitudeDelta: 0.08) == .kecamatan)
        #expect(MapClustering.tier(forLongitudeDelta: 0.05) == .kelurahan)
        #expect(MapClustering.tier(forLongitudeDelta: 0.025) == .kelurahan)
        #expect(MapClustering.tier(forLongitudeDelta: 0.015) == .individual)
        #expect(MapClustering.tier(forLongitudeDelta: 0.005) == .individual)
    }

    @Test("Category: Tier 1 zoomed out clusters by Wilayah")
    func tier1WilayahClustering() {
        let sources = [
            source(type: .hidran, name: "H1", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Kebon Kelapa"),
            source(type: .hidran, name: "H2", wilayah: "Jakarta Pusat", kecamatan: "Menteng", kelurahan: "Cikini"),
            source(type: .hidran, name: "H3", wilayah: "Jakarta Selatan", kecamatan: "Tebet", kelurahan: "Tebet Barat"),
            source(type: .hidran, name: "H4", wilayah: "Jakarta Selatan", kecamatan: "Tebet", kelurahan: "Tebet Timur")
        ]

        let clusters = MapClustering.clusterCategory(sources, longitudeDelta: 0.30)
        #expect(clusters.count == 2)

        let titles = Set(clusters.compactMap { $0.title })
        #expect(titles.contains("Jakarta Pusat"))
        #expect(titles.contains("Jakarta Selatan"))

        let pusatCluster = clusters.first { $0.title == "Jakarta Pusat" }
        #expect(pusatCluster?.count == 2)
        #expect(pusatCluster?.isCluster == true)

        let selatanCluster = clusters.first { $0.title == "Jakarta Selatan" }
        #expect(selatanCluster?.count == 2)
        #expect(selatanCluster?.isCluster == true)
    }

    @Test("Category: Tier 2 medium zoom clusters by Kecamatan")
    func tier2KecamatanClustering() {
        let sources = [
            source(type: .hidran, name: "H1", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Kebon Kelapa"),
            source(type: .hidran, name: "H2", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Petojo Selatan"),
            source(type: .hidran, name: "H3", wilayah: "Jakarta Pusat", kecamatan: "Menteng", kelurahan: "Cikini"),
            source(type: .hidran, name: "H4", wilayah: "Jakarta Pusat", kecamatan: "Menteng", kelurahan: "Gondangdia")
        ]

        let clusters = MapClustering.clusterCategory(sources, longitudeDelta: 0.12)
        #expect(clusters.count == 2)

        let titles = Set(clusters.compactMap { $0.title })
        #expect(titles.contains("Gambir"))
        #expect(titles.contains("Menteng"))

        let gambirCluster = clusters.first { $0.title == "Gambir" }
        #expect(gambirCluster?.count == 2)
        #expect(gambirCluster?.isCluster == true)
    }

    @Test("Category: Tier 3 close zoom clusters by Kelurahan")
    func tier3KelurahanClustering() {
        let sources = [
            source(type: .hidran, name: "H1", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Kebon Kelapa"),
            source(type: .hidran, name: "H2", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Kebon Kelapa"),
            source(type: .hidran, name: "H3", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Petojo Selatan"),
            source(type: .hidran, name: "H4", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Petojo Selatan")
        ]

        let clusters = MapClustering.clusterCategory(sources, longitudeDelta: 0.05)
        #expect(clusters.count == 2)

        let titles = Set(clusters.compactMap { $0.title })
        #expect(titles.contains("Kebon Kelapa"))
        #expect(titles.contains("Petojo Selatan"))

        let kelapaCluster = clusters.first { $0.title == "Kebon Kelapa" }
        #expect(kelapaCluster?.count == 2)
        #expect(kelapaCluster?.isCluster == true)
    }

    @Test("Category: Tier 4 zoom in reveals all individual pins")
    func tier4IndividualPins() {
        let sources = [
            source(type: .hidran, name: "H1", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Kebon Kelapa"),
            source(type: .hidran, name: "H2", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Kebon Kelapa"),
            source(type: .hidran, name: "H3", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Petojo Selatan")
        ]

        let clusters = MapClustering.clusterCategory(sources, longitudeDelta: 0.015)
        #expect(clusters.count == 3)
        #expect(clusters.allSatisfy { !$0.isCluster && $0.count == 1 })
    }

    @Test("Category: Single item in an administrative area renders as an individual pin")
    func singleItemRendersAsPin() {
        let sources = [
            source(type: .posDamkar, name: "Pos Gambir", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Gambir"),
            source(type: .kali, name: "Sungai Ciliwung", wilayah: "Jakarta Selatan", kecamatan: "Tebet", kelurahan: "Tebet Barat")
        ]

        // At Wilayah tier: each Wilayah has 1 item, so each renders as a single-pin cluster
        let clusters = MapClustering.clusterCategory(sources, longitudeDelta: 0.30)
        #expect(clusters.count == 2)
        #expect(clusters.allSatisfy { !$0.isCluster })
        #expect(clusters.contains { $0.singleSource?.name == "Pos Gambir" })
        #expect(clusters.contains { $0.singleSource?.name == "Sungai Ciliwung" })
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

    @Test("clusterCategory follows the same 4-tier administrative hierarchy")
    func clusterCategoryHierarchy() {
        let rivers = [
            source(type: .kali, name: "Sungai 1", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Kebon Kelapa"),
            source(type: .kali, name: "Sungai 2", wilayah: "Jakarta Pusat", kecamatan: "Gambir", kelurahan: "Kebon Kelapa"),
            source(type: .kali, name: "Sungai 3", wilayah: "Jakarta Pusat", kecamatan: "Menteng", kelurahan: "Cikini")
        ]

        // Wilayah tier: 1 cluster for Jakarta Pusat with 3 items
        let wilayahClusters = MapClustering.clusterCategory(rivers, longitudeDelta: 0.30)
        #expect(wilayahClusters.count == 1)
        #expect(wilayahClusters[0].isCluster)
        #expect(wilayahClusters[0].count == 3)
        #expect(wilayahClusters[0].title == "Jakarta Pusat")

        // Kecamatan tier: 2 clusters (Gambir count 2, Menteng count 1 which renders as individual pin)
        let kecClusters = MapClustering.clusterCategory(rivers, longitudeDelta: 0.12)
        #expect(kecClusters.count == 2)
        let gambir = kecClusters.first { $0.title == "Gambir" }
        #expect(gambir?.count == 2)
        #expect(gambir?.isCluster == true)
        let menteng = kecClusters.first { $0.singleSource?.name == "Sungai 3" }
        #expect(menteng != nil)

        // Kelurahan tier: 2 clusters
        let kelClusters = MapClustering.clusterCategory(rivers, longitudeDelta: 0.05)
        #expect(kelClusters.count == 2)

        // Individual tier: 3 individual pins
        let indClusters = MapClustering.clusterCategory(rivers, longitudeDelta: 0.01)
        #expect(indClusters.count == 3)
        #expect(indClusters.allSatisfy { !$0.isCluster })
    }
}

