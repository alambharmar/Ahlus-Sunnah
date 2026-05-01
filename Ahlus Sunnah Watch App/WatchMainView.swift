//
//  WatchMainView.swift
//  WaslWatch Watch App
//
//  Main view for Watch app
//

import SwiftUI

struct WatchMainView: View {
    @StateObject private var prayerManager = PrayerManager()
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            TabView {
                // Prayer Times Tab
                WatchPrayerTimesView()
                    .environmentObject(prayerManager)
                    .environmentObject(locationManager)
                
                // Qibla Tab
                WatchQiblaView()
                    .environmentObject(locationManager)
                
                // Tasbeeh Tab
                WatchTasbeehView()
            }
            .tabViewStyle(.page)
        }
    }
}

#Preview {
    WatchMainView()
}
