import Foundation

public extension Date {
    /// Returns the date formatted in Hijri (Islamic, Umm al-Qura) calendar.
    /// - Parameter locale: The locale to use for month/day names. Defaults to current locale.
    /// - Returns: A localized string like "5 Rabiʻ I 1447 AH" or similar, depending on locale.
    func toHijriDateString(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = locale
        // Example format: EEEE, d MMMM yyyy (adjusts to locale)
        // We prefer template so it adapts to user locale ordering.
        let template = "EEEE d MMMM y"
        if let pattern = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: formatter.locale) {
            formatter.dateFormat = pattern
        } else {
            formatter.dateFormat = "EEEE, d MMMM y"
        }
        return formatter.string(from: self)
    }
}
