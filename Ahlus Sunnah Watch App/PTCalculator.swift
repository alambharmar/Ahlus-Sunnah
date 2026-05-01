//
// PTCALCULATOR.SWIFT - Core Prayer Time Calculation Logic
//

import Foundation

// MARK: - Constants and Configuration Enums (Needed by PrayerManager)

public enum CalculationMethod: Int {
    case jafari
    case karachi
    case isna
    case mwl
    case makkah
    case egypt
    case custom
    case tehran
    case dubai // Custom method defined for this project
}

public enum Madhab: Int {
    case shafii
    case hanafi
}

public enum Adjusting: Int {
    case none
    case midNight
    case oneSeventh
    case angleBased
}

public class PTCalculationSettings {
    public var calcMethod: CalculationMethod = .mwl
    public var madhab: Madhab = .shafii
    public var adjusting: Adjusting = .angleBased
    public var highLats: Adjusting = .none
    public var dhuhrFixed: Int = 0
    public var ishaFixed: Int = 0
    
    public var fajrAngle: Double = 18.0
    public var ishaAngle: Double = 18.0
}

// MARK: - Calculator Class

public class PTCalculator {
    
    // --- Public Properties ---
    public var settings: PTCalculationSettings
    public var date: Date
    public var latitude: Double
    public var longitude: Double
    public var timeZone: Double
    
    // --- Result Properties (The accurate times) ---
    public var fajr: Date!
    public var sunrise: Date!
    public var dhuhr: Date!
    public var asr: Date!
    public var maghrib: Date!
    public var isha: Date!
    
    // --- Internal Calculation Data ---
    private var times: [Double] = Array(repeating: Double.nan, count: 6)
    private var julianDay: Double = 0.0
    
    // --- Initializer ---
    public init(settings: PTCalculationSettings, date: Date, latitude: Double, longitude: Double, timeZone: Double) {
        self.settings = settings
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone
        
        // Initialize Date properties to avoid forced unwrapping crashes if calculation fails
        self.fajr = date
        self.sunrise = date
        self.dhuhr = date
        self.asr = date
        self.maghrib = date
        self.isha = date
        
        self.configureSettings()
        self.computePrayerTimes()
    }
    
    // --- Private Helper: Configure Calculation Parameters ---
    private func configureSettings() {
        switch settings.calcMethod {
        case .jafari:
            settings.fajrAngle = 16.0; settings.ishaAngle = 14.0; settings.ishaFixed = 0
        case .karachi:
            settings.fajrAngle = 18.0; settings.ishaAngle = 18.0; settings.ishaFixed = 0
        case .isna:
            settings.fajrAngle = 15.0; settings.ishaAngle = 15.0; settings.ishaFixed = 0
        case .mwl:
            settings.fajrAngle = 18.0; settings.ishaAngle = 17.0; settings.ishaFixed = 0
        case .makkah:
            settings.fajrAngle = 18.5; settings.ishaAngle = 0.0; settings.ishaFixed = 90
        case .egypt:
            settings.fajrAngle = 19.5; settings.ishaAngle = 17.5; settings.ishaFixed = 0
        case .tehran:
            settings.fajrAngle = 17.7; settings.ishaAngle = 14.0; settings.ishaFixed = 0
        case .dubai:
            settings.fajrAngle = 18.2; settings.ishaAngle = 18.2; settings.ishaFixed = 0
        case .custom:
            break
        }
        settings.dhuhrFixed = 0 // Fixed to 0 for all methods here
    }
    
    // --- Core Calculation: Compute all times for the date ---
    private func computePrayerTimes() {
        self.julianDay = calculateJulianDay(date: self.date)
        
        // 1. Compute Midday (Dhuhr base)
        let sunDataMidDay = sunPosition(jd: julianDay + 0.5, time: 12.0)
        self.times[2] = sunDataMidDay.apparentTransit / 15.0 // Dhuhr
        
        // 2. Compute Sunrise/Sunset
        self.times[1] = computeTime(angle: 90.0, time: 6.0) // Sunrise
        self.times[4] = computeTime(angle: 90.0, time: 18.0) // Maghrib (Sunset)
        
        if self.times[4].isNaN { return } // Stop if Sunset calculation failed
        
        // 3. Compute Fajr and Isha based on angles
        self.times[0] = computeTime(angle: settings.fajrAngle, time: self.times[1]) // Fajr
        self.times[5] = computeTime(angle: settings.ishaAngle, time: self.times[4]) // Isha
        
        // 4. Compute Asr based on Madhab
        let madhabFactor = settings.madhab == .shafii ? 1.0 : 2.0
        self.times[3] = computeAsr(factor: madhabFactor, time: self.times[2]) // Asr
        
        // 5. Apply fixed offsets
        if settings.calcMethod == .makkah && settings.ishaFixed > 0 {
            self.times[5] = self.times[4] + Double(settings.ishaFixed) / 60.0
        }
        
        // 6. Finalize (convert to Date objects)
        self.finalizeTimes()
    }
    
    // --- Time Utility Functions ---
    private func computeAsr(factor: Double, time: Double) -> Double {
        let declination = sunPosition(jd: julianDay + time, time: time).declination
        let argument = 1.0 / (factor + tan((latitude - declination).toRadians))
        let angle = 180.0 / Double.pi * atan(argument)
        
        guard !angle.isNaN && angle.isFinite else { return Double.nan }
        
        return computeTime(angle: angle, time: time)
    }

    private func computeTime(angle: Double, time: Double) -> Double {
        let sunData = sunPosition(jd: julianDay + time, time: time)
        
        let v: Double = sin(angle.toRadians) - sin(latitude.toRadians) * sin(sunData.declination.toRadians)
        let u: Double = cos(latitude.toRadians) * cos(sunData.declination.toRadians)

        let argument = v / u
        guard argument >= -1.0 && argument <= 1.0 else { // CRITICAL SAFETY CHECK
            return Double.nan
        }
        
        let t: Double = 180.0 / Double.pi * acos(argument)
        let transitTime = sunData.apparentTransit / 15.0
        
        return angle > 90.0 ? transitTime - t / 15.0 : transitTime + t / 15.0
    }

    private func calculateJulianDay(date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        let year = components.year!
        let month = components.month!
        let day = components.day!
        
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        
        let jDN = Double(day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045)
        
        return jDN - 0.5 + timeZone / 24.0
    }
    
    private func sunPosition(jd: Double, time: Double) -> (declination: Double, apparentTransit: Double) {
        let D = jd - 2451545.0 + 0.0008
        let g = (357.529 + 0.98560028 * D).normalizeAngle()
        let q = (280.459 + 0.98564736 * D).normalizeAngle()
        let L = q + 1.915 * sin(g.toRadians) + 0.02 * sin((2 * g).toRadians)
        let e = 23.439 - 0.00000036 * D
        let declination = (180.0 / Double.pi) * asin(sin(e.toRadians) * sin(L.toRadians))
        let RA = (180.0 / Double.pi) * atan2(cos(e.toRadians) * sin(L.toRadians), cos(L.toRadians))
        
        let apparentTransit = (q + timeZone * 15.0 - RA).normalizeAngle()
        
        return (declination, apparentTransit)
    }

    // --- Final Step: Convert hours (0.0 to 24.0) to Date objects (Includes NaN/Inf check) ---
    private func finalizeTimes() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        let componentsToDate: (Double, Prayer) -> Date = { hours, prayer in
            
            // Check for the NaN/Infinity failure
            guard !hours.isNaN && hours.isFinite else {
                // Return safe placeholder time if calculation failed
                let hour: Int = {
                    switch prayer {
                    case .Fajr: return 5
                    case .Sunrise: return 6
                    case .Dhuhr: return 12
                    case .Asr: return 15
                    case .Maghrib: return 18
                    case .Isha: return 20
                    }
                }()
                // Use `date` (start of day) to set the placeholder time
                return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: self.date) ?? self.date
            }
            
            let hourInt = Int(hours.rounded(.down))
            let minuteInt = Int((hours * 60.0).truncatingRemainder(dividingBy: 60.0).rounded())
            
            var dateComponents = components
            dateComponents.hour = hourInt
            dateComponents.minute = minuteInt
            dateComponents.second = 0
            
            return calendar.date(from: dateComponents) ?? self.date
        }
        
        self.fajr = componentsToDate(times[0], .Fajr)
        self.sunrise = componentsToDate(times[1], .Sunrise)
        self.dhuhr = componentsToDate(times[2], .Dhuhr)
        self.asr = componentsToDate(times[3], .Asr)
        self.maghrib = componentsToDate(times[4], .Maghrib)
        self.isha = componentsToDate(times[5], .Isha)
    }
}

// --- Extensions for Radians/Degrees Conversion ---
private extension Double {
    var toRadians: Double {
        return self * .pi / 180.0
    }
    
    func normalizeAngle() -> Double {
        var a = self.truncatingRemainder(dividingBy: 360.0)
        if a < 0 {
            a += 360.0
        }
        return a
    }
}
