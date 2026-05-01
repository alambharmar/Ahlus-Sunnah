import SwiftUI

struct EventDetailView: View {
    let date: Date
    let events: [IslamicEvent]
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private func markerColor(for event: IslamicEvent) -> Color {
        switch event.type {
        case .holiday:
            return .red
        case .religious:
            return .blue
        case .system:
            return .green
        case .other:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date.toHijriDateString())
                    .font(.headline)
                Text(DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if events.isEmpty {
                Text("No events for this day.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(events) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(markerColor(for: event))
                                .frame(width: 8, height: 8)
                            Text(event.title)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 8) {
                            Text(timeFormatter.string(from: event.date))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let sourceTitle = event.sourceTitle {
                                Text(sourceTitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text(event.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .frame(width: 320, height: 240)
    }
}
