//
//  WatchPrayerTimesView.swift
//  WaslWatch Watch App
//
//  Prayer times display for Watch
//

import SwiftUI

struct WatchPrayerTimesView: View {
    @EnvironmentObject var prayerManager: PrayerManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Location
                Text(locationManager.locationName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // Next Prayer
                if let nextPrayer = prayerManager.nextPrayer {
                    VStack {
                        Text("Next Prayer")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(nextPrayer.prayer.rawValue)
                            .font(.headline)
                        Text(nextPrayer.time.formatted(date: .omitted, time: .shortened))
                            .font(.title3)
                    }
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(10)
                }
                
                Divider()
                
                // All Prayer Times
                ForEach(prayerManager.prayerTimes) { prayerTime in
                    HStack {
                        Text(prayerTime.prayer.rawValue)
                            .font(.caption)
                        Spacer()
                        Text(prayerTime.time.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Prayer Times")
        .onAppear {
            Task {
                await prayerManager.fetchPrayerTimes(
                    city: prayerManager.currentCity,
                    country: prayerManager.currentCountry,
                    method: prayerManager.currentMethod,
                    school: prayerManager.currentSchool,
                    for: prayerManager.selectedDate
                )
            }
        }
    }
}

#Preview {
    WatchPrayerTimesView()
        .environmentObject(PrayerManager())
        .environmentObject(LocationManager())
}
