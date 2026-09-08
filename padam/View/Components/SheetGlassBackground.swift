//
//  SheetGlassBackground.swift
//  padam
//
//  Liquid Glass background for Apple Maps bottom sheets:
//  - True native UIKit blur effect (UIVisualEffectView) for optical refraction.
//  - Liquid Glass translucency and sheen in collapsed (small) and half-expanded (.medium) detents.
//  - Smoothly transitions to a solid background when fully expanded (.large).
//

import SwiftUI
import UIKit

/// Native UIKit blur effect wrapper to guarantee pure, high-translucency liquid glass blur
struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.backgroundColor = .clear
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

/// Liquid Glass presentation background for bottom sheets
struct SheetGlassBackground: View {
    var isFullyExpanded: Bool

    var body: some View {
        ZStack {
            if isFullyExpanded {
                // Solid background when fully expanded
                Color(red: 0.11, green: 0.11, blue: 0.13)
                    .ignoresSafeArea()
            } else {
                // Pure Apple Liquid Glass blur in collapsed and half-expanded modes
                VisualEffectBlur(style: .systemUltraThinMaterialDark)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isFullyExpanded)
    }
}
