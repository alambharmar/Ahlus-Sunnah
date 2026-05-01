//
//  macOSApp.swift
//  WaslApp macOS
//
//  Entry point for macOS app
//

import SwiftUI

#if os(macOS)
@main
struct WaslApp_macOS: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var prayerManager = PrayerManager()

    var body: some Scene {
        WindowGroup {
            MainSidebarView()
                .environmentObject(themeManager)
                .environmentObject(prayerManager)
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                .background(backgroundView)
        }
        .defaultSize(width: 700, height: 520)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarPrayerView()
                .environmentObject(prayerManager)
        } label: {
            MenuBarLabel()
                .environmentObject(prayerManager)
        }
        .menuBarExtraStyle(.window)
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
#endif
