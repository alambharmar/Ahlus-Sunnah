import SwiftUI

struct CalendarView: View {
    @StateObject private var manager = HijriCalendarManager()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var jumpYearText: String = ""
    
    var body: some View {
        ZStack {
            // Background
            GlassBackground()
            
            // Main Content
            VStack(spacing: 0) {
                // Top Toolbar
                HStack {
                    // View Switcher (Centered)
                    Spacer()
                    
                    CustomSegmentedControl(selection: $manager.currentViewMode)
                    
                    Spacer()
                }
                .padding()
                
                // Header (Year/Month Navigation)
                HStack {
#if os(macOS)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(headerTitle)
                            .font(.system(size: 34, weight: .light))
                            .foregroundColor(.white)

                        Text(gregorianHeaderTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
#else
                    Text(headerTitle)
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white)
#endif
                    
                    Spacer()
                    
                    // Navigation Group
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation {
                                if manager.currentViewMode == .year {
                                    manager.previousYear()
                                } else {
                                    manager.previousMonth()
                                }
#if os(macOS)
                                manager.refreshEventKitCacheForVisibleMonth()
#endif
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                        
                        Button("Today") {
                            withAnimation {
                                manager.goToToday()
#if os(macOS)
                                manager.refreshEventKitCacheForVisibleMonth()
#endif
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        
                        Button(action: {
                            withAnimation {
                                if manager.currentViewMode == .year {
                                    manager.nextYear()
                                } else {
                                    manager.nextMonth()
                                }
#if os(macOS)
                                manager.refreshEventKitCacheForVisibleMonth()
#endif
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)

                if manager.currentViewMode == .year {
                    HStack(spacing: 8) {
                        TextField("Hijri year", text: $jumpYearText)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .frame(maxWidth: 120)

                        Button("Go") {
                            let trimmed = jumpYearText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let year = Int(trimmed) {
                                withAnimation {
                                    manager.jumpToYear(year)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }

                // Calendar Grid
                if manager.currentViewMode == .year {
                    YearScrollView(manager: manager)
                } else {
                    ScrollView {
                        CalendarGridView(manager: manager)
                            .environmentObject(themeManager)
                    }
                }
            }
            .padding()
        }
        .onAppear {
#if os(macOS)
            manager.requestCalendarAccessIfNeeded()
#endif
        }
        .onChange(of: manager.currentDate) { _, _ in
#if os(macOS)
            manager.refreshEventKitCacheForVisibleMonth()
#endif
        }
    }

    private var gregorianHeaderTitle: String {
        manager.gregorianHeaderString(for: manager.currentDate, viewMode: manager.currentViewMode)
    }

    private var headerTitle: String {
        if manager.currentViewMode == .year {
            return manager.yearString(for: manager.currentDate)
        }
        return "\(manager.monthName(for: manager.currentDate)) \(manager.yearString(for: manager.currentDate))"
    }
}

// MARK: - Helper Views

struct CustomSegmentedControl: View {
    @Binding var selection: HijriCalendarManager.CalendarViewMode
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([HijriCalendarManager.CalendarViewMode.month, .year], id: \.self) { mode in
                Button(action: { selection = mode }) {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selection == mode ? .white : .gray)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(
                            ZStack {
                                if selection == mode {
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                        .matchedGeometryEffect(id: "TAB", in: namespace)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct YearScrollView: View {
    @ObservedObject var manager: HijriCalendarManager
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 40) {
                    // Generate range of years: Current - 20 to Current + 20
                    let yearRange = 20
                    let currentYear = Int(manager.yearString(for: Date())) ?? 1446
                    let startYear = currentYear - yearRange
                    let endYear = currentYear + yearRange
                    
                    ForEach(startYear...endYear, id: \.self) { year in
                        VStack(alignment: .leading) {
                            Text("\(year)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.leading)
                                .id(year) // ID for scrolling
                            
                            LazyVGrid(columns: columns, spacing: 30) {
                                ForEach(0..<12) { offset in
                                    if let monthDate = dateFor(year: year, monthOffset: offset) {
                                        VStack {
                                            Text(manager.monthName(for: monthDate))
                                                .font(.headline)
                                                .foregroundColor(.red)
                                            
                                            MiniMonthGrid(date: monthDate, manager: manager)
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            manager.currentDate = monthDate
                                            manager.currentViewMode = .month
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                // Scroll to current year on appear
                if let year = Int(manager.yearString(for: manager.currentDate)) {
                    proxy.scrollTo(year, anchor: .top)
                }
            }
            .onChange(of: manager.currentDate) { oldValue, newDate in
                // Scroll when date changes (e.g. "Today" clicked)
                if let year = Int(manager.yearString(for: newDate)) {
                    withAnimation {
                        proxy.scrollTo(year, anchor: .top)
                    }
                }
            }
        }
    }
    
    func dateFor(year: Int, monthOffset: Int) -> Date? {
        // Construct a date for the given Hijri year and month offset
        // This is tricky without a direct "set year" method on Hijri calendar in standard Swift Date
        // We'll approximate by creating components
        var components = DateComponents()
        components.calendar = manager.calendar
        components.year = year
        components.month = 1 // Start of year
        components.day = 1
        
        guard let startOfYear = manager.calendar.date(from: components) else { return nil }
        return manager.calendar.date(byAdding: .month, value: monthOffset, to: startOfYear)
    }
}

struct MiniMonthGrid: View {
    let date: Date
    @ObservedObject var manager: HijriCalendarManager
    let columns = Array(repeating: GridItem(.fixed(20)), count: 7)
    let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        let days = manager.daysInMonth(for: date)

        VStack {
            // Weekday Headers
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                }
            }

            // Days
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(days.indices, id: \.self) { index in
                    if let day = days[index] {
                        Text(manager.dayNumber(for: day))
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    } else {
                        Text("")
                    }
                }
            }
        }
    }
}
