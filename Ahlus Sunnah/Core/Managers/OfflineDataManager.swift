import SwiftUI
import Foundation

// MARK: - Offline Data Manager
@Observable
class OfflineDataManager {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    var totalCachedMonths: Int = 0
    var lastSyncDate: Date?
    var isDownloading: Bool = false
    var downloadProgress: Double = 0.0
    var downloadStatus: String = ""
    
    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("PrayerTimesCache", isDirectory: true)
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        loadCacheMetadata()
    }
    
    // MARK: - Cache Management
    
    func getCachedData(for key: PrayerCacheKey) -> CachedPrayerData? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.identifier).json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let cached = try? JSONDecoder().decode(CachedPrayerData.self, from: data) else {
            return nil
        }
        
        // Return nil if expired
        if cached.isExpired {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        return cached
    }
    
    func saveToCache(_ prayerData: [PrayerDayData], for key: PrayerCacheKey) {
        let cached = CachedPrayerData(key: key, data: prayerData, fetchedAt: Date())
        let fileURL = cacheDirectory.appendingPathComponent("\(key.identifier).json")
        
        do {
            let data = try JSONEncoder().encode(cached)
            try data.write(to: fileURL)
            updateCacheMetadata()
        } catch {
            print("Error saving to cache: \(error)")
        }
    }
    
    func clearCache() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
            updateCacheMetadata()
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
    
    func getCacheSize() -> String {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = fileURLs.reduce(0) { sum, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return sum + size
            }
            return ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
        } catch {
            return "0 KB"
        }
    }
    
    private func updateCacheMetadata() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            totalCachedMonths = fileURLs.count
        } catch {
            totalCachedMonths = 0
        }
    }
    
    private func loadCacheMetadata() {
        updateCacheMetadata()
        
        if let date = UserDefaults.standard.object(forKey: "lastOfflineSyncDate") as? Date {
            lastSyncDate = date
        }
    }
    
    // MARK: - Bulk Download for Offline Mode
    
    func downloadAllData(
        cities: [(city: String, country: String)],
        methods: [Int],
        schools: [Int],
        monthsAhead: Int = 12
    ) async {
        DispatchQueue.main.async {
            self.isDownloading = true
            self.downloadProgress = 0.0
        }
        
        let calendar = Calendar.current
        let currentDate = Date()
        
        var monthsToDownload: [(month: Int, year: Int)] = []
        for i in 0..<monthsAhead {
            guard let futureDate = calendar.date(byAdding: .month, value: i, to: currentDate) else { continue }
            let month = calendar.component(.month, from: futureDate)
            let year = calendar.component(.year, from: futureDate)
            monthsToDownload.append((month, year))
        }
        
        let totalCombinations = cities.count * methods.count * schools.count * monthsToDownload.count
        var completed = 0
        
        DispatchQueue.main.async {
            self.downloadStatus = "Preparing to download \(totalCombinations) datasets..."
        }
        
        for city in cities {
            for method in methods {
                for school in schools {
                    for (month, year) in monthsToDownload {
                        let key = PrayerCacheKey(
                            city: city.city,
                            country: city.country,
                            method: method,
                            school: school,
                            month: month,
                            year: year
                        )
                        
                        if let cached = getCachedData(for: key), !cached.isExpired {
                            completed += 1
                            continue
                        }
                        
                        DispatchQueue.main.async {
                            self.downloadStatus = "Downloading: \(city.city), \(month)/\(year)"
                        }
                        
                        if let data = await fetchPrayerTimesFromAPI(key: key) {
                            saveToCache(data, for: key)
                        }
                        
                        completed += 1
                        let progress = Double(completed) / Double(totalCombinations)
                        
                        DispatchQueue.main.async {
                            self.downloadProgress = progress
                        }
                        
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                }
            }
        }
        
        UserDefaults.standard.set(Date(), forKey: "lastOfflineSyncDate")
        
        DispatchQueue.main.async {
            self.isDownloading = false
            self.downloadStatus = "Download complete!"
            self.lastSyncDate = Date()
            self.updateCacheMetadata()
        }
    }
    
    // MARK: - API Fetching
    
    private func fetchPrayerTimesFromAPI(key: PrayerCacheKey) async -> [PrayerDayData]? {
        let baseURL = "https://api.aladhan.com/v1/calendarByCity"
        
        guard let encodedCity = key.city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedCountry = key.country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        let urlString = "\(baseURL)?city=\(encodedCity)&country=\(encodedCountry)&method=\(key.method)&school=\(key.school)&month=\(key.month)&year=\(key.year)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CalendarAPIResponse.self, from: data)
            return response.data
        } catch {
            print("Error fetching from API: \(error)")
            return nil
        }
    }
}
