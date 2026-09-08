//
//  CategoryBrowseTests.swift
//  padamTests
//
//  Tests for category browsing and administrative region grouping.
//

import XCTest
@testable import padam

final class CategoryBrowseTests: XCTestCase {

    func testAdministrativeRegionExplicitWilayah() {
        let source = WaterSource(
            type: .posDamkar,
            name: "Pos Damkar Gambir",
            address: "Jl. Gambir",
            coordinate: Coordinate(latitude: -6.1754, longitude: 106.8272),
            wilayah: "KOTA ADM. JAKARTA PUSAT"
        )
        XCTAssertEqual(source.administrativeRegion, "Jakarta Pusat")
    }

    func testAdministrativeRegionAddressMatching() {
        let source = WaterSource(
            type: .kolamRenang,
            name: "Club House Puri Grisenda",
            address: "Kapuk Muara, Penjaringan, Jkt Utara",
            coordinate: Coordinate(latitude: -6.1345, longitude: 106.7541),
            wilayah: nil
        )
        XCTAssertEqual(source.administrativeRegion, "Jakarta Utara")
    }

    func testAdministrativeRegionCoordinateFallback() {
        let southSource = WaterSource(
            type: .kali,
            name: "Kali Jagakarsa",
            address: "Tanpa Alamat",
            coordinate: Coordinate(latitude: -6.3200, longitude: 106.8200),
            wilayah: nil
        )
        XCTAssertEqual(southSource.administrativeRegion, "Jakarta Selatan")
    }

    func testAllBundledSourcesCategorizedIntoValidRegions() {
        let loader = WaterSourceLoader()
        let all = loader.loadAll()
        XCTAssertFalse(all.isEmpty, "Bundled sources should not be empty")

        let validRegions: Set<String> = [
            "Jakarta Pusat",
            "Jakarta Utara",
            "Jakarta Barat",
            "Jakarta Selatan",
            "Jakarta Timur",
            "Kepulauan Seribu",
            "Lainnya"
        ]

        for source in all {
            let region = source.administrativeRegion
            XCTAssertTrue(validRegions.contains(region), "Source \(source.name) resolved to unexpected region: \(region)")
        }
    }
}
