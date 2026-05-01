//
//  AccentColorManager.swift
//  WaslApp
//
//  macOS Accent Color Manager - Adapts to system accent color
//

import Combine
import SwiftUI

#if os(macOS)
    import AppKit

    class AccentColorManager: ObservableObject {
        @Published var currentAccentColor: Color = .green
        @Published var useMultiColor: Bool {
            didSet {
                UserDefaults.standard.set(useMultiColor, forKey: "useMultiColor")
                updateAccentColor()
            }
        }

        private var cancellables = Set<AnyCancellable>()

        init() {
            // Load saved preference - default to TRUE for green accent
            let hasLaunchedBefore = UserDefaults.standard.object(forKey: "useMultiColor") != nil
            if hasLaunchedBefore {
                self.useMultiColor = UserDefaults.standard.bool(forKey: "useMultiColor")
            } else {
                // First launch - default to green (multi-color mode)
                self.useMultiColor = true
                UserDefaults.standard.set(true, forKey: "useMultiColor")
            }

            // Set initial color
            updateAccentColor()

            // Observe system accent color changes
            NotificationCenter.default.publisher(
                for: NSNotification.Name("AppleColorPreferencesChangedNotification")
            )
            .sink { [weak self] _ in
                self?.updateAccentColor()
            }
            .store(in: &cancellables)

            // Also observe appearance changes
            NotificationCenter.default.publisher(
                for: NSNotification.Name("NSSystemColorsDidChangeNotification")
            )
            .sink { [weak self] _ in
                self?.updateAccentColor()
            }
            .store(in: &cancellables)
        }

        private func updateAccentColor() {
            if useMultiColor {
                // Royal antique gold — inspired by masjid dome gilding (#D4AA55)
                currentAccentColor = Color(red: 0.831, green: 0.667, blue: 0.333)
            } else {
                // Adapt to system accent color
                currentAccentColor = Color(NSColor.controlAccentColor)
            }
        }

        // Convenience computed property for easy access
        var accentColor: Color {
            return currentAccentColor
        }
    }

#else

    // Fallback for iOS/watchOS - uses gold accent color
    class AccentColorManager: ObservableObject {
        // Gold accent color inspired by masjid aesthetics (R239 G230 B80)
        @Published var currentAccentColor: Color = Color(red: 0.937, green: 0.902, blue: 0.314)
        @Published var useMultiColor: Bool = false

        var accentColor: Color {
            return currentAccentColor
        }
    }

#endif
