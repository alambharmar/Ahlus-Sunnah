//
//  ThemeManager.swift
//  WaslApp
//
//  Theme management for light/dark mode — Royal White/Gold palette
//

import Combine
import SwiftUI

enum AppTheme: String, CaseIterable {
    case automatic = "Automatic"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "appTheme")
        }
    }

    @Published var accentColorManager = AccentColorManager()

    init() {
        let savedTheme =
            UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.automatic.rawValue
        self.selectedTheme = AppTheme(rawValue: savedTheme) ?? .automatic
    }

    var backgroundColor: Color {
        #if os(iOS)
            return Color(UIColor.systemBackground)
        #else
            return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    // Royal palette — warm ivory-white (light) and warm off-black (dark)
    // Inspired by the marble and stone of masjid architecture
    static let darkBackground = Color(red: 0.102, green: 0.102, blue: 0.094)  // #1A1A18 warm onyx
    static let lightBackground = Color(red: 0.980, green: 0.980, blue: 0.969)  // #FAFAF7 warm ivory

    #if os(iOS)
        static let iOSDarkBackground = Color(red: 0.102, green: 0.102, blue: 0.094)
    #endif
}
