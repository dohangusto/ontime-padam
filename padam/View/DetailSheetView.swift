//
//  DetailSheetView.swift
//  padam
//
//  Detail state (large detent). Everything the operator needs to speak an
//  actionable instruction over the radio: type, distance, full address, the
//  raw condition, and a route. Includes the satellite toggle so the operator can
//  judge road width / truck access themselves — we provide evidence, not
//  conclusions.
//

import SwiftUI
import MapKit

struct DetailSheetView: View {
    let ranked: RankedWaterSource
    let fireLocation: Coordinate?
    @Binding var satellite: Bool
    var onBack: () -> Void
    var onRouteReady: (MKPolyline?) -> Void

    @State private var estimate: RouteEstimate?
    @State private var isLoadingRoute = false

    private var source: WaterSource { ranked.source }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                actionRow
                markers
                distanceSection
                Divider()
                addressSection
                if let kondisi = source.kondisi, !kondisi.isEmpty {
                    infoRow(title: "Kondisi (data mentah)", value: kondisi)
                }
                administrativeSection
                DataAttributionFooter()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .task(id: source.id) { await loadRoute() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            SourcePinView(type: source.type)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name)
                    .font(.title2.bold())
                    .lineLimit(2)
                Text(source.type.displayName)
                    .font(.subheadline)
                    .foregroundStyle(source.type.tint)
            }
            Spacer()
            Button(action: onBack) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.quaternary, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    /// Apple-Maps-style prominent action row: primary route button (with ETA when
    /// known) plus a satellite toggle so the operator can judge road access.
    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: openInMaps) {
                Label(routeButtonTitle, systemImage: "car.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button { satellite.toggle() } label: {
                Label("Satelit", systemImage: "globe.americas.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(satellite ? .blue : .gray)
        }
        .controlSize(.large)
    }

    private var routeButtonTitle: String {
        if let estimate { return "Rute · \(formatDuration(estimate.travelTime))" }
        return "Rute"
    }

    @ViewBuilder private var markers: some View {
        HStack(spacing: 8) {
            if ranked.isLowReliability {
                calloutBadge("Keandalan rendah — banyak hidran rusak / debit kecil",
                             systemImage: "exclamationmark.triangle.fill", tint: .orange)
            }
            if ranked.isFar {
                calloutBadge("Jauh (>3 km) dari lokasi",
                             systemImage: "location.slash", tint: .secondary)
            }
        }
    }

    private var distanceSection: some View {
        HStack(spacing: 20) {
            metric(title: "Garis lurus", value: DistanceFormat.string(ranked.distanceMeters))
            if let estimate {
                metric(title: "Jarak rute", value: DistanceFormat.string(estimate.distanceMeters))
                metric(title: "Estimasi waktu", value: formatDuration(estimate.travelTime))
            } else if isLoadingRoute {
                metric(title: "Rute", value: "…")
            }
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Alamat lengkap")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(source.address.isEmpty ? "Alamat tidak tersedia" : source.address)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder private var administrativeSection: some View {
        let parts = [source.kelurahan, source.kecamatan, source.wilayah].compactMap { $0 }
        if !parts.isEmpty {
            infoRow(title: "Wilayah", value: parts.joined(separator: ", "))
        }
    }


    // MARK: Pieces

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func calloutBadge(_ text: String, systemImage: String, tint: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Actions

    private func loadRoute() async {
        guard let fireLocation else { return }
        isLoadingRoute = true
        estimate = await DirectionsService.route(from: fireLocation, to: source.coordinate)
        isLoadingRoute = false
        onRouteReady(estimate?.polyline)
    }

    private func openInMaps() {
        let location = CLLocation(latitude: source.coordinate.latitude,
                                  longitude: source.coordinate.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = source.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int((interval / 60).rounded())
        return "\(minutes) mnt"
    }
}

#if DEBUG
#Preview("Detail") {
    DetailSheetView(ranked: PreviewSamples.sampleRanked,
                    fireLocation: PreviewSamples.fire,
                    satellite: .constant(false),
                    onBack: {}, onRouteReady: { _ in })
}
#endif
