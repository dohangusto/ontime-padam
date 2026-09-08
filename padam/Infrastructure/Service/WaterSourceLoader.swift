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
    let phone: String?

    private enum CodingKeys: String, CodingKey {
        case namaPos = "nama_pos"
        case namaHidran = "nama_hidran"
        case namaSungai = "nama_sungai"
        case nama
        case name
        case title
        case alamat
        case address
        case wilayah, kecamatan, kelurahan, kondisi
        case latitude, longitude
        case telepon, phone
        case noTelepon = "no_telepon"
        case nomorTelepon = "nomor_telepon"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Resolve the "name" and "address" fields across the differing per-file
        // keys. Broken out of a single `??` chain so the type-checker stays fast.
        let nameKeys: [CodingKeys] = [.namaPos, .namaHidran, .namaSungai, .nama, .name, .title]
        name = try Self.firstString(in: c, keys: nameKeys)
        address = try Self.firstString(in: c, keys: [.alamat, .address])
        // The sungai dataset stores coordinates as strings ("−6.28"), the others
        // as numbers. Accept either so no file needs bespoke handling.
        latitude = Self.decodeFlexibleDouble(c, forKey: .latitude)
        longitude = Self.decodeFlexibleDouble(c, forKey: .longitude)
        wilayah = try c.decodeIfPresent(String.self, forKey: .wilayah)
        kecamatan = try c.decodeIfPresent(String.self, forKey: .kecamatan)
        kelurahan = try c.decodeIfPresent(String.self, forKey: .kelurahan)
        kondisi = try c.decodeIfPresent(String.self, forKey: .kondisi)
        phone = try Self.firstString(in: c, keys: [.telepon, .phone, .noTelepon, .nomorTelepon])
    }

    /// Returns the first non-nil string among the given keys, so callers avoid a
    /// long `??` chain that stresses the type-checker.
    private static func firstString(in c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) throws -> String? {
        for key in keys {
            if let value = try c.decodeIfPresent(String.self, forKey: key) {
                return value
            }
        }
        return nil
    }

    /// Decodes a coordinate component that may arrive as a JSON number or a
    /// numeric string. Returns nil when absent or unparseable.
    private static func decodeFlexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Double? {
        if let value = try? c.decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let string = try? c.decodeIfPresent(String.self, forKey: key) {
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
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
            kondisi: kondisi,
            phone: phone?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
    }
}

private extension String {
    /// nil for an empty/whitespace-only string, so a blank phone field never
    /// produces a call action with nothing to dial.
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

struct WaterSourceLoader {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// JSON resource name per type. Any category without an entry (e.g. `got`)
    /// intentionally loads as empty.
    private static let resourceNames: [WaterSourceType: String] = [
        .posDamkar: "pos-damkar",
        .hidran: "hidran",
        .kolamRenang: "kolam-renang",
        .kali: "sungai"
    ]

    /// Types that actually have a bundled dataset. Lets the UI distinguish "no
    /// dataset loaded" from "dataset loaded but nothing found nearby".
    static var availableTypes: Set<WaterSourceType> { Set(resourceNames.keys) }

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
        let sources = dtos.compactMap { $0.toWaterSource(type: type) }
        return deduplicated(sources)
    }

    /// Collapses rows that describe the same physical point. The sungai dataset
    /// carries ~80 water-quality rows per sampling point (one per parameter), so
    /// without this a single river point would produce dozens of overlapping
    /// pins. Keyed by name + rounded coordinate, so genuinely distinct points on
    /// the same river (different coordinates) are preserved.
    private func deduplicated(_ sources: [WaterSource]) -> [WaterSource] {
        var seen = Set<String>()
        var result: [WaterSource] = []
        result.reserveCapacity(sources.count)
        for source in sources {
            let key = "\(source.name)|\(source.coordinate.latitude.rounded(toPlaces: 6))|\(source.coordinate.longitude.rounded(toPlaces: 6))"
            if seen.insert(key).inserted {
                result.append(source)
            }
        }
        return result
    }
}

private extension Double {
    /// Rounds to a fixed number of decimals so tiny float differences don't
    /// defeat coordinate-based de-duplication.
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
