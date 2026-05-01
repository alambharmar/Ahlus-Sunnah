import Foundation
import SwiftUI
import Combine
import CoreLocation
import Network
import UserNotifications

// MARK: - Network Monitor (NEW!)
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Integrated Prayer Manager (TempNamaz Logic + Wasl UI Interface)

final class PrayerManager: ObservableObject {

    // MARK: - Location Manager Integration (Keep your original)
    @ObservedObject var locationManager = LocationManager()
    private var locationCancellable: AnyCancellable?

    // MARK: - NEW: Network Monitor
    @StateObject private var networkMonitor = NetworkMonitor()
    private var networkCancellable: AnyCancellable?

    // MARK: - NEW: Offline Manager (from TempNamaz)
    let offlineManager: OfflineDataManager
    
    // MARK: - NEW: API Data Storage
    @Published var dailyTimings: [PrayerDayData] = []
    @Published var isLoading = false
    @Published var isOfflineMode: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - NEW: Settings (Replaces old calculator settings)
    @Published var currentCity: String = "Dubai"
    @Published var currentCountry: String = "United Arab Emirates"
    @Published var currentMethod: Int = 2 // ISNA by default
    @Published var currentSchool: Int = 0 // Shafi'i by default
    
    // MARK: - Published Properties (Keep your original interface)
    @Published var prayerTimes: [PrayerTime] = []
    @Published var nextPrayer: PrayerTime?
    @Published var countdownString: String = "Calculating..."
    @Published var selectedDate: Date = Date()
    @Published var isSilent: Bool = false
    @Published var showIqamaInGrid: Bool = false
    @Published var showQazaInGrid: Bool = false

    // MARK: - UI Properties (Keep your original)
    @Published var iqamaOffsetMinutes: Double = 10
    @Published var qazaOffsetMinutes: Double = 45
    @Published var dhuhrMinutes: Double = 0
    let qazaPurple = Color(red: 0.6, green: 0.4, blue: 0.8)

    // MARK: - Qaza Tracking (Keep your original)
    @Published var qazaCounts: [Prayer: Int] = [
        .Fajr: 0, .Dhuhr: 0, .Asr: 0, .Maghrib: 0, .Isha: 0
    ]

    private var timer: AnyCancellable?
    private var isFetchingNextDay = false

    private lazy var countdownFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    // MARK: - AppStorage for Settings Persistence
    @AppStorage("selectedCity") private var storedCity: String = "Dubai"
    @AppStorage("selectedCountry") private var storedCountry: String = "United Arab Emirates"
    @AppStorage("calculationMethod") private var storedMethod: Int = 2
    @AppStorage("juristicSchool") private var storedSchool: Int = 0

    init() {
        // Initialize offline manager
        self.offlineManager = OfflineDataManager()
        
        // Initialize network monitor
        let monitor = NetworkMonitor()
        self._networkMonitor = StateObject(wrappedValue: monitor)
        
        // Load saved settings
        self.currentCity = storedCity
        self.currentCountry = storedCountry
        self.currentMethod = storedMethod
        self.currentSchool = storedSchool
        
        // Request notification permissions
        requestNotificationPermission()
        
        // Load from cache initially
        loadFromOfflineCache()
        
        // Setup location monitoring (keep your original)
        locationCancellable = locationManager.objectWillChange
            .sink { _ in
                // When location changes significantly, you could update city
                // For now, we'll use manual city selection
            }
        
        // Monitor network changes
        networkCancellable = monitor.$isConnected
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                
                // If we go offline and have no data, show offline mode
                if !isConnected && !self.dailyTimings.isEmpty {
                    self.isOfflineMode = true
                    self.errorMessage = "No internet - Using offline data"
                }
                
                // If we come back online, try to refresh
                if isConnected && self.isOfflineMode {
                    Task {
                        await self.fetchPrayerTimes(
                            city: self.currentCity,
                            country: self.currentCountry,
                            method: self.currentMethod,
                            school: self.currentSchool,
                            for: self.selectedDate
                        )
                    }
                }
            }
        
        // Initial fetch
        Task {
            await fetchPrayerTimes(
                city: currentCity,
                country: currentCountry,
                method: currentMethod,
                school: currentSchool,
                for: selectedDate
            )
        }
        
        setupTimer()
    }
    
    // MARK: - NEW: Load from Offline Cache
    private func loadFromOfflineCache() {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedDate)
        let year = calendar.component(.year, from: selectedDate)
        
        let key = PrayerCacheKey(
            city: currentCity,
            country: currentCountry,
            method: currentMethod,
            school: currentSchool,
            month: month,
            year: year
        )
        
        if let cached = offlineManager.getCachedData(for: key) {
            self.dailyTimings = cached.data
            self.isOfflineMode = true
            convertAPIDataToPrayerTimes(for: selectedDate)
        }
    }
    
    // MARK: - NEW: Fetch Prayer Times from API
    func fetchPrayerTimes(city: String, country: String, method: Int, school: Int, for date: Date) async {
        
        // Update settings
        DispatchQueue.main.async {
            self.isLoading = true
            self.currentCity = city
            self.currentCountry = country
            self.currentMethod = method
            self.currentSchool = school
            
            // Save to AppStorage
            self.storedCity = city
            self.storedCountry = country
            self.storedMethod = method
            self.storedSchool = school
        }
        
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let key = PrayerCacheKey(
            city: city,
            country: country,
            method: method,
            school: school,
            month: month,
            year: year
        )
        
        // Check cache first
        if let cached = offlineManager.getCachedData(for: key) {
            DispatchQueue.main.async {
                self.dailyTimings = cached.data
                self.isLoading = false
                self.isOfflineMode = true
                self.convertAPIDataToPrayerTimes(for: date)
            }
            
            // Update in background
            await fetchFromAPIAndCache(key: key, date: date)
            return
        }
        
        // Fetch from API
        await fetchFromAPIAndCache(key: key, date: date)
    }
    
    private func fetchFromAPIAndCache(key: PrayerCacheKey, date: Date) async {
        // Check network connectivity first
        guard networkMonitor.isConnected else {
            print("⚠️ No network connection, using cache only")
            DispatchQueue.main.async {
                self.isOfflineMode = true
                self.errorMessage = "No internet - Using offline data"
                self.isLoading = false
            }
            return
        }
        
        let baseURL = "https://api.aladhan.com/v1/calendarByCity"
        
        guard let encodedCity = key.city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedCountry = key.country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid city or country"
                self.isLoading = false
            }
            return
        }
        
        let urlString = "\(baseURL)?city=\(encodedCity)&country=\(encodedCountry)&method=\(key.method)&school=\(key.school)&month=\(key.month)&year=\(key.year)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Could not create URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CalendarAPIResponse.self, from: data)
            
            // Save to cache
            offlineManager.saveToCache(response.data, for: key)
            
            DispatchQueue.main.async {
                self.dailyTimings = response.data
                self.isLoading = false
                self.isOfflineMode = false
                self.errorMessage = nil
                self.convertAPIDataToPrayerTimes(for: date)
            }
        } catch {
            print("Network Error: \(error)")
            
            // Try cache as fallback
            if let cached = offlineManager.getCachedData(for: key) {
                DispatchQueue.main.async {
                    self.dailyTimings = cached.data
                    self.isLoading = false
                    self.isOfflineMode = true
                    self.errorMessage = "Using offline data"
                    self.convertAPIDataToPrayerTimes(for: date)
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Network failed and no cache available"
                }
            }
        }
    }
    
    // MARK: - NEW: Convert API Data to PrayerTime Array
    private func convertAPIDataToPrayerTimes(for date: Date) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        // Find the day data for the selected date
        guard let dayData = dailyTimings.first(where: { dayData in
            guard let apiDate = dateFormatter.date(from: dayData.date.gregorian.date) else { return false }
            return calendar.isDate(apiDate, inSameDayAs: date)
        }) else {
            print("No data found for selected date")
            return
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        var newTimes: [PrayerTime] = []
        
        for (prayerName, timeString) in dayData.timings.allTimings {
            // Clean time string (remove timezone like "+04")
            let cleanTime = timeString.components(separatedBy: " ").first ?? timeString
            
            guard let timeOnly = timeFormatter.date(from: cleanTime) else { continue }
            let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnly)
            
            guard let prayerDate = calendar.date(bySettingHour: timeComponents.hour!,
                                                  minute: timeComponents.minute!,
                                                  second: 0,
                                                  of: date) else { continue }
            
            // Apply Dhuhr offset if it's Dhuhr
            let finalTime = prayerName == "Dhuhr" ?
                prayerDate.addingTimeInterval(dhuhrMinutes * 60) : prayerDate
            
            // Map to Prayer enum
            if let prayer = Prayer(rawValue: prayerName) {
                newTimes.append(PrayerTime(prayer: prayer, time: finalTime, isMuted: isSilent))
            }
        }
        
        prayerTimes = newTimes.sorted { $0.time.timeIntervalSince1970 < $1.time.timeIntervalSince1970 }
        updateProgressAndNextPrayer()
        
        // Schedule notifications after prayer times are updated
        schedulePrayerNotifications()
    }

    // MARK: - Public Interface (Keep your original methods)
    
    func updateSelectedDayTimes(for date: Date) {
        selectedDate = date
        
        // If we have data for this month, just convert it
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let currentMonth = calendar.component(.month, from: dailyTimings.first?.date.gregorian.date.toDate() ?? Date())
        let currentYear = calendar.component(.year, from: dailyTimings.first?.date.gregorian.date.toDate() ?? Date())
        
        if month == currentMonth && year == currentYear && !dailyTimings.isEmpty {
            convertAPIDataToPrayerTimes(for: date)
        } else {
            // Need to fetch new month
            Task {
                await fetchPrayerTimes(
                    city: currentCity,
                    country: currentCountry,
                    method: currentMethod,
                    school: currentSchool,
                    for: date
                )
            }
        }
    }

    func setupTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0, tolerance: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateProgressAndNextPrayer()
            }
    }

    func date(for dayIndex: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: dayIndex, to: today) ?? Date()
    }

    // MARK: - Offset Calculation Functions (Keep your original)
    
    func calculateIqamaTime(for adhanTime: Date) -> Date {
        return adhanTime.addingTimeInterval(iqamaOffsetMinutes * 60)
    }

    func calculateQazaTime(for adhanTime: Date) -> Date {
        return adhanTime.addingTimeInterval(qazaOffsetMinutes * 60)
    }

    // MARK: - Progress Tracking (Keep your original)

    func updateProgressAndNextPrayer() {
        let now = Date()
        var nextPrayerFound = false

        for prayerTime in prayerTimes.sorted(by: { $0.time.compare($1.time) == .orderedAscending }) {
            if prayerTime.time.timeIntervalSince(now) > 0 {
                nextPrayer = prayerTime
                nextPrayerFound = true

                let interval = nextPrayer!.time.timeIntervalSinceNow
                countdownString = countdownFormatter.string(from: interval) ?? "0h 0m 0s"
                break
            }
        }

        if !nextPrayerFound {
            guard !isFetchingNextDay else { return }
            isFetchingNextDay = true
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

            Task { [weak self] in
                guard let self = self else { return }
                await self.fetchPrayerTimes(
                    city: self.currentCity,
                    country: self.currentCountry,
                    method: self.currentMethod,
                    school: self.currentSchool,
                    for: tomorrow
                )
                await MainActor.run {
                    self.isFetchingNextDay = false
                }
            }
        }
    }

    func getActiveProgressPrayers() -> [Prayer] {
        return [.Dhuhr, .Asr, .Maghrib]
    }

    func trackerRatio() -> Double {
        guard let fajrTime = prayerTimes.first(where: { $0.prayer == .Fajr })?.time,
              let ishaTime = prayerTimes.first(where: { $0.prayer == .Isha })?.time
        else { return 0.0 }

        let now = Date()
        let totalDuration = ishaTime.timeIntervalSince(fajrTime)
        let elapsedTime = now.timeIntervalSince(fajrTime)

        // Clamp between 0 and 1
        let ratio = max(0.0, min(1.0, elapsedTime / totalDuration))
        
        // If we're before Fajr, return 0
        if now < fajrTime {
            return 0.0
        }
        
        // If we're after Isha, return 1
        if now > ishaTime {
            return 1.0
        }
        
        return ratio
    }

    func getProgressRatioPoint(for prayer: Prayer) -> Double {
        // Calculate the actual position of each prayer on the timeline
        guard let fajrTime = prayerTimes.first(where: { $0.prayer == .Fajr })?.time,
              let ishaTime = prayerTimes.first(where: { $0.prayer == .Isha })?.time,
              let prayerTime = prayerTimes.first(where: { $0.prayer == prayer })?.time
        else { return 0.0 }
        
        let totalDuration = ishaTime.timeIntervalSince(fajrTime)
        let prayerDuration = prayerTime.timeIntervalSince(fajrTime)
        
        return max(0.0, min(1.0, prayerDuration / totalDuration))
    }

    // MARK: - Qaza Tracking Logic (Keep your original)
    
    func incrementQazaCount(for prayer: Prayer) {
        if let currentCount = qazaCounts[prayer] { qazaCounts[prayer] = currentCount + 1 }
    }

    func decrementQazaCount(for prayer: Prayer) {
        if let currentCount = qazaCounts[prayer], currentCount > 0 { qazaCounts[prayer] = currentCount - 1 }
    }

    func resetAllQazaCounts() {
        for key in qazaCounts.keys { qazaCounts[key] = 0 }
    }
    
    // MARK: - Notification System
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func schedulePrayerNotifications() {
        // Remove all pending notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Don't schedule if silent mode is on
        if isSilent {
            print("🔕 Silent mode is ON - No notifications scheduled")
            return
        }
        
        let now = Date()
        
        for prayerTime in prayerTimes {
            // Skip if this prayer time has passed or if it's Sunrise
            guard prayerTime.time > now, prayerTime.prayer != .Sunrise else { continue }
            
            // Skip if notifications are disabled for this prayer
            guard prayerTime.notificationsEnabled else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "🕌 \(prayerTime.prayer.rawValue) Prayer Time"
            content.body = "It's time for \(prayerTime.prayer.rawValue) prayer"
            content.sound = .default
            
            // Create trigger
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: prayerTime.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // Create request
            let identifier = "prayer_\(prayerTime.prayer.rawValue)_\(prayerTime.time.timeIntervalSince1970)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Schedule notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling notification for \(prayerTime.prayer.rawValue): \(error.localizedDescription)")
                } else {
                    print("✅ Notification scheduled for \(prayerTime.prayer.rawValue) at \(prayerTime.time)")
                }
            }
        }
    }
    
    func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🕌 Test Notification"
        content.body = "Prayer notifications are working correctly!"
        content.sound = .default
        
        // Trigger in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Test notification error: \(error.localizedDescription)")
            } else {
                print("✅ Test notification will appear in 5 seconds")
            }
        }
    }
}

// MARK: - Helper Extension for Date Parsing
extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.date(from: self)
    }
}
