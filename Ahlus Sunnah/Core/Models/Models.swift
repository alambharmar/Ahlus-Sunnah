import Foundation
import SwiftUI

// MARK: - Prayer Enum (Keep your original)
enum Prayer: String, CaseIterable, Identifiable {
    case Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
    
    var id: String { rawValue }
    
    var shortName: String {
        switch self {
        case .Fajr: return "Fajr"
        case .Sunrise: return "Sun"
        case .Dhuhr: return "Dhr"
        case .Asr: return "Asr"
        case .Maghrib: return "Mgh"
        case .Isha: return "Isha"
        }
    }
    
    var displayColor: Color {
        switch self {
        case .Fajr: return .cyan
        case .Sunrise: return .yellow
        case .Dhuhr: return .orange
        case .Asr: return .brown
        case .Maghrib: return .red
        case .Isha: return .purple
        }
    }
}

// MARK: - PrayerTime Struct (Keep your original)
struct PrayerTime: Identifiable {
    let id = UUID()
    var prayer: Prayer
    var time: Date
    var isMuted: Bool
    var notificationsEnabled: Bool = true // New: individual notification control
}

// MARK: - NEW: API Data Models (from TempNamaz)

struct Timings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
    
    var allTimings: [(name: String, time: String)] {
        return [
            ("Fajr", Fajr),
            ("Sunrise", Sunrise),
            ("Dhuhr", Dhuhr),
            ("Asr", Asr),
            ("Maghrib", Maghrib),
            ("Isha", Isha)
        ]
    }
}

struct GregorianDate: Codable {
    let date: String
}

struct DateInfo: Codable {
    let readable: String
    let timestamp: String
    let gregorian: GregorianDate
}

struct PrayerDayData: Codable, Identifiable {
    var id: String { date.gregorian.date }
    let timings: Timings
    let date: DateInfo
}

struct CalendarAPIResponse: Decodable {
    let data: [PrayerDayData]
}

// MARK: - NEW: Cache Key for Offline Mode
struct PrayerCacheKey: Codable, Hashable {
    let city: String
    let country: String
    let method: Int
    let school: Int
    let month: Int
    let year: Int
    
    var identifier: String {
        return "\(city)_\(country)_\(method)_\(school)_\(month)_\(year)"
    }
}

// MARK: - NEW: Cached Prayer Data
struct CachedPrayerData: Codable {
    let key: PrayerCacheKey
    let data: [PrayerDayData]
    let fetchedAt: Date
    
    var isExpired: Bool {
        let calendar = Calendar.current
        guard let expiryDate = calendar.date(byAdding: .day, value: 60, to: fetchedAt) else {
            return true
        }
        return Date() >= expiryDate
    }
}
