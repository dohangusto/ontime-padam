//
//  PreviewSamples.swift
//  padam
//
//  Sample data used only by SwiftUI previews.
//

#if DEBUG
import Foundation

enum PreviewSamples {
    static let fire = Coordinate(latitude: -6.2000, longitude: 106.8167)

    /// A spread of sources across types and distances, including a far hydrant,
    /// so previews exercise the "far" and "low reliability" markers. Kali/got are
    /// intentionally sparse/empty to show the graceful empty groups.
    static let sources: [WaterSource] = [
        WaterSource(type: .kali, name: "Kali Krukut", address: "Jl. Kali Krukut, Jakarta Pusat",
                    coordinate: Coordinate(latitude: -6.203, longitude: 106.820), kondisi: nil),
        WaterSource(type: .kolamRenang, name: "Kolam Renang Senayan", address: "Jl. Pintu Satu Senayan",
                    coordinate: Coordinate(latitude: -6.215, longitude: 106.803)),
        WaterSource(type: .kolamRenang, name: "Kolam Renang GBK", address: "Gelora Bung Karno",
                    coordinate: Coordinate(latitude: -6.218, longitude: 106.802)),
        WaterSource(type: .posDamkar, name: "POS TANAH ABANG", address: "Jl. Fachrudin, Tanah Abang",
                    coordinate: Coordinate(latitude: -6.198, longitude: 106.812), kondisi: "BAIK"),
        WaterSource(type: .posDamkar, name: "POS GAMBIR", address: "Jl. Medan Merdeka",
                    coordinate: Coordinate(latitude: -6.185, longitude: 106.825), kondisi: "BAIK"),
        WaterSource(type: .hidran, name: "HIDRAN KOTA", address: "Jl. Thamrin No.10",
                    coordinate: Coordinate(latitude: -6.201, longitude: 106.818), kondisi: "BISA DIGUNAKAN"),
        WaterSource(type: .hidran, name: "HIDRAN KOTA", address: "Jl. Sudirman (jauh)",
                    coordinate: Coordinate(latitude: -6.250, longitude: 106.860), kondisi: "TIDAK BISA DIGUNAKAN")
    ]

    static var groups: [RankedGroup] {
        RankingService.rank(sources: sources, from: fire)
    }

    static var sampleRanked: RankedWaterSource {
        RankedWaterSource(source: sources[5], distanceMeters: fire.distance(to: sources[5].coordinate))
    }
}
#endif
