import SwiftUI
import CoreHaptics

// Gold accent color inspired by masjid aesthetics
private let accentGold = Color(red: 0.937, green: 0.902, blue: 0.314)

// MARK: - QiblaView Main Structure
struct QiblaView: View {
    @StateObject var viewModel = QiblaViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    private var cityDisplay: String {
        viewModel.currentCity ?? "Current City"
    }
    
    private var targetQiblaAngle: Double {
        viewModel.qiblaAngle
    }
    
    private var degreesToQibla: Int {
        var diff = targetQiblaAngle - viewModel.userHeading
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return Int(abs(diff))
    }
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    private var backgroundColor: Color {
        isDarkMode ? .black : .white
    }
    
    private var textSecondaryColor: Color {
        isDarkMode ? .gray : .secondary
    }
    
    private var cardBorderColor: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }

    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Qibla")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
        }
        .onAppear {
            viewModel.startUpdates()
        }
        .onDisappear {
            viewModel.stopUpdates()
        }
    }
    
    private var mainContent: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                compassDisplay
                infoCard
                Spacer()
            }
        }
    }
    
    private var compassDisplay: some View {
        ZStack {
            // Rotating dial with white bezel, yellow ticks, numbers on bezel
            RotatingCompassDial(
                heading: viewModel.totalRotation,
                accentColor: accentGold,
                isDarkMode: isDarkMode
            )
            .frame(width: 340, height: 340)
            
            // Fixed Qibla pointer
            FixedQiblaPointer(
                isAligned: viewModel.isAligned,
                accentColor: accentGold
            )
            .frame(width: 180, height: 180)
        }
    }
    
    private var infoCard: some View {
        VStack(spacing: 15) {
            HStack {
                qiblaDirectionInfo
                Spacer()
                alignmentInfo
            }
            
            if !viewModel.isCalibrated {
                calibrationWarning
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color(white: 0.95)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    private var qiblaDirectionInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Qibla Direction")
                .font(.subheadline)
                .foregroundColor(textSecondaryColor)
            
            Text("\(Int(targetQiblaAngle))°")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(accentGold)
        }
    }
    
    private var alignmentInfo: some View {
        VStack(alignment: .trailing, spacing: 5) {
            let alignmentText = viewModel.isAligned ? "Aligned" : "\(degreesToQibla)° off"
            let alignmentColor = viewModel.isAligned ? accentGold : Color.orange
            
            Text(alignmentText)
                .font(.subheadline)
                .foregroundColor(alignmentColor)
                .fontWeight(.semibold)
            
            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .font(.caption)
                Text(cityDisplay)
                    .font(.caption)
            }
            .foregroundColor(textSecondaryColor)
        }
    }
    
    private var calibrationWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Wave device in figure-eight to calibrate")
                .font(.caption)
                .foregroundColor(textSecondaryColor)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

// MARK: - Rotating Compass Dial (Apple Watch Compass Style)
// MARK: - Rotating Compass Dial (Apple Watch Compass Style)
struct RotatingCompassDial: View {
    let heading: Double
    let accentColor: Color
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            // White outer bezel with degree numbers on it
            outerBezel
            
            // Inner black dial
            innerDial
        }
        .rotationEffect(.degrees(-heading))
        .animation(.linear(duration: 0.05), value: heading)
    }
    
    private var outerBezel: some View {
        ZStack {
            // White outer ring (Main background)
            Circle()
                .strokeBorder(Color.white, lineWidth: 50)
            
            // Yellow inner ring (accent band) - moving inside the numbers
            Circle()
                .strokeBorder(accentColor, lineWidth: 16)
                .padding(50)
            
            // Ticks (Outer)
            ForEach(0..<72, id: \.self) { index in
                BezelTickMark(index: index, accentColor: accentColor)
            }
            
            // Numbers & Cardinals (Inner)
            bezelCardinalDirections
            
            ForEach(0..<12, id: \.self) { index in
                BezelDegreeNumber(index: index, accentColor: accentColor)
            }
        }
    }
    
    private var bezelCardinalDirections: some View {
        Group {
            // North - use ^ arrow in yellow, pushed out slightly to match ticks or numbers?
            // Apple Watch usually has the triangle on the OUTER edge if it replaces 0?
            // Actually in the reference (step 122), the orange ^ is on the OUTER edge, replacing the tick? No, it's on the ring.
            // Let's look closely at image 122.
            // The orange triangle is on the OUTER edge.
            // The Letters E, S, W are on the INNER edge.
            
            Text("▼") // Using a down triangle pointing to the center, or just a custom triangle shape
                .font(.system(size: 14, weight: .black))
                .foregroundColor(accentColor)
                .rotationEffect(.degrees(180)) // Point inward
                .offset(y: -166) // On outer edge like ticks
            
            // East
            Text("E")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .rotationEffect(.degrees(90))
                .offset(y: -138) // Inner edge like numbers
                .rotationEffect(.degrees(-90))
            
            // South
            Text("S")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .rotationEffect(.degrees(180))
                .offset(y: -138) // Inner edge like numbers
                .rotationEffect(.degrees(-180))
            
            // West
            Text("W")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .rotationEffect(.degrees(-90))
                .offset(y: -138) // Inner edge like numbers
                .rotationEffect(.degrees(90))
        }
    }
    
    private var innerDial: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .padding(55) // Inside yellow ring
            
            tickMarks
            innerCircles
        }
    }
    
    private var tickMarks: some View {
        ForEach(0..<72, id: \.self) { index in
            TickMark(index: index)
        }
    }
    
    private var innerCircles: some View {
        Group {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .padding(80)
            
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .padding(100)
            
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .padding(120)
        }
    }
}

// MARK: - Inner Dial Tick Mark (White lines on black dial)
struct TickMark: View {
    let index: Int
    
    private var angle: Double { Double(index) * 5 }
    private var isMajor: Bool { index % 6 == 0 }      // every 30°
    private var isMedium: Bool { !isMajor && index % 2 == 0 } // every 10°
    
    private var tickHeight: CGFloat {
        if isMajor { return 16 }
        if isMedium { return 10 }
        return 6
    }
    
    private var tickOpacity: Double {
        if isMajor { return 0.9 }
        if isMedium { return 0.6 }
        return 0.35
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(tickOpacity))
            .frame(width: isMajor ? 2 : 1, height: tickHeight)
            .offset(y: 100) // position within inner black dial
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Bezel Tick Mark (Yellow lines on white bezel)
// MARK: - Bezel Tick Mark (Yellow lines on outer white bezel)
struct BezelTickMark: View {
    let index: Int
    let accentColor: Color
    
    private var angle: Double { Double(index) * 5 }
    private var isMajor: Bool { index % 6 == 0 }      // every 30°
    private var isMedium: Bool { !isMajor && index % 2 == 0 } // every 10°
    
    private var tickHeight: CGFloat {
        if isMajor { return 10 }
        if isMedium { return 7 }
        return 4
    }
    
    var body: some View {
        Rectangle()
            .fill(accentColor) // Yellow tick marks
            .frame(width: isMajor ? 2.5 : 1.5, height: tickHeight)
            .offset(y: -165) // Positioned on outer side of white bezel
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Bezel Degree Number (Numbers on white bezel)
struct BezelDegreeNumber: View {
    let index: Int
    let accentColor: Color
    
    private var angle: Double { Double(index) * 30 }
    private var degrees: Int { Int(angle) }
    
    // Skip 0 (North position - will show arrow), 90 (E), 180 (S), 270 (W)
    private var shouldShow: Bool {
        degrees != 0 && degrees != 90 && degrees != 180 && degrees != 270
    }
    
    var body: some View {
        if shouldShow {
            Text("\(degrees)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .rotationEffect(.degrees(angle)) // Rotate text to be radial
                .offset(y: -138) // Position on inner part of bezel
                .rotationEffect(.degrees(-angle)) // Counter-rotate position around circle
        }
    }
}

// MARK: - Fixed Qibla Pointer (Always points up)
struct FixedQiblaPointer: View {
    let isAligned: Bool
    let accentColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
            
            qiblaArrow
            centerDot
        }
    }
    
    private var qiblaArrow: some View {
        VStack(spacing: 0) {
            // Pointer Line
            Rectangle()
                .fill(accentColor)
                .frame(width: 3, height: 75) // Longer, thinner line
            
            Spacer()
                .frame(height: 35) // Offset from center
        }
        .offset(y: -42)
    }
    
    private var centerDot: some View {
        ZStack {
            // Outer white ring
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 18, height: 18)
            
            // Inner black fill to match background
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
