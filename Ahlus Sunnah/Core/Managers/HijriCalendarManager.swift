import Foundation
import SwiftUI
import Combine
#if os(macOS)
import EventKit
#endif

struct IslamicEvent: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let description: String
    let type: EventType
    let sourceTitle: String?
    
    enum EventType {
        case holiday
        case religious
        case other
        case system
    }
}

class HijriCalendarManager: ObservableObject {
    @Published var currentDate: Date = Date()
    @Published var selectedDate: Date?
    @Published var currentViewMode: CalendarViewMode = .month
#if os(macOS)
    @Published private(set) var isEventKitAuthorized: Bool = false
#endif
    
    let calendar: Calendar
#if os(macOS)
    private let eventStore = EKEventStore()
    private var eventCache: [Date: [IslamicEvent]] = [:]
#endif
    
    init() {
        var hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        hijriCalendar.locale = Locale(identifier: "en_US")
        self.calendar = hijriCalendar
    }
    
    enum CalendarViewMode: String, CaseIterable {
        case month = "Month"
        case year = "Year"
    }
    
    // MARK: - Date Helpers
    
    private struct MonthKey: Hashable {
        let year: Int
        let month: Int
    }

    private var daysCache: [MonthKey: [Date?]] = [:]
    private var daysCacheOrder: [MonthKey] = []
    private let daysCacheLimit = 36

    private lazy var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    private lazy var yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    private lazy var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "d"
        return formatter
    }()

    private lazy var gregorianHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()

    func monthName(for date: Date) -> String {
        return monthFormatter.string(from: date)
    }

    func yearString(for date: Date) -> String {
        return yearFormatter.string(from: date)
    }

    func gregorianHeaderString(for date: Date, viewMode: CalendarViewMode) -> String {
        gregorianHeaderFormatter.dateFormat = viewMode == .year ? "yyyy" : "MMMM yyyy"
        return gregorianHeaderFormatter.string(from: date)
    }

    func daysInMonth(for date: Date) -> [Date?] {
        let key = monthKey(for: date)
        if let cached = daysCache[key] {
            return cached
        }

        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = firstWeekday - 1  // Sunday → 1

        var days: [Date?] = Array(repeating: nil, count: offset)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        storeDaysCache(days, for: key)
        return days
    }

    func dayNumber(for date: Date) -> String {
        return dayFormatter.string(from: date)
    }
    
    func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }
    
    func isSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    // MARK: - Navigation
    
    func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    func previousYear() {
        if let newDate = calendar.date(byAdding: .year, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    func nextYear() {
        if let newDate = calendar.date(byAdding: .year, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    func goToToday() {
        currentDate = Date()
        selectedDate = Date()
    }

    func jumpToYear(_ year: Int) {
        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        components.year = year

        if let newDate = calendar.date(from: components) {
            currentDate = newDate
        } else {
            components.month = 1
            components.day = 1
            if let fallback = calendar.date(from: components) {
                currentDate = fallback
            }
        }
    }

    // MARK: - Events

    func events(for date: Date) -> [IslamicEvent] {
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return [] }
        
        var events: [IslamicEvent] = []
        
        if month == 1 && day == 1 {
            events.append(IslamicEvent(title: "Islamic New Year", date: date, description: "The beginning of the new Islamic year.", type: .holiday, sourceTitle: nil))
        }
        if month == 1 && day == 10 {
            events.append(IslamicEvent(title: "Ashura", date: date, description: "A day of fasting and reflection.", type: .religious, sourceTitle: nil))
        }
        if month == 3 && day == 12 {
            events.append(IslamicEvent(title: "Mawlid al-Nabi", date: date, description: "Birth of the Prophet Muhammad (PBUH).", type: .religious, sourceTitle: nil))
        }
        if month == 7 && day == 27 {
            events.append(IslamicEvent(title: "Isra and Mi'raj", date: date, description: "The Night Journey and Ascension.", type: .religious, sourceTitle: nil))
        }
        if month == 10 && day == 1 {
            events.append(IslamicEvent(title: "Eid al-Fitr", date: date, description: "Festival of breaking the fast.", type: .holiday, sourceTitle: nil))
        }
        if month == 12 && day == 10 {
            events.append(IslamicEvent(title: "Eid al-Adha", date: date, description: "Festival of Sacrifice.", type: .holiday, sourceTitle: nil))
        }

#if os(macOS)
        let key = normalizedDateKey(for: date)
        if let systemEvents = eventCache[key] {
            events.append(contentsOf: systemEvents)
        }
#endif
        
        return events
    }

    func eventDotCount(for date: Date) -> Int {
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return 0 }

        var count = 0
        if month == 1 && day == 1 { count += 1 }
        if month == 1 && day == 10 { count += 1 }
        if month == 3 && day == 12 { count += 1 }
        if month == 7 && day == 27 { count += 1 }
        if month == 10 && day == 1 { count += 1 }
        if month == 12 && day == 10 { count += 1 }

        #if os(macOS)
        let key = normalizedDateKey(for: date)
        count += eventCache[key]?.count ?? 0
        #endif

        return count
    }

#if os(macOS)
    func requestCalendarAccessIfNeeded() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            isEventKitAuthorized = true
            refreshEventKitCacheForVisibleMonth()
        case .notDetermined:
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { [weak self] granted, _ in
                    DispatchQueue.main.async {
                        self?.isEventKitAuthorized = granted
                        if granted {
                            self?.refreshEventKitCacheForVisibleMonth()
                        }
                    }
                }
            } else {
                eventStore.requestAccess(to: .event) { [weak self] granted, _ in
                    DispatchQueue.main.async {
                        self?.isEventKitAuthorized = granted
                        if granted {
                            self?.refreshEventKitCacheForVisibleMonth()
                        }
                    }
                }
            }
        default:
            isEventKitAuthorized = false
        }
    }

    func refreshEventKitCacheForVisibleMonth() {
        guard isEventKitAuthorized else { return }
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return }

        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        var nextCache: [Date: [IslamicEvent]] = [:]
        for event in ekEvents {
            let key = normalizedDateKey(for: event.startDate)
            let description = event.location?.isEmpty == false
                ? event.location!
                : (event.notes?.isEmpty == false ? event.notes! : "Calendar event")
            let mapped = IslamicEvent(
                title: event.title,
                date: event.startDate,
                description: description,
                type: .system,
                sourceTitle: event.calendar.title
            )
            nextCache[key, default: []].append(mapped)
        }

        eventCache = nextCache
    }

    private func normalizedDateKey(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
#endif

    private func monthKey(for date: Date) -> MonthKey {
        let components = calendar.dateComponents([.year, .month], from: date)
        return MonthKey(year: components.year ?? 0, month: components.month ?? 0)
    }

    private func storeDaysCache(_ days: [Date?], for key: MonthKey) {
        daysCache[key] = days
        daysCacheOrder.removeAll { $0 == key }
        daysCacheOrder.append(key)
        while daysCacheOrder.count > daysCacheLimit {
            let oldest = daysCacheOrder.removeFirst()
            daysCache.removeValue(forKey: oldest)
        }
    }
}
