//
//  WatchQiblaView.swift
//  WaslWatch Watch App
//
//  Qibla compass for Watch - Apple Watch Compass Style
//

import SwiftUI

// Gold accent color
private let accentGold = Color(red: 0.937, green: 0.902, blue: 0.314)

struct WatchQiblaView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = QiblaViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 8) {
                compassView
                statusText
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var compassView: some View {
        ZStack {
            WatchRotatingDial(heading: viewModel.totalRotation)
                .frame(width: 180, height: 180)
            
            WatchFixedQiblaPointer(
                isAligned: viewModel.isAligned,
                isCalibrated: viewModel.isCalibrated
            )
            .frame(width: 100, height: 100)
        }
    }
    
    private var statusText: some View {
        Group {
            if viewModel.isAligned {
                Text("Aligned ✓")
                    .font(.caption2)
                    .foregroundColor(accentGold)
            } else {
                Text("\(Int(viewModel.qiblaAngle))°")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Watch Rotating Dial
struct WatchRotatingDial: View {
    let heading: Double
    
    private var bezelGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: accentGold, location: 0.0),
                .init(color: .white, location: 0.25),
                .init(color: accentGold, location: 0.5),
                .init(color: .white, location: 0.75),
                .init(color: accentGold, location: 1.0)
            ]),
            center: .center
        )
    }
    
    var body: some View {
        ZStack {
            bezelRing
            innerBlackDial
            watchTickMarks
            watchDegreeNumbers
            watchInnerCircles
        }
        .rotationEffect(.degrees(-heading))
        .animation(.linear(duration: 0.05), value: heading)
    }
    
    private var bezelRing: some View {
        Circle()
            .stroke(bezelGradient, lineWidth: 18)
    }
    
    private var innerBlackDial: some View {
        Circle()
            .fill(Color.black)
            .padding(18)
    }
    
    private var watchTickMarks: some View {
        ForEach(0..<72, id: \.self) { index in
            WatchTickMark(index: index)
        }
    }
    
    private var watchDegreeNumbers: some View {
        ForEach(0..<12, id: \.self) { index in
            WatchTiltedDegreeNumber(index: index)
        }
    }
    
    private var watchInnerCircles: some View {
        Group {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .padding(40)
            
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .padding(55)
        }
    }
}

// MARK: - Watch Tick Mark
struct WatchTickMark: View {
    let index: Int
    
    private var angle: Double { Double(index) * 5 }
    private var isMajor: Bool { index % 6 == 0 }
    
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(isMajor ? 0.9 : 0.5))
            .frame(width: 1.5, height: isMajor ? 7 : 4)
            .offset(y: -70)
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Watch Tilted Degree Number
struct WatchTiltedDegreeNumber: View {
    let index: Int
    
    private var angle: Double { Double(index) * 30 }
    private var degrees: Int { Int(angle) }
    
    var body: some View {
        Text("\(degrees)")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .offset(y: -58)
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Watch Fixed Qibla Pointer
struct WatchFixedQiblaPointer: View {
    let isAligned: Bool
    let isCalibrated: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
            
            watchQiblaArrow
            watchCenterDot
            
            if !isCalibrated {
                calibrationOverlay
            }
        }
    }
    
    private var watchQiblaArrow: some View {
        VStack(spacing: 0) {
            WatchTriangle()
                .fill(accentGold)
                .frame(width: 12, height: 9)
                .shadow(color: accentGold.opacity(0.6), radius: isAligned ? 6 : 3)
            
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accentGold)
                .frame(width: 2.5, height: 35)
            
            Spacer()
                .frame(height: 15)
            
            Image(systemName: "cube.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(y: -10)
    }
    
    private var watchCenterDot: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 6, height: 6)
            .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
            .shadow(color: isAligned ? accentGold : .clear, radius: 5)
    }
    
    private var calibrationOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.8))
            
            VStack(spacing: 5) {
                ProgressView()
                    .tint(.yellow)
                    .scaleEffect(0.8)
                
                Text("Calibrating")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
    }
}

// MARK: - Watch Triangle Shape
struct WatchTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    WatchQiblaView()
        .environmentObject(LocationManager())
}
