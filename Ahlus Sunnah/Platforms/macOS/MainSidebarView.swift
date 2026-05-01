import SwiftUI

#if os(macOS)

// MARK: - Royal Gold Palette (macOS)

extension Color {
    /// Antique gold — the primary accent for the Royal theme
    static let royalGold = Color(red: 0.831, green: 0.667, blue: 0.333)
    /// Warm ivory-white background
    static let royalIvory = Color(red: 0.980, green: 0.980, blue: 0.969)
    /// Warm off-black background
    static let royalOnyx = Color(red: 0.102, green: 0.102, blue: 0.094)
    /// Muted warm secondary text
    static let royalMuted = Color(red: 0.541, green: 0.502, blue: 0.439)
}

struct MainSidebarView: View {
    @EnvironmentObject private var prayerManager: PrayerManager
    @StateObject private var tasbeehManager = TasbeehManager()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TimesView()
                .tabItem {
                    Label("Times", systemImage: "clock.fill")
                }
                .tag(0)

            TasbeehView_macOS()
                .tabItem {
                    Label("Tasbeeh", systemImage: "circle.dotted")
                }
                .tag(2)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(3)
        }
        .frame(width: 700, height: 520)
        .fixedSize()
        .tint(Color.royalGold)
        .environmentObject(prayerManager)
        .environmentObject(tasbeehManager)
        .background(backgroundView.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .windowToolbar)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if themeManager.selectedTheme.colorScheme == .dark {
            ThemeManager.darkBackground
        } else if themeManager.selectedTheme.colorScheme == .light {
            ThemeManager.lightBackground
        } else {
            Color.clear
        }
    }
}

#Preview {
    MainSidebarView()
        .frame(width: 700, height: 520)
}

#endif
