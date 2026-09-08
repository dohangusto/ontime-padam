//
//  WaterSourceLoader.swift
//  padam
//
//  Loads bundled JSON into the uniform `WaterSource` shape. Data is immutable
//  and bundled (no remote fetch, no editing). Missing categories simply return
//  no rows — they must never crash and never be hidden from the type system.
//
//  Kept as a standalone service (not inside a ViewModel) so it stays testable.
//

import Foundation

/// Decodes a single row from any of the source JSON files. All files share the
/// same location/address fields; only the "name" key differs by file, which we
/// resolve here so downstream code needs no per-type handling.
struct WaterSourceDTO: Decodable {
    let name: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let wilayah: String?
    let kecamatan: String?
    let kelurahan: String?
    let kondisi: String?

    private enum CodingKeys: String, CodingKey {
        case namaPos = "nama_pos"
        case namaHidran = "nama_hidran"
        case nama
        case title
        case alamat
        case wilayah, kecamatan, kelurahan, kondisi
        case latitude, longitude
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .namaPos)
            ?? c.decodeIfPresent(String.self, forKey: .namaHidran)
            ?? c.decodeIfPresent(String.self, forKey: .nama)
            ?? c.decodeIfPresent(String.self, forKey: .title)
        address = try c.decodeIfPresent(String.self, forKey: .alamat)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        wilayah = try c.decodeIfPresent(String.self, forKey: .wilayah)
        kecamatan = try c.decodeIfPresent(String.self, forKey: .kecamatan)
        kelurahan = try c.decodeIfPresent(String.self, forKey: .kelurahan)
        kondisi = try c.decodeIfPresent(String.self, forKey: .kondisi)
    }

    /// Maps to the uniform model for a given type. Returns nil when the
    /// coordinate is missing or invalid — we never fabricate a location.
    func toWaterSource(type: WaterSourceType) -> WaterSource? {
        guard let latitude, let longitude else { return nil }
        let coordinate = Coordinate(latitude: latitude, longitude: longitude)
        guard coordinate.isValid else { return nil }

        let resolvedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        return WaterSource(
            type: type,
            name: (resolvedName?.isEmpty == false ? resolvedName! : type.displayName),
            address: address ?? "",
            coordinate: coordinate,
            wilayah: wilayah,
            kecamatan: kecamatan,
            kelurahan: kelurahan,
            kondisi: kondisi
        )
    }
}

struct WaterSourceLoader {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// JSON resource name per type. The three deferred categories intentionally
    /// have no entry, so they load as empty.
    private static let resourceNames: [WaterSourceType: String] = [
        .posDamkar: "pos-damkar",
        .hidran: "hidran"
    ]

    /// Loads every available type into one flat, uniform array.
    func loadAll() -> [WaterSource] {
        WaterSourceType.allCases.flatMap { load(type: $0) }
    }

    /// Loads a single type. Returns an empty array for missing files, missing
    /// resources, or malformed JSON — never throws, never crashes.
    func load(type: WaterSourceType) -> [WaterSource] {
        guard
            let resource = Self.resourceNames[type],
            let url = bundle.url(forResource: resource, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            return []
        }
        return decode(data, type: type)
    }

    /// Decodes raw JSON data for a type. Exposed for testing without a bundle.
    func decode(_ data: Data, type: WaterSourceType) -> [WaterSource] {
        guard let dtos = try? JSONDecoder().decode([WaterSourceDTO].self, from: data) else {
            return []
        }
        return dtos.compactMap { $0.toWaterSource(type: type) }
    }
}
