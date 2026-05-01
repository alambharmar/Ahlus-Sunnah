import SwiftUI

// Gold accent color inspired by masjid aesthetics (R239 G230 B80)
private let accentGold = Color(red: 0.937, green: 0.902, blue: 0.314)

// MARK: - Qaza Card Component
struct QazaCard: View {
    @EnvironmentObject var prayerManager: PrayerManager
    
    let prayer: Prayer
    let count: Int
    let iconName: String
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(prayer.displayColor.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: prayer.displayColor.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 15) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(prayer.displayColor.opacity(0.15))
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(prayer.displayColor)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(prayer.rawValue)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(count) missed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(count)")
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundColor(prayer.displayColor)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText())
                
                HStack(spacing: 10) {
                    Button {
                        if count > 0 {
                            withAnimation(.spring(response: 0.3)) {
                                prayerManager.decrementQazaCount(for: prayer)
                                isAnimating = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isAnimating = false
                            }
                        }
                        } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Prayed")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(count > 0 ? accentGold : Color.gray.opacity(0.3))
                        )
                    }
                    .disabled(count == 0)
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            prayerManager.incrementQazaCount(for: prayer)
                            isAnimating = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isAnimating = false
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(prayer.displayColor)
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(prayer.displayColor.opacity(0.5), lineWidth: 2)
                                    )
                            )
                    }
                }
            }
            .padding(20)
        }
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
    }
}

// MARK: - Statistics Card
struct QazaStatisticsCard: View {
    @EnvironmentObject var prayerManager: PrayerManager
    
    private var totalMissed: Int {
        prayerManager.qazaCounts.values.reduce(0, +)
    }
    
    private var mostMissedPrayer: (Prayer, Int)? {
        prayerManager.qazaCounts.max(by: { $0.value < $1.value })
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Missed")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("\(totalMissed)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let (prayer, count) = mostMissedPrayer, count > 0 {
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Most Missed")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 5) {
                            Text(prayer.rawValue)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(prayer.displayColor)
                            
                            Text("(\(count))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            if totalMissed > 0 {
                ProgressView(value: Double(totalMissed - prayerManager.qazaCounts.values.reduce(0, +)), total: Double(totalMissed))
                    .tint(accentGold)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Quick Actions Card
struct QuickActionsCard: View {
    @EnvironmentObject var prayerManager: PrayerManager
    @State private var showingResetAlert = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Button {
                    // Add one to all prayers
                    for prayer in [Prayer.Fajr, .Dhuhr, .Asr, .Maghrib, .Isha] {
                        prayerManager.incrementQazaCount(for: prayer)
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                        Text("Add Full Day")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                            )
                    )
                }
                
                Button {
                    showingResetAlert = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title)
                        Text("Reset All")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .alert("Reset All Qaza Counts?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                prayerManager.resetAllQazaCounts()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all Qaza (missed prayer) counts to zero. This action cannot be undone.")
        }
    }
}

// MARK: - Main Qaza View
struct QazaView: View {
    @EnvironmentObject var prayerManager: PrayerManager
    
    private let compulsoryPrayers: [Prayer] = [.Fajr, .Dhuhr, .Asr, .Maghrib, .Isha]
    
    private func iconName(for prayer: Prayer) -> String {
        switch prayer {
        case .Fajr: return "sun.max.fill"
        case .Dhuhr: return "sun.min.fill"
        case .Asr: return "cloud.sun.fill"
        case .Maghrib: return "sunset.fill"
        case .Isha: return "moon.fill"
        case .Sunrise: return "sun.horizon.fill"
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    QazaStatisticsCard()
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    QuickActionsCard()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Individual Prayers")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(compulsoryPrayers, id: \.self) { prayer in
                                QazaCard(
                                    prayer: prayer,
                                    count: prayerManager.qazaCounts[prayer] ?? 0,
                                    iconName: iconName(for: prayer)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.bottom, 20)
            }
        }
        #if os(iOS)
        .navigationTitle("Qaza Tracker")
        .navigationBarTitleDisplayMode(.large)
        #else
        .navigationTitle("Qaza Tracker")
        #endif
        .preferredColorScheme(.dark)
    }
}

