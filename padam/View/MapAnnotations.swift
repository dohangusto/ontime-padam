//
//  MapAnnotations.swift
//  padam
//
//  Small annotation views used on the map: aggregated cluster bubbles, single
//  water-source pins, and the fire-location marker.
//

import SwiftUI

/// An administrative cluster pill showing the region name (e.g. "Pulo Gadung", "Paseban"),
/// total count of sources, and styled with the dominant water source type's color and icon.
struct AdminClusterPillView: View {
    let title: String
    let count: Int
    let dominantType: WaterSourceType

    var body: some View {
        HStack(spacing: 6) {
            // Dominant type icon circle badge
            ZStack {
                Circle()
                    .fill(dominantType.tint)
                    .frame(width: 22, height: 22)

                Image(systemName: dominantType.symbolName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Region title + Count
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.leading, 4)
        .padding(.trailing, 10)
        .padding(.vertical, 4)
        .background(
            Color.black.opacity(0.82),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(dominantType.tint.opacity(0.85), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(clusterAccessibilityLabel)
        .accessibilityHint("Ketuk dua kali untuk memperbesar area ini")
        .accessibilityAddTraits(.isButton)
    }

    private var label: String {
        if title.isEmpty {
            return "\(count)"
        }
        return "\(title) · \(count)"
    }

    private var clusterAccessibilityLabel: String {
        if title.isEmpty {
            return "\(count) sumber air, kategori dominan \(dominantType.displayName)"
        }

        return "\(count) sumber air di \(title), kategori dominan \(dominantType.displayName)"
    }
}

/// A cluster bubble showing how many sources it aggregates (legacy fallback).
struct ClusterBubbleView: View {
    let count: Int
    var dominantType: WaterSourceType = .hidran

    var body: some View {
        Text("\(count)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(8)
            .frame(minWidth: 32, minHeight: 32)
            .background(dominantType.tint, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(radius: 2)
            .accessibilityLabel("\(count) sumber air")
            .accessibilityHint("Ketuk dua kali untuk memperbesar area ini")
            .accessibilityAddTraits(.isButton)
    }
}

/// A single water-source pin, tinted and iconed by type.
///
/// When active/selected: renders as a prominent Apple Maps-style large squircle (~54x54)
/// with a large bold symbol, anchor dot, and prominent title label.
/// When unselected: renders as a compact circular pin.
struct SourcePinView: View {
    let type: WaterSourceType
    var isSelected: Bool = false
    var label: String? = nil

    /// Hydrants are the least reliable type — demote them visually unless selected.
    private var isDemoted: Bool { type.isLowReliability && !isSelected }

    var body: some View {
        Group {
            if isSelected {
                selectedPin
            } else {
                standardPin
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "Dipilih" : "")
        .accessibilityHint("Ketuk dua kali untuk membuka detail sumber air")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Selected / Active Pin (Apple Maps Large Squircle Style)

    private var selectedPin: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(type.tint)
                    .frame(width: 54, height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 4)

                Image(systemName: type.symbolName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Anchor dot
            Circle()
                .fill(type.tint)
                .frame(width: 6, height: 6)
                .overlay(Circle().stroke(.white, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.3), radius: 2)

            // Prominent Title Label below pin
            if let label = label, !label.isEmpty {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .overlay(Capsule().stroke(type.tint.opacity(0.85), lineWidth: 1.2))
                    .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 160)
            }
        }
        .zIndex(100)
    }

    // MARK: - Standard Pin

    private var standardPin: some View {
        VStack(spacing: 3) {
            if let label = label, !label.isEmpty {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.black.opacity(0.82), in: Capsule())
                    .overlay(Capsule().stroke(type.tint.opacity(0.7), lineWidth: 0.8))
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1)
            }

            Image(systemName: type.symbolName)
                .font(.system(size: isDemoted ? 10 : 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(isDemoted ? 5 : 7)
                .background(type.tint.opacity(isDemoted ? 0.85 : 1), in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .scaleEffect(isDemoted ? 0.85 : 1)
                .shadow(radius: 1)
        }
    }

    private var accessibilityLabel: String {
        if let label, !label.isEmpty {
            return "\(type.displayName), \(label)"
        }

        return type.displayName
    }
}

/// The fire location the operator is refilling for.
/// Rendered as a prominent large squircle pin (56x56) with anchor dot and title label.
struct FireMarkerView: View {
    var title: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color(red: 0.85, green: 0.12, blue: 0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: Color.red.opacity(0.45), radius: 10, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)

                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Anchor dot
            Circle()
                .fill(Color.red)
                .frame(width: 7, height: 7)
                .overlay(Circle().stroke(.white, lineWidth: 1.2))
                .shadow(color: Color.black.opacity(0.35), radius: 2)

            // Location title label
            if let title = title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .overlay(Capsule().stroke(Color.red.opacity(0.85), lineWidth: 1.2))
                    .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 160)
            }
        }
        .zIndex(150)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title.map { "Lokasi kebakaran, \($0)" } ?? "Lokasi kebakaran")
    }
}
