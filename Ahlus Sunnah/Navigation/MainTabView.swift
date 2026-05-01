import SwiftUI

// MARK: - iOS/iPadOS Tab View

struct MainTabView: View {
    @StateObject private var prayerManager = PrayerManager()
    @StateObject private var tasbeehManager = TasbeehManager()
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TabView {
            TimesView()
                .tabItem {
                    Label("Times", systemImage: "clock.fill")
                }

            QiblaView()
                .tabItem {
                    Label("Qibla", systemImage: "location.north.fill")
                }

            TasbeehView(manager: tasbeehManager)
                .tabItem {
                    Label("Tasbeeh", systemImage: "circle.dotted")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            MoreTabView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
        }
        .accentColor(Color(red: 0.937, green: 0.902, blue: 0.314))
        .environmentObject(prayerManager)
        .environmentObject(tasbeehManager)
    }
}

// MARK: - More Tab View for iOS

struct MoreTabView: View {
    @EnvironmentObject var prayerManager: PrayerManager
    @EnvironmentObject var themeManager: ThemeManager

    // Gold accent color for consistency
    private let accentGold = Color(red: 0.937, green: 0.902, blue: 0.314)

    enum MoreItem: String, Identifiable, CaseIterable {
        case qaza = "Qaza"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .qaza: return "checklist.checked"
            case .settings: return "gearshape.fill"
            }
        }
    }

    private func colorFor(_ item: MoreItem) -> Color {
        switch item {
        case .qaza: return .blue
        case .settings: return .gray
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: MoreItem.qaza) {
                        Label {
                            Text("Qaza Tracker")
                        } icon: {
                            Image(systemName: MoreItem.qaza.icon)
                                .foregroundColor(colorFor(.qaza))
                        }
                    }
                }

                Section {
                    NavigationLink(value: MoreItem.settings) {
                        Label {
                            Text("Settings")
                        } icon: {
                            Image(systemName: MoreItem.settings.icon)
                                .foregroundColor(colorFor(.settings))
                        }
                    }
                }
            }
            .navigationTitle("More")
            .navigationDestination(for: MoreItem.self) { item in
                switch item {
                case .qaza:
                    QazaView()
                        .environmentObject(prayerManager)
                case .settings:
                    SettingsView()
                        .environmentObject(prayerManager)
                        .environmentObject(themeManager)
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
