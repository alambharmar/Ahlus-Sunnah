import SwiftUI

// MARK: - City Data for Selection
struct CityOption: Identifiable {
    let id = UUID()
    let city: String
    let country: String
    var combinedName: String { "\(city), \(country)" }
}

let availableCities: [CityOption] = [
    CityOption(city: "Dubai", country: "United Arab Emirates"),
    CityOption(city: "Abu Dhabi", country: "United Arab Emirates"),
    CityOption(city: "Mecca", country: "Saudi Arabia"),
    CityOption(city: "Madinah", country: "Saudi Arabia"),
    CityOption(city: "Riyadh", country: "Saudi Arabia"),
    CityOption(city: "London", country: "United Kingdom"),
    CityOption(city: "New York", country: "United States"),
    CityOption(city: "Los Angeles", country: "United States"),
    CityOption(city: "Karachi", country: "Pakistan"),
    CityOption(city: "Jakarta", country: "Indonesia"),
    CityOption(city: "Cairo", country: "Egypt"),
    CityOption(city: "Istanbul", country: "Turkey"),
    CityOption(city: "Kuala Lumpur", country: "Malaysia"),
    CityOption(city: "Toronto", country: "Canada"),
    CityOption(city: "Paris", country: "France"),
    CityOption(city: "Sydney", country: "Australia"),
    CityOption(city: "Berlin", country: "Germany"),
    CityOption(city: "Tokyo", country: "Japan"),
]

// MARK: - MAIN SETTINGS VIEW
struct SettingsView: View {
    @EnvironmentObject var manager: PrayerManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var showingLocationSheet = false
    @State private var showingDownloadSheet = false
    @State private var showingClearCacheAlert = false

    var body: some View {
        Form {
            NotificationSection(manager: manager)

            OfflineSection(
                manager: manager,
                showingDownloadSheet: $showingDownloadSheet,
                showingClearCacheAlert: $showingClearCacheAlert
            )

            LocationSection(
                manager: manager,
                showingLocationSheet: $showingLocationSheet
            )

            CalculationSection(manager: manager)

            TimeAdjustmentsSection(manager: manager)

            DisplaySection(manager: manager)

            AppearanceSection(themeManager: themeManager)
        }
        #if os(macOS)
            .formStyle(.grouped)
            .padding(.vertical, 20)
            .frame(minWidth: 520, minHeight: 420)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        #endif
        #if os(iOS)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        #else
            .navigationTitle("Settings")
        #endif
    }
}

// MARK: - SECTION 0: Notification Section
struct NotificationSection: View {
    @ObservedObject var manager: PrayerManager
    @State private var showTestAlert = false

    var body: some View {
        Section(header: Text("Notifications")) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                Text("Prayer Notifications")
                Spacer()
                Text(manager.isSilent ? "Disabled" : "Enabled")
                    .foregroundColor(manager.isSilent ? .red : .green)
                    .font(.caption)
            }

            Button(action: {
                manager.testNotification()
                showTestAlert = true
            }) {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.orange)
                    Text("Test Notification")
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Text(
                "Notifications will appear 5 seconds after pressing the test button. Make sure you have allowed notifications for this app in System Settings."
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .alert("Test Notification Sent", isPresented: $showTestAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "A test notification will appear in 5 seconds. If you don't see it, check your notification settings."
            )
        }
    }
}

// MARK: - SECTION 1: Offline Mode Section
struct OfflineSection: View {
    @ObservedObject var manager: PrayerManager
    @Binding var showingDownloadSheet: Bool
    @Binding var showingClearCacheAlert: Bool

    var body: some View {
        Section(header: Text("Offline Mode")) {

            HStack {
                Image(systemName: manager.isOfflineMode ? "wifi.slash" : "wifi")
                    .foregroundColor(manager.isOfflineMode ? .orange : .green)
                Text(manager.isOfflineMode ? "Offline Mode Active" : "Online Mode")
                Spacer()
            }

            HStack {
                Text("Cached Months")
                Spacer()
                Text("\(manager.offlineManager.totalCachedMonths)")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("Cache Size")
                Spacer()
                Text(manager.offlineManager.getCacheSize())
                    .foregroundColor(.gray)
            }

            if let lastSync = manager.offlineManager.lastSyncDate {
                HStack {
                    Text("Last Sync")
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundColor(.gray)
                }
            }

            Button {
                showingDownloadSheet = true
            } label: {
                Label("Download for Offline Use", systemImage: "arrow.down.circle.fill")
                    .foregroundColor(.green)
            }
            .sheet(isPresented: $showingDownloadSheet) {
                OfflineDownloadView(offlineManager: manager.offlineManager)
                    #if os(macOS)
                        .frame(width: 520, height: 420)
                    #endif
            }

            Button(role: .destructive) {
                showingClearCacheAlert = true
            } label: {
                Label("Clear Offline Cache", systemImage: "trash")
            }
            .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    manager.offlineManager.clearCache()
                }
            } message: {
                Text("This will delete all offline prayer time data.")
            }
        }
    }
}

// MARK: - SECTION 2: Location Section
struct LocationSection: View {
    @ObservedObject var manager: PrayerManager
    @Binding var showingLocationSheet: Bool

    var body: some View {
        Section(header: Text("Location")) {
            HStack {
                Text("Current City")
                Spacer()
                Text(manager.currentCity)
                    .foregroundColor(.gray)
            }

            Button {
                showingLocationSheet = true
            } label: {
                Label("Change City", systemImage: "location.magnifyingglass")
                    .foregroundColor(.blue)
            }
            .sheet(isPresented: $showingLocationSheet) {
                LocationSelectionView(manager: manager)
                    #if os(macOS)
                        .frame(width: 520, height: 420)
                    #endif
            }
        }
    }
}

// MARK: - SECTION 3: Calculation Section
struct CalculationSection: View {
    @ObservedObject var manager: PrayerManager

    let methods = [
        (2, "Islamic Society of North America (ISNA)"),
        (3, "Muslim World League (MWL)"),
        (5, "Egyptian General Authority of Survey"),
        (4, "Umm Al-Qura University, Makkah"),
        (1, "University of Islamic Sciences, Karachi"),
        (0, "Ithna Ashari (Shia)"),
        (7, "Institute of Geophysics, Tehran (Shia)"),
        (11, "MUIS - Singapore"),
        (13, "Diyanet - Turkey"),
        (15, "Moonsighting Committee World"),
    ]

    var body: some View {
        Section(header: Text("Prayer Calculation Settings")) {

            Picker("Calculation Method", selection: $manager.currentMethod) {
                ForEach(methods, id: \.0) { method in
                    Text(method.1).tag(method.0)
                }
            }
            .onChange(of: manager.currentMethod) { oldValue, value in
                Task {
                    await manager.fetchPrayerTimes(
                        city: manager.currentCity,
                        country: manager.currentCountry,
                        method: value,
                        school: manager.currentSchool,
                        for: manager.selectedDate
                    )
                }
            }

            Picker("Juristic Method (Asr)", selection: $manager.currentSchool) {
                Text("Shafi'i, Maliki, Hanbali").tag(0)
                Text("Hanafi").tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: manager.currentSchool) { oldValue, value in
                Task {
                    await manager.fetchPrayerTimes(
                        city: manager.currentCity,
                        country: manager.currentCountry,
                        method: manager.currentMethod,
                        school: value,
                        for: manager.selectedDate
                    )
                }
            }

            Stepper(
                "Dhuhr Offset: \(Int(manager.dhuhrMinutes)) min",
                value: $manager.dhuhrMinutes, in: 0...60)
        }
    }
}

// MARK: - SECTION 4: Time Adjustments
struct TimeAdjustmentsSection: View {
    @ObservedObject var manager: PrayerManager

    var body: some View {
        Section(header: Text("Time Adjustments")) {
            Stepper(
                "Iqama Offset: \(Int(manager.iqamaOffsetMinutes)) min",
                value: $manager.iqamaOffsetMinutes, in: 0...60)

            Stepper(
                "Qaza Offset: \(Int(manager.qazaOffsetMinutes)) min",
                value: $manager.qazaOffsetMinutes, in: 0...60)
        }
    }
}

// MARK: - SECTION 5: Display Options
struct DisplaySection: View {
    @ObservedObject var manager: PrayerManager

    var body: some View {
        Section(header: Text("App Display and Muting")) {
            Toggle("Mute All Notifications", isOn: $manager.isSilent)
                .tint(.red)

            Toggle("Show Iqama in Times Grid", isOn: $manager.showIqamaInGrid)

            Toggle("Show Qaza Button in Times Grid", isOn: $manager.showQazaInGrid)
        }
    }
}

// MARK: - SECTION 6: Appearance
struct AppearanceSection: View {
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        Section(header: Text("Appearance")) {
            Picker("Theme", selection: $themeManager.selectedTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            #if os(iOS)
                .pickerStyle(.menu)
            #endif

            #if os(macOS)
                // ── Royal Gold Accent ──────────────────────────────────
                Toggle(isOn: $themeManager.accentColorManager.useMultiColor) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.831, green: 0.667, blue: 0.333).opacity(0.2))
                                .frame(width: 26, height: 26)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(red: 0.831, green: 0.667, blue: 0.333))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Royal Gold Accent")
                                .font(.body)
                            Text("Antique masjid gold — inspired by Islamic architecture")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(Color(red: 0.831, green: 0.667, blue: 0.333))

                HStack {
                    Text("Active Accent")
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(themeManager.accentColorManager.accentColor)
                            .frame(width: 14, height: 14)
                        Text(
                            themeManager.accentColorManager.useMultiColor ? "Royal Gold" : "System"
                        )
                        .foregroundColor(.secondary)
                        .font(.caption)
                    }
                }

                Text("When Royal Gold is disabled, the app uses your macOS system accent color.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            #endif

            // ── Background Palette ─────────────────────────────────
            HStack {
                Text("Background Palette")
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 0.980, green: 0.980, blue: 0.969))  // Ivory
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
                    Circle()
                        .fill(Color(red: 0.102, green: 0.102, blue: 0.094))  // Onyx
                        .frame(width: 14, height: 14)
                    Text("Royal White & Onyx")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Location Selection Sheet
struct LocationSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: PrayerManager

    @State private var searchText = ""

    var filteredCities: [CityOption] {
        if searchText.isEmpty { return availableCities }
        return availableCities.filter {
            $0.combinedName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCities) { city in
                    Button {
                        manager.currentCity = city.city
                        manager.currentCountry = city.country

                        Task {
                            await manager.fetchPrayerTimes(
                                city: city.city,
                                country: city.country,
                                method: manager.currentMethod,
                                school: manager.currentSchool,
                                for: manager.selectedDate
                            )
                        }

                        dismiss()
                    } label: {
                        Text(city.combinedName)
                    }
                }

                if filteredCities.isEmpty {
                    Text("No results found").foregroundColor(.gray)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Location")
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                #else
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                #endif
            }
        }
    }
}

// MARK: - Offline Download Sheet
struct OfflineDownloadView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var offlineManager: OfflineDataManager

    @State private var selectedCities: Set<String> = []
    @State private var selectedMethods: Set<Int> = [2]
    @State private var selectedSchools: Set<Int> = [0, 1]
    @State private var monthsAhead: Int = 6

    let allMethods = [
        (3, "Muslim World League"),
        (2, "ISNA"),
        (5, "Egyptian Authority"),
        (4, "Umm Al-Qura"),
        (1, "Karachi University"),
    ]

    var estimatedDataSize: String {
        let cityCount = selectedCities.count
        let methodCount = selectedMethods.count
        let schoolCount = selectedSchools.count
        let months = monthsAhead

        if cityCount == 0 || methodCount == 0 || schoolCount == 0 || months == 0 {
            return ByteCountFormatter.string(fromByteCount: 0, countStyle: .file)
        }

        let combos = cityCount * methodCount * schoolCount * months
        let kb = combos * 15
        let bytes = Int64(kb) * 1024
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    var body: some View {
        NavigationView {
            Form {
                if offlineManager.isDownloading {
                    Section {
                        VStack(spacing: 15) {
                            ProgressView(value: offlineManager.downloadProgress)
                            Text(offlineManager.downloadStatus)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(Int(offlineManager.downloadProgress * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 20)
                    }
                } else {
                    // Cities
                    Section(header: Text("Select Cities")) {
                        ForEach(availableCities) { city in
                            Toggle(
                                city.combinedName,
                                isOn: Binding(
                                    get: { selectedCities.contains(city.city) },
                                    set: { isSelected in
                                        if isSelected {
                                            _ = selectedCities.insert(city.city)
                                        } else {
                                            selectedCities.remove(city.city)
                                        }
                                    }
                                ))
                        }

                        Button("Select All") {
                            selectedCities = Set(availableCities.map { $0.city })
                        }
                        .foregroundColor(.blue)
                    }

                    // Methods
                    Section(header: Text("Calculation Methods")) {
                        ForEach(allMethods, id: \.0) { method in
                            Toggle(
                                method.1,
                                isOn: Binding(
                                    get: { selectedMethods.contains(method.0) },
                                    set: { isSelected in
                                        if isSelected {
                                            _ = selectedMethods.insert(method.0)
                                        } else {
                                            selectedMethods.remove(method.0)
                                        }
                                    }
                                ))
                        }
                    }

                    // Schools
                    Section(header: Text("Juristic Schools")) {
                        Toggle(
                            "Shafi'i, Maliki, Hanbali",
                            isOn: Binding(
                                get: { selectedSchools.contains(0) },
                                set: { isSelected in
                                    if isSelected {
                                        _ = selectedSchools.insert(0)
                                    } else {
                                        selectedSchools.remove(0)
                                    }
                                }
                            ))
                        Toggle(
                            "Hanafi",
                            isOn: Binding(
                                get: { selectedSchools.contains(1) },
                                set: { isSelected in
                                    if isSelected {
                                        _ = selectedSchools.insert(1)
                                    } else {
                                        selectedSchools.remove(1)
                                    }
                                }
                            ))
                    }

                    // Time range
                    Section(header: Text("Time Range")) {
                        Stepper("Months Ahead: \(monthsAhead)", value: $monthsAhead, in: 1...24)
                    }

                    Section(header: Text("Summary")) {
                        HStack {
                            Text("Total Combinations")
                            Spacer()
                            Text(
                                "\(selectedCities.count * selectedMethods.count * selectedSchools.count * monthsAhead)"
                            )
                            .foregroundColor(.gray)
                        }

                        HStack {
                            Text("Estimated Size")
                            Spacer()
                            Text(estimatedDataSize)
                                .foregroundColor(.gray)
                        }
                    }

                    Section {
                        Button {
                            startDownload()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Start Download", systemImage: "arrow.down.circle.fill")
                                Spacer()
                            }
                        }
                        .foregroundColor(.green)
                        .disabled(
                            selectedCities.isEmpty || selectedMethods.isEmpty
                                || selectedSchools.isEmpty
                        )
                    }
                }
            }
            .navigationTitle("Offline Download")
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(offlineManager.isDownloading ? "Done" : "Cancel") {
                            dismiss()
                        }
                        .disabled(
                            offlineManager.isDownloading && offlineManager.downloadProgress < 1.0)
                    }
                #else
                    ToolbarItem(placement: .cancellationAction) {
                        Button(offlineManager.isDownloading ? "Done" : "Cancel") {
                            dismiss()
                        }
                        .disabled(
                            offlineManager.isDownloading && offlineManager.downloadProgress < 1.0)
                    }
                #endif
            }
        }
    }

    func startDownload() {
        let cities =
            availableCities
            .filter { selectedCities.contains($0.city) }
            .map { (city: $0.city, country: $0.country) }

        Task {
            await offlineManager.downloadAllData(
                cities: cities,
                methods: Array(selectedMethods),
                schools: Array(selectedSchools),
                monthsAhead: monthsAhead
            )
        }
    }
}
