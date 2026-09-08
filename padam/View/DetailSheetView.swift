//
//  DetailSheetView.swift
//  padam
//
//  Single location detail bottom sheet matching IMG_4790:
//  - Top header with ShareLink, Title & Subtitle, and Close (xmark) button.
//  - Prominent driving Route button (with ETA). Call appears only when the
//    source carries a phone number, so a call is never offered with nothing to dial.
//  - 3-column Summary Chips (Status, Keandalan, Jarak lurus). Status color is
//    bound to the point's condition, never hardcoded.
//  - Info cards (Alamat, Wilayah, Kondisi).
//  - Floating bottom capsule bar overlay with Plus, Star, and Ellipsis actions.
//

import SwiftUI
import MapKit

struct DetailSheetView: View {
    let ranked: RankedWaterSource
    let fireLocation: Coordinate?
    var isSaved: Bool = false
    var isSmall: Bool = false
    var isFullyExpanded: Bool = true
    var onToggleSave: () -> Void = {}
    var onBack: () -> Void
    var onRouteReady: (MKPolyline?) -> Void

    @State private var estimate: RouteEstimate?
    @State private var isLoadingRoute = false

    @Environment(\.openURL) private var openURL

    private var source: WaterSource { ranked.source }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, isSmall ? 10 : 12)
                    .padding(.bottom, isSmall ? 10 : 8)

                if !isSmall {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            actionRow
                            summaryChipsRow
                            addressAndAdministrativeSection
                            conditionSection
                            DataAttributionFooter()
                                .padding(.top, 4)
                                .padding(.bottom, 72) // space for floating bottom bar
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .scrollDisabled(!isFullyExpanded)
                }
            }
            .frame(maxHeight: .infinity, alignment: isSmall ? .center : .top)

            if !isSmall {
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
                    .background(Color.white.opacity(0.1), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                // The name is what the operator says over the radio — never
                // truncate it. Allow up to two lines instead.
                Text(source.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if source.type.isLowReliability {
                    HStack(spacing: 4) {
                        Text(source.type.displayName)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.secondary.opacity(0.6))
                        Text("keandalan rendah")
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                } else {
                    Text(source.type.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Button(action: onBack) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Action Buttons Row (IMG_4790)

    private var actionRow: some View {
        HStack(spacing: 12) {
            // Primary action for every type: driving route with ETA.
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
                .background(Color.indigo, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            // Call only appears when the source actually has a number (e.g. a Pos
            // DAMKAR, once phone data is loaded). Hydrants and other types show
            // route only — no dead call button.
            if let phone = source.phone {
                Button {
                    call(phone)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Hubungi")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.white)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var routeButtonTitle: String {
        if let estimate { return "Rute · \(formatDuration(estimate.travelTime))" }
        return "Rute"
    }

    // MARK: Summary Chips Row (2 Columns: Status, Jarak lurus)

    private var summaryChipsRow: some View {
        HStack(spacing: 0) {
            // Status — color, icon and word all bound to the point's condition.
            // Single word/phrase: Aktif (green), Rusak (red), Tak diketahui (gray).
            VStack(spacing: 4) {
                Text("Status")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    Image(systemName: ranked.condition.symbolName)
                        .font(.subheadline.weight(.bold))
                    Text(ranked.condition.label)
                        .font(.headline.weight(.bold))
                        .lineLimit(1)
                }
                .foregroundStyle(ranked.condition.tint)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 32)

            // Straight-line distance — labeled so it's never confused with the
            // driving ETA on the Rute button (which is the decision figure).
            VStack(spacing: 4) {
                Text("Jarak lurus")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    Image(systemName: "ruler")
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
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
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
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
    }

    // MARK: Condition / Raw Data Section

    @ViewBuilder
    private var conditionSection: some View {
        if let kondisi = source.kondisi, !kondisi.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Kondisi Lapangan")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: ranked.condition.symbolName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ranked.condition.tint)
                    Text(kondisi)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
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

    private func call(_ number: String) {
        let dialable = number.filter { $0.isNumber || $0 == "+" }
        guard !dialable.isEmpty, let url = URL(string: "tel://\(dialable)") else { return }
        openURL(url)
    }
}

#if DEBUG
#Preview("Detail") {
    DetailSheetView(
        ranked: PreviewSamples.sampleRanked,
        fireLocation: PreviewSamples.fire,
        isSaved: false,
        onToggleSave: {},
        onBack: {},
        onRouteReady: { _ in }
    )
    .background(.black)
}
#endif
