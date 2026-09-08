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
