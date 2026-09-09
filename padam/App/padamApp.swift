//
//  padamApp.swift
//  padam
//
//  Created by Ivandohan Samuel Siregar on 07/09/26.
//

import SwiftUI

@main
struct padamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.locale, Locale(identifier: AppInfo.accessibilityLocaleIdentifier))
        }
    }
}
