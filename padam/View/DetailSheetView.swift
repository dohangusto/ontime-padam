//
//  DetailSheetView.swift
//  padam
//
//  Single location detail bottom sheet matching IMG_4790:
//  - Top header with ShareLink, Title & Subtitle, and Close (xmark) button.
//  - Prominent Action buttons (Primary Route button with ETA + Secondary Call / Satellite button).
//  - 3-column Summary Chips (Status/Hours, Keandalan/Rating, Distance).
//  - Info cards (Alamat, Wilayah, Kondisi).
//  - Floating bottom capsule bar overlay with Plus, Star, and Ellipsis actions.
//

import SwiftUI
import MapKit

struct DetailSheetView: View {
    let ranked: RankedWaterSource
    let fireLocation: Coordinate?
    @Binding var satellite: Bool
    var isSaved: Bool = false
    var onToggleSave: () -> Void = {}
    var onBack: () -> Void
    var onRouteReady: (MKPolyline?) -> Void

    @State private var estimate: RouteEstimate?
    @State private var isLoadingRoute = false

    private var source: WaterSource { ranked.source }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    actionRow
                    summaryChipsRow
                    addressAndAdministrativeSection
                    conditionSection
                    DataAttributionFooter()
                        .padding(.top, 4)
                        .padding(.bottom, 72) // space for floating bottom bar
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            // Floating Bottom Bar pinned at the bottom overlay (IMG_4790)
            FloatingBottomBar(
                source: source,
                isSaved: isSaved,
                onToggleSave: onToggleSave,
                onAddGuide: {},
                onOpenInMaps: openInMaps
            )
            .padding(.bottom, 12)
        }
        .task(id: source.id) { await loadRoute() }
    }

    // MARK: Header (Share, Title + Subtitle, Close)

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ShareLink(
                item: "\(source.name)\n\(source.address)\nKoordinat: \(source.coordinate.latitude), \(source.coordinate.longitude)"
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(.quaternary.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                Text(source.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(source.type.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button(action: onBack) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.quaternary.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Action Buttons Row (IMG_4790)

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button(action: openInMaps) {
                HStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(routeButtonTitle)
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(.white)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                satellite.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: satellite ? "globe.americas.fill" : "phone.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(satellite ? "Satelit On" : "Hubungi")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(.white)
                .background(.quaternary.opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var routeButtonTitle: String {
        if let estimate { return formatDuration(estimate.travelTime) }
        return "Rute"
    }

    // MARK: Summary Chips Row (3 Columns: Status, Keandalan, Distance)

    private var summaryChipsRow: some View {
        HStack(spacing: 0) {
            // Status / Hours
            VStack(spacing: 4) {
                Text("Status")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(statusText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 32)

            // Ratings / Keandalan
            VStack(spacing: 4) {
                Text("Keandalan")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: ranked.isLowReliability ? "exclamationmark.triangle.fill" : "hand.thumbsup.fill")
                        .font(.caption.weight(.bold))
                    Text(ranked.isLowReliability ? "Rendah" : "100%")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(ranked.isLowReliability ? .orange : .primary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 32)

            // Distance
            VStack(spacing: 4) {
                Text("Distance")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(DistanceFormat.string(ranked.distanceMeters))
                        .font(.headline.monospacedDigit().weight(.bold))
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusText: String {
        if let kondisi = source.kondisi, !kondisi.isEmpty {
            return kondisi.capitalized
        }
        return "Siap Pakai"
    }

    // MARK: Address & Administrative Section

    private var addressAndAdministrativeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Alamat")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(source.address.isEmpty ? "Alamat tidak tercantum" : source.address)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }

            let parts = [source.kelurahan, source.kecamatan, source.wilayah].compactMap { $0 }
            if !parts.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wilayah Administratif")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(parts.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Condition / Raw Data Section

    @ViewBuilder
    private var conditionSection: some View {
        if let kondisi = source.kondisi, !kondisi.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Kondisi Lapangan")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(kondisi)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
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
        let location = CLLocation(
            latitude: source.coordinate.latitude,
            longitude: source.coordinate.longitude
        )
        let item = MKMapItem(location: location, address: nil)
        item.name = source.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int((interval / 60).rounded())
        return "\(minutes) min"
    }
}

#if DEBUG
#Preview("Detail") {
    DetailSheetView(
        ranked: PreviewSamples.sampleRanked,
        fireLocation: PreviewSamples.fire,
        satellite: .constant(false),
        isSaved: false,
        onToggleSave: {},
        onBack: {},
        onRouteReady: { _ in }
    )
    .background(.black)
}
#endif
