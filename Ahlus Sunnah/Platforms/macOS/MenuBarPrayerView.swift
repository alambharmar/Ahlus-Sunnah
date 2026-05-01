import SwiftUI

#if os(macOS)

    // MARK: - Menu Bar Popup View

    struct MenuBarPrayerView: View {
        @EnvironmentObject var prayerManager: PrayerManager

        private let accentGold = Color(red: 0.831, green: 0.667, blue: 0.333)  // Royal gold #D4AA55

        // Time formatter for displaying individual prayer times
        private var timeFormatter: DateFormatter {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f
        }

        var body: some View {
            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────
                headerView

                Divider()

                // ── Prayer Times List ────────────────────────────────────
                VStack(spacing: 2) {
                    ForEach(prayerManager.prayerTimes) { pt in
                        prayerRow(for: pt)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                // ── Footer ───────────────────────────────────────────────
                footerView
            }
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
            )
        }

        // MARK: - Header
        private var headerView: some View {
            HStack(spacing: 10) {
                // Crescent icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(accentGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wasl")
                        .font(.system(size: 16, weight: .bold))

                    // Today's date (short)
                    Text(Date(), style: .date)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Next prayer countdown badge
                if let next = prayerManager.nextPrayer {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(next.prayer.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(accentGold)
                        Text(prayerManager.countdownString)
                            .font(.system(size: 11, weight: .medium).monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }

        // MARK: - Prayer Row
        @ViewBuilder
        private func prayerRow(for prayerTime: PrayerTime) -> some View {
            let isNext = prayerManager.nextPrayer?.prayer == prayerTime.prayer
            let isPast = prayerTime.time < Date() && !isNext

            HStack(spacing: 10) {
                // Colored circle icon
                ZStack {
                    Circle()
                        .fill(prayerTime.prayer.displayColor.opacity(isNext ? 0.25 : 0.12))
                        .frame(width: 30, height: 30)

                    Image(systemName: prayerIcon(for: prayerTime.prayer))
                        .font(.system(size: 12))
                        .foregroundStyle(prayerTime.prayer.displayColor)
                }

                // Prayer name
                Text(prayerTime.prayer.rawValue)
                    .font(.system(size: 13, weight: isNext ? .semibold : .regular))
                    .foregroundStyle(isPast ? Color.secondary : Color.primary)

                Spacer()

                // Time
                Text(timeFormatter.string(from: prayerTime.time))
                    .font(
                        .system(size: 13, weight: isNext ? .semibold : .regular).monospacedDigit()
                    )
                    .foregroundStyle(isPast ? Color.secondary : Color.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isNext ? accentGold.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isNext ? accentGold.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.3), value: isNext)
        }

        // MARK: - Footer
        private var footerView: some View {
            HStack {
                // City label
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(prayerManager.currentCity)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Open main window button
                Button {
                    openMainWindow()
                } label: {
                    HStack(spacing: 4) {
                        Text("Open Wasl")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(accentGold.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }

        // MARK: - Helpers

        private func prayerIcon(for prayer: Prayer) -> String {
            switch prayer {
            case .Fajr: return "sunrise.fill"
            case .Sunrise: return "sun.horizon.fill"
            case .Dhuhr: return "sun.max.fill"
            case .Asr: return "sun.haze.fill"
            case .Maghrib: return "sunset.fill"
            case .Isha: return "moon.fill"
            }
        }

        private func openMainWindow() {
            // Activate the app and bring the main window to front
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows {
                if window.title != "" || window.isVisible {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
            // If no window is visible, open a new one
            if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
        }
    }

    // MARK: - Menu Bar Title Label (the text shown in the menu bar itself)

    struct MenuBarLabel: View {
        @EnvironmentObject var prayerManager: PrayerManager
        private let accentGold = Color(red: 0.831, green: 0.667, blue: 0.333)  // Royal gold #D4AA55

        var body: some View {
            HStack(spacing: 5) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 13))

                if let next = prayerManager.nextPrayer {
                    Text(
                        "\(next.prayer.rawValue) · \(shortCountdown(prayerManager.countdownString))"
                    )
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                } else {
                    Text("Wasl")
                        .font(.system(size: 12, weight: .medium))
                }
            }
        }

        /// Converts "1h 23m 10s" → "1h 23m" for brevity in the menu bar
        private func shortCountdown(_ full: String) -> String {
            // Drop the seconds component for cleaner display
            let parts = full.components(separatedBy: " ")
            let filtered = parts.filter { !$0.hasSuffix("s") || $0.hasSuffix("ms") }
            let result = filtered.prefix(2).joined(separator: " ")
            return result.isEmpty ? full : result
        }
    }

#endif
