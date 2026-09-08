//
//  WaterSource.swift
//  padam
//
//  One uniform data shape for all five water-source categories. There is no
//  per-type variant: the `type` field distinguishes them, and every consumer
//  treats them identically.
//

import Foundation

struct WaterSource: Identifiable, Hashable, Sendable {
    let id: UUID
    let type: WaterSourceType
    let name: String
    let address: String
    let coordinate: Coordinate

    // Administrative context, useful for the radio instruction. Optional because
    // not every source carries it, and we never fabricate missing values.
    let wilayah: String?
    let kecamatan: String?
    let kelurahan: String?

    /// Raw condition string straight from the source data (e.g. "BAIK",
    /// "BISA DIGUNAKAN"). We surface it verbatim and never infer it.
    let kondisi: String?

    /// Contact number, when the dataset provides one. No current dataset does,
    /// so this is nil everywhere today; the call action only appears when it is
    /// present, so we never offer a call with nothing to dial.
    let phone: String?

    init(
        id: UUID = UUID(),
        type: WaterSourceType,
        name: String,
        address: String,
        coordinate: Coordinate,
        wilayah: String? = nil,
        kecamatan: String? = nil,
        kelurahan: String? = nil,
        kondisi: String? = nil,
        phone: String? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.wilayah = wilayah
        self.kecamatan = kecamatan
        self.kelurahan = kelurahan
        self.kondisi = kondisi
        self.phone = phone
    }
}
