//
//  iOSApp.swift
//  WaslApp iOS
//
//  Entry point for iOS app
//

import SwiftUI

#if os(iOS)
@main
struct WaslApp_iOS: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var prayerManager = PrayerManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environmentObject(prayerManager)
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                .background(backgroundView)
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if themeManager.selectedTheme.colorScheme == .dark {
            ThemeManager.darkBackground
                .ignoresSafeArea()
        } else if themeManager.selectedTheme.colorScheme == .light {
            ThemeManager.lightBackground
                .ignoresSafeArea()
        } else {
            Color.clear
        }
    }
}

private struct RootView: View {
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadRootView()
        } else {
            MainTabView()
        }
    }
}
#endif
