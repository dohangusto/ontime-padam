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

    /// Normalized Jakarta administrative region ("Jakarta Pusat", "Jakarta Selatan", "Jakarta Barat", "Jakarta Timur", "Jakarta Utara", "Kepulauan Seribu", or "Lainnya").
    var administrativeRegion: String {
        if let wilayah, !wilayah.isEmpty {
            let clean = wilayah
                .replacingOccurrences(of: "KOTA ADM. ", with: "")
                .replacingOccurrences(of: "KAB. ADM. ", with: "")
                .replacingOccurrences(of: "KOTA ADMINISTRASI ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return clean.capitalized
        }

        let combined = [address, kecamatan, kelurahan].compactMap { $0 }.joined(separator: " ").uppercased()
        if combined.contains("JAKARTA PUSAT") || combined.contains("JKT PUSAT") { return "Jakarta Pusat" }
        if combined.contains("JAKARTA UTARA") || combined.contains("JKT UTARA") { return "Jakarta Utara" }
        if combined.contains("JAKARTA BARAT") || combined.contains("JKT BARAT") { return "Jakarta Barat" }
        if combined.contains("JAKARTA SELATAN") || combined.contains("JKT SELATAN") { return "Jakarta Selatan" }
        if combined.contains("JAKARTA TIMUR") || combined.contains("JKT TIMUR") { return "Jakarta Timur" }
        if combined.contains("KEPULAUAN SERIBU") { return "Kepulauan Seribu" }

        // Area / Kecamatan keyword resolution
        let north = ["PENJARINGAN", "KELAPA GADING", "TANJUNG PRIOK", "CILINCING", "KOJA", "PADEMANGAN", "PLUIT", "MARUNDA", "KAPUK", "ANCOL", "SUNTER"]
        let west = ["CENGKARENG", "GROGOL", "KALIDERES", "KEBON JERUK", "KEMBANGAN", "PALMERAH", "TAMAN SARI", "TAMBORA", "DAAN MOGOT", "RAWA BUAYA", "JELAMBAR", "TOMANG", "SLIPI"]
        let south = ["CILANDAK", "JAGAKARSA", "KEBAYORAN", "MAMPANG", "PANCORAN", "PASAR MINGGU", "PESANGGRAHAN", "SETIABUDI", "TEBET", "KUNINGAN", "BLOK M", "FATMAWATI", "PONDOK INDAH", "LEBAK BULUS", "KEMANG", "PONDOK LABU", "SRENGSENG SAWAH", "CIJANTUNG", "KALIBATA", "PEJATEN"]
        let east = ["CAKUNG", "CIPINANG", "CIRACAS", "DUREN SAWIT", "JATINEGARA", "KRAMAT JATI", "MAKASAR", "MATRAMAN", "PASAR REBO", "PULOGADUNG", "KALIMALANG", "PONDOK KELAPA", "PONDOK RANGON", "LUBANG BUAYA", "PULOGEBANG", "KAMPUNG MELAYU"]
        let central = ["GAMBIR", "TANAH ABANG", "MENTENG", "SENEN", "CEMPAKA PUTIH", "JOHAR BARU", "KEMAYORAN", "SAWAH BESAR", "KWITANG", "CIDENG", "ISTIQLAL", "MONAS", "KARET", "MANGGARAI", "SALEMBA"]

        if north.contains(where: { combined.contains($0) }) { return "Jakarta Utara" }
        if west.contains(where: { combined.contains($0) }) { return "Jakarta Barat" }
        if south.contains(where: { combined.contains($0) }) { return "Jakarta Selatan" }
        if east.contains(where: { combined.contains($0) }) { return "Jakarta Timur" }
        if central.contains(where: { combined.contains($0) }) { return "Jakarta Pusat" }

        // Bounding box coordinate fallback
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        if lat >= -6.15 && lon >= 106.78 { return "Jakarta Utara" }
        if lon < 106.80 && lat >= -6.20 { return "Jakarta Barat" }
        if lat >= -6.20 && lat < -6.15 && lon >= 106.80 && lon <= 106.87 { return "Jakarta Pusat" }
        if lat < -6.20 && lon < 106.85 { return "Jakarta Selatan" }
        if lon >= 106.85 && lat < -6.15 { return "Jakarta Timur" }

        return "Jakarta Pusat"
    }

    /// Normalized administrative district (Kecamatan).
    var administrativeKecamatan: String {
        if let kecamatan, !kecamatan.isEmpty {
            let clean = kecamatan
                .replacingOccurrences(of: "KEC. ", with: "")
                .replacingOccurrences(of: "KECAMATAN ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return clean.capitalized
        }

        let combined = [address, kelurahan].compactMap { $0 }.joined(separator: " ").uppercased()
        let kecList = [
            "PENJARINGAN", "KELAPA GADING", "TANJUNG PRIOK", "CILINCING", "KOJA", "PADEMANGAN",
            "CENGKARENG", "GROGOL PETAMBURAN", "GROGOL", "KALIDERES", "KEBON JERUK", "KEMBANGAN", "PALMERAH", "TAMAN SARI", "TAMBORA",
            "CILANDAK", "JAGAKARSA", "KEBAYORAN BARU", "KEBAYORAN LAMA", "MAMPANG PRAPATAN", "PANCORAN", "PASAR MINGGU", "PESANGGRAHAN", "SETIABUDI", "TEBET",
            "CAKUNG", "CIPINANG", "CIRACAS", "DUREN SAWIT", "JATINEGARA", "KRAMAT JATI", "MAKASAR", "MATRAMAN", "PASAR REBO", "PULOGADUNG",
            "GAMBIR", "TANAH ABANG", "MENTENG", "SENEN", "CEMPAKA PUTIH", "JOHAR BARU", "KEMAYORAN", "SAWAH BESAR"
        ]
        for kec in kecList {
            if combined.contains(kec) {
                return kec.capitalized
            }
        }
        return administrativeRegion
    }

    /// Normalized administrative subdistrict (Kelurahan).
    var administrativeKelurahan: String {
        if let kelurahan, !kelurahan.isEmpty {
            let clean = kelurahan
                .replacingOccurrences(of: "KEL. ", with: "")
                .replacingOccurrences(of: "KELURAHAN ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return clean.capitalized
        }

        let combined = [address, name].compactMap { $0 }.joined(separator: " ").uppercased()
        let kelList = [
            "KAPUK MUARA", "PLUIT", "PEJAGALAN", "PENJARINGAN", "KAMAL MUARA",
            "KEBON KACANG", "KAMPUNG BALI", "PETOJO SELATAN", "PETOJO UTARA", "GAMBIR", "KEBON KELAPA", "DURI PULO", "CIDENG",
            "GONDANGDIA", "CIKINI", "MENTENG", "PEGANGSAAN", "KWITANG", "PASAR SENEN", "BUNGUR", "KENARI", "KRAMAT",
            "RAWASARI", "CEMPAKA PUTIH TIMUR", "CEMPAKA PUTIH BARAT", "GALUR", "TANAH TINGGI", "KAMPUNG RAWA", "JOHAR BARU",
            "GUNUNG SAHARI", "KEMAYORAN", "KEBON KOSONG", "HARAPAN MULYA", "SERDANG", "UTAN PANJANG", "SUMUR BATU",
            "PASAR BARU", "MANGGA DUA SELATAN", "KARANG ANYAR", "KARTINI",
            "BINTARO", "PESANGGRAHAN", "PETUKANGAN UTARA", "PETUKANGAN SELATAN", "ULUJAMI",
            "CIPETE UTARA", "CIPETE SELATAN", "GANDARIA UTARA", "GANDARIA SELATAN", "PONDOK PINANG", "LEBAK BULUS", "CILANDAK BARAT",
            "PONDOK LABU", "JAGAKARSA", "SRENGSENG SAWAH", "CIGANJUR", "LENTENG AGUNG", "TANJUNG BARAT", "CILANDAK TIMUR",
            "PEJATEN BARAT", "PEJATEN TIMUR", "PASAR MINGGU", "JATI PADANG", "RAGUNAN", "KALIBATA", "RAWAJATI", "DUREN TIGA",
            "PANCORAN", "CIKOKO", "PENGADEGAN", "TEBET BARAT", "TEBET TIMUR", "KEBON BARU", "BUKIT DURI", "MANGGARAI", "MENTENG DALAM"
        ]
        for kel in kelList {
            if combined.contains(kel) {
                return kel.capitalized
            }
        }
        return administrativeKecamatan
    }
}
