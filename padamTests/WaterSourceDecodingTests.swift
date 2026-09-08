//
//  WaterSourceDecodingTests.swift
//  padamTests
//
//  Verifies the uniform decoding maps every source file into one shape, and
//  that malformed / invalid / missing coordinates are dropped rather than
//  fabricated.
//

import Testing
import Foundation
@testable import padam

@MainActor
struct WaterSourceDecodingTests {

    let loader = WaterSourceLoader()

    @Test("Decodes the pos-damkar shape (nama_pos) into the uniform model")
    func decodePosDamkar() {
        let json = """
        [{
          "nama_pos": "POS PLUIT",
          "alamat": "JL. PLUIT BARAT",
          "longitude": 106.784716,
          "latitude": -6.117498,
          "wilayah": "KOTA ADM. JAKARTA UTARA",
          "kecamatan": "PENJARINGAN",
          "kelurahan": "PLUIT",
          "kondisi": "BAIK"
        }]
        """.data(using: .utf8)!

        let sources = loader.decode(json, type: .posDamkar)
        #expect(sources.count == 1)
        let s = sources[0]
        #expect(s.type == .posDamkar)
        #expect(s.name == "POS PLUIT")
        #expect(s.address == "JL. PLUIT BARAT")
        #expect(s.kondisi == "BAIK")
        #expect(s.coordinate.latitude == -6.117498)
    }

    @Test("Decodes the hidran shape (nama_hidran) into the same uniform model")
    func decodeHidran() {
        let json = """
        [{
          "nama_hidran": "HIDRAN KOTA",
          "alamat": "JL. ASEM NO.15",
          "longitude": 106.8400713,
          "latitude": -6.28016,
          "kondisi": "TIDAK BISA DIGUNAKAN"
        }]
        """.data(using: .utf8)!

        let sources = loader.decode(json, type: .hidran)
        #expect(sources.count == 1)
        #expect(sources[0].type == .hidran)
        #expect(sources[0].name == "HIDRAN KOTA")
        #expect(sources[0].kondisi == "TIDAK BISA DIGUNAKAN")
    }

    @Test("Invalid or missing coordinates are dropped, never fabricated")
    func invalidCoordinatesDropped() {
        let json = """
        [
          { "nama_pos": "Null Island", "longitude": 0, "latitude": 0 },
          { "nama_pos": "Out of range", "longitude": 200, "latitude": -6.1 },
          { "nama_pos": "Missing lat", "longitude": 106.8 },
          { "nama_pos": "Valid", "longitude": 106.8, "latitude": -6.1 }
        ]
        """.data(using: .utf8)!

        let sources = loader.decode(json, type: .posDamkar)
        #expect(sources.count == 1)
        #expect(sources[0].name == "Valid")
    }

    @Test("Malformed JSON returns an empty array, never crashes")
    func malformedJSON() {
        let json = "{ not valid json ".data(using: .utf8)!
        #expect(loader.decode(json, type: .hidran).isEmpty)
    }

    @Test("Decodes the kolam-renang shape (name + address key) into the uniform model")
    func decodeKolamRenang() {
        let json = """
        [{
          "name": "Club House Puri Grisenda",
          "address": "RT.7/RW.3, Kapuk Muara, Jakarta Utara",
          "latitude": -6.1345625,
          "longitude": 106.7541875,
          "phone": "0851-7999-9320"
        }]
        """.data(using: .utf8)!

        let sources = loader.decode(json, type: .kolamRenang)
        #expect(sources.count == 1)
        let s = sources[0]
        #expect(s.type == .kolamRenang)
        #expect(s.name == "Club House Puri Grisenda")
        #expect(s.address == "RT.7/RW.3, Kapuk Muara, Jakarta Utara")
        #expect(s.phone == "0851-7999-9320")
        #expect(s.coordinate.latitude == -6.1345625)
    }

    @Test("Decodes the sungai shape with string coordinates and nama_sungai")
    func decodeSungaiStringCoordinates() {
        let json = """
        [{
          "nama_sungai": "KALIBARU TIMUR",
          "alamat": "JL. RAYA BOGOR KOMSEKO",
          "latitude": "-6.286182",
          "longitude": "106.870626",
          "parameter": "PH"
        }]
        """.data(using: .utf8)!

        let sources = loader.decode(json, type: .kali)
        #expect(sources.count == 1)
        let s = sources[0]
        #expect(s.type == .kali)
        #expect(s.name == "KALIBARU TIMUR")
        #expect(s.address == "JL. RAYA BOGOR KOMSEKO")
        #expect(s.coordinate.latitude == -6.286182)
        #expect(s.coordinate.longitude == 106.870626)
    }

    @Test("Collapses repeated sungai rows (one per parameter) into a single point")
    func deduplicatesSungaiSamplingPoint() {
        // Same sampling point appears once per measured parameter.
        let json = """
        [
          { "nama_sungai": "KALIBARU TIMUR", "latitude": "-6.286182", "longitude": "106.870626", "parameter": "PH" },
          { "nama_sungai": "KALIBARU TIMUR", "latitude": "-6.286182", "longitude": "106.870626", "parameter": "BOD" },
          { "nama_sungai": "KALIBARU TIMUR", "latitude": "-6.286182", "longitude": "106.870626", "parameter": "COD" },
          { "nama_sungai": "KALIBARU TIMUR", "latitude": "-6.300000", "longitude": "106.900000", "parameter": "PH" }
        ]
        """.data(using: .utf8)!

        let sources = loader.decode(json, type: .kali)
        // Two distinct coordinates → two points, not four.
        #expect(sources.count == 2)
    }

    @Test("Missing name falls back to the type label, not a fabricated value")
    func missingNameFallsBack() {
        let json = """
        [{ "alamat": "somewhere", "longitude": 106.8, "latitude": -6.1 }]
        """.data(using: .utf8)!
        let sources = loader.decode(json, type: .kali)
        #expect(sources.count == 1)
        #expect(sources[0].name == WaterSourceType.kali.displayName)
    }
}
