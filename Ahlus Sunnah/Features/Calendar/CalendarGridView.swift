import SwiftUI

struct CalendarGridView: View {
    @ObservedObject var manager: HijriCalendarManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingEventDetails = false
    
    // Grid columns
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] // Monday start
    
    var body: some View {
        let days = manager.daysInMonth(for: manager.currentDate)

        VStack(spacing: 16) {
            // Weekday Headers
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            // Days Grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(days.indices, id: \.self) { index in
                    if let date = days[index] {
                        DayCell(date: date, manager: manager, accentColor: themeManager.accentColorManager.accentColor)
                            .onTapGesture {
                                manager.selectedDate = date
                                // Only show details if there are events
                                if !manager.events(for: date).isEmpty {
                                    showingEventDetails = true
                                }
                            }
                            .popover(isPresented: $showingEventDetails) {
                                if let selected = manager.selectedDate {
                                    EventDetailView(date: selected, events: manager.events(for: selected))
                                }
                            }
                    } else {
                        Text("") // Placeholder for empty cells
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct DayCell: View {
    let date: Date
    @ObservedObject var manager: HijriCalendarManager
    var accentColor: Color = .green

    var body: some View {
        let isToday = manager.isToday(date)
        let isSelected = manager.isSelected(date)
        let dotCount = min(manager.eventDotCount(for: date), 3)

        ZStack {
            if isToday {
                Circle()
                    .fill(accentColor)
                    .frame(width: 28, height: 28)
            } else if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 30, height: 30)
            }

            VStack(spacing: 3) {
                Text(manager.dayNumber(for: date))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)

                if dotCount > 0 && !isToday {
                    HStack(spacing: 3) {
                        ForEach(0..<dotCount, id: \.self) { _ in
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
        }
        .frame(height: 32)
    }
}
