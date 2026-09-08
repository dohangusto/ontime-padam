//
//  MapOverlays.swift
//  padam
//
//  Native Apple Maps overlay controls: Weather Pill (top-left) and Map Controls (bottom-right).
//

import SwiftUI
import MapKit

/// Top-left weather indicator matching IMG_4786 / IMG_4790
struct WeatherPillView: View {
    var temperature: String = "29°"
    var areaName: String = "KEBON KACANG"

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)

                Text(temperature)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())

            Text(areaName)
                .font(.system(size: 12, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(.secondary)
        }
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
    }
}

/// Bottom-right stacked map action controls (Map Layer Style + Hydrant Layer
/// Toggle + User Location Tracking) matching IMG_4786 / IMG_4790
struct MapFloatingControlsView: View {
    @Binding var isSatellite: Bool
    /// Whether the (noisy, least reliable) hydrant layer is currently hidden.
    var hydrantsHidden: Bool = false
    var onToggleHydrants: () -> Void = {}
    var onRecenter: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) {
                    isSatellite.toggle()
                }
            } label: {
                Image(systemName: isSatellite ? "globe.americas.fill" : "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSatellite ? .blue : .primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(width: 32)

            // Mute/show the hydrant layer so the reliable types read clearly.
            Button(action: onToggleHydrants) {
                Image(systemName: hydrantsHidden ? "fire.extinguisher" : "fire.extinguisher.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(hydrantsHidden ? .secondary : WaterSourceType.hidran.tint)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(width: 32)

            Button(action: onRecenter) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
    }
}

#Preview {
    ZStack {
        Color.gray
        VStack {
            HStack {
                WeatherPillView()
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                MapFloatingControlsView(isSatellite: .constant(false), onRecenter: {})
            }
        }
        .padding()
    }
}
