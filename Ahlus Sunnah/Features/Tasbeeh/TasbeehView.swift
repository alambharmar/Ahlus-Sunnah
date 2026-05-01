import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// MARK: - 1. Material & Pattern Definitions

enum CardMaterialStyle: CaseIterable {
    case brushedSteel, metallicPurple, carbonFiber, brushedGold, anodizedGreen
    case plasticOrange, metallicBlue, titaniumGray, plasticPink, polishedCopper
    case plasticRed, anodizedPurple
}

enum PatternType {
    case none, fineLines, geometricDiamonds, dots, worldMap, verticalStripes, diagonalWaves, subtleHex
}

// MARK: - 2. Material Style Helper Functions (Updated)

func getMaterialStyle(for transliteration: String) -> CardMaterialStyle {
    switch transliteration {
    case "SubhanAllah":
        return .brushedSteel
    case "Alhamdulillah":
        return .metallicPurple
    case "Allahu Akbar":
        return .carbonFiber
    case "La ilaha illa Allah":
        return .brushedGold
    case "Astaghfirullah":
        return .anodizedGreen
    case "La hawla wa la quwwata illa billah":
        return .plasticOrange
    case "Subhanallahi wa bihamdihi":
        return .metallicBlue
    case "Subhanallahil Azeem":
        return .titaniumGray
    case "La ilaha illallahu wahdahu la sharika lah":
        return .plasticPink
    case "Allahumma salli ala Muhammad":
        return .polishedCopper
    case "Bismillah":
        return .plasticRed
    default:
        return .anodizedPurple
    }
}

func getPatternType(for style: CardMaterialStyle) -> PatternType {
    switch style {
    case .brushedSteel:
        return .fineLines
    case .metallicPurple:
        return .geometricDiamonds
    case .carbonFiber:
        return .subtleHex // Subtle Hexagons for Carbon
    case .brushedGold:
        return .worldMap
    case .anodizedGreen:
        return .dots
    case .plasticOrange:
        return .verticalStripes
    case .metallicBlue:
        return .diagonalWaves
    case .titaniumGray:
        return .fineLines
    case .plasticPink:
        return .dots
    case .polishedCopper:
        return .worldMap
    case .plasticRed:
        return .verticalStripes
    case .anodizedPurple:
        return .geometricDiamonds
    }
}

func getCardColor(for materialStyle: CardMaterialStyle) -> Color {
    // Used for the button in DetailView
    switch materialStyle {
    case .brushedSteel:
        return Color(red: 0.5, green: 0.55, blue: 0.6)
    case .metallicPurple:
        return Color(red: 0.45, green: 0.22, blue: 0.65)
    case .carbonFiber:
        return Color(red: 0.12, green: 0.12, blue: 0.12)
    case .brushedGold:
        return Color(red: 0.8, green: 0.65, blue: 0.25)
    case .anodizedGreen:
        return Color(red: 0.17, green: 0.55, blue: 0.35)
    case .plasticOrange:
        return Color(red: 0.85, green: 0.45, blue: 0.15)
    case .metallicBlue:
        return Color(red: 0.17, green: 0.35, blue: 0.7)
    case .titaniumGray:
        return Color(red: 0.4, green: 0.43, blue: 0.47)
    case .plasticPink:
        return Color(red: 0.8, green: 0.25, blue: 0.45)
    case .polishedCopper:
        return Color(red: 0.75, green: 0.45, blue: 0.25)
    case .plasticRed:
        return Color(red: 0.8, green: 0.17, blue: 0.17)
    case .anodizedPurple:
        return Color(red: 0.4, green: 0.27, blue: 0.55)
    }
}

// MARK: - 3. Card Material Background and Patterns (Updated)

// Helper struct for complex card patterns
struct CreditCardPattern: View {
    let type: PatternType
    let baseColor: Color
    
    var body: some View {
        GeometryReader { geo in
            Group {
                switch type {
                case .fineLines:
                    Path { path in
                        for i in stride(from: 0, to: geo.size.width + geo.size.height, by: 1.5) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i - geo.size.height, y: geo.size.height))
                        }
                    }
                    .stroke(baseColor.opacity(0.1), lineWidth: 0.5)
                case .geometricDiamonds:
                    Path { path in
                        let spacing: CGFloat = 40
                        for x in stride(from: 0, to: geo.size.width, by: spacing) {
                            for y in stride(from: 0, to: geo.size.height, by: spacing) {
                                path.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                            }
                        }
                    }
                    .stroke(baseColor.opacity(0.12), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 4], dashPhase: 2))
                    .rotationEffect(.degrees(45))
                case .dots:
                    ForEach(0..<100) { _ in
                        Circle()
                            .fill(baseColor.opacity(0.25))
                            .frame(width: 4, height: 4)
                            .position(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                            )
                    }
                case .worldMap:
                    Path { path in
                        path.move(to: CGPoint(x: geo.size.width * 0.1, y: geo.size.height * 0.4))
                        path.addCurve(to: CGPoint(x: geo.size.width * 0.9, y: geo.size.height * 0.6), control1: CGPoint(x: geo.size.width * 0.3, y: geo.size.height * 0.1), control2: CGPoint(x: geo.size.width * 0.7, y: geo.size.height * 0.9))
                        path.move(to: CGPoint(x: geo.size.width * 0.3, y: geo.size.height * 0.8))
                        path.addQuadCurve(to: CGPoint(x: geo.size.width * 0.7, y: geo.size.height * 0.2), control: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.5))
                    }
                    .stroke(baseColor.opacity(0.15), lineWidth: 1)
                    .blur(radius: 0.5)
                case .verticalStripes:
                    Path { path in
                        for i in stride(from: 0, to: geo.size.width, by: 10) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i, y: geo.size.height))
                        }
                    }
                    .stroke(baseColor.opacity(0.15), lineWidth: 1)
                case .diagonalWaves:
                    Path { path in
                        for x in stride(from: -geo.size.height, to: geo.size.width, by: 12) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x + geo.size.height, y: geo.size.height))
                        }
                    }
                    .stroke(baseColor.opacity(0.1), lineWidth: 3)
                    .blur(radius: 0.5)
                case .subtleHex:
                    Path { path in
                        let size: CGFloat = 20
                        let h = size * 2 * 0.866 // height of hexagon side
                        for r in stride(from: -h, to: geo.size.height + h, by: h) {
                            for c in stride(from: -size, to: geo.size.width + size, by: size * 1.5) {
                                // Draw a point/small hexagon start
                                path.addRect(CGRect(x: c, y: r, width: 0.5, height: 0.5))
                                path.addRect(CGRect(x: c + size * 0.75, y: r + h/2, width: 0.5, height: 0.5))
                            }
                        }
                    }
                    .stroke(baseColor.opacity(0.08), lineWidth: 0.5)
                case .none:
                    Color.clear
                }
            }
        }
    }
}

// Main Card Background
struct CardMaterialBackground: View {
    let materialStyle: CardMaterialStyle
    
    var body: some View {
        ZStack {
            baseMaterial
            
            // Apply unique pattern on top
            CreditCardPattern(
                type: getPatternType(for: materialStyle),
                baseColor: materialStyle == .carbonFiber ? .black : .white
            )
            
            // Magstripe effect for metallic cards
            if materialStyle == .brushedSteel || materialStyle == .titaniumGray {
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(height: 30)
                    .offset(y: -40)
            }
            
            // Shine/Reflection effect
            LinearGradient(
                colors: [Color.white.opacity(0.3), Color.clear, Color.white.opacity(0.1)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
        }
    }
    
    var baseMaterial: some View {
        Group {
            switch materialStyle {
            case .brushedSteel:
                LinearGradient(colors: [Color(red: 0.55, green: 0.6, blue: 0.65), Color(red: 0.45, green: 0.5, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .metallicPurple:
                LinearGradient(colors: [Color(red: 0.5, green: 0.25, blue: 0.7), Color(red: 0.4, green: 0.2, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .carbonFiber:
                LinearGradient(colors: [Color(red: 0.15, green: 0.15, blue: 0.15), Color(red: 0.08, green: 0.08, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .brushedGold:
                LinearGradient(colors: [Color(red: 0.85, green: 0.7, blue: 0.3), Color(red: 0.75, green: 0.6, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .anodizedGreen:
                LinearGradient(colors: [Color(red: 0.2, green: 0.6, blue: 0.4), Color(red: 0.15, green: 0.5, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .plasticOrange:
                LinearGradient(colors: [Color(red: 0.9, green: 0.5, blue: 0.2), Color(red: 0.8, green: 0.4, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .metallicBlue:
                LinearGradient(colors: [Color(red: 0.2, green: 0.4, blue: 0.75), Color(red: 0.15, green: 0.3, blue: 0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .titaniumGray:
                LinearGradient(colors: [Color(red: 0.45, green: 0.48, blue: 0.52), Color(red: 0.35, green: 0.38, blue: 0.42)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .plasticPink:
                LinearGradient(colors: [Color(red: 0.85, green: 0.3, blue: 0.5), Color(red: 0.75, green: 0.2, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .polishedCopper:
                LinearGradient(colors: [Color(red: 0.8, green: 0.5, blue: 0.3), Color(red: 0.7, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .plasticRed:
                LinearGradient(colors: [Color(red: 0.85, green: 0.2, blue: 0.2), Color(red: 0.75, green: 0.15, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .anodizedPurple:
                LinearGradient(colors: [Color(red: 0.45, green: 0.3, blue: 0.6), Color(red: 0.35, green: 0.25, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
}

// MARK: - 3. Simple Wallet Stack View (FIXED to Single-Tap Open)
struct WalletStackView: View {
    @Binding var zikrList: [ZikrItem]
    @Binding var selectedZikr: ZikrItem?
    @Namespace var namespace // No need for isCardSeparated anymore
    
    private let cardHeight: CGFloat = 220
    private let stackOffset: CGFloat = 60
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .top) {
                // Spacer for total height
                Color.clear
                    .frame(height: cardHeight + CGFloat(max(0, zikrList.count - 1)) * stackOffset + 100)
                
                ForEach(Array($zikrList.wrappedValue.enumerated()), id: \.element.id) { index, zikr in
                    
                    let reversedIndex = $zikrList.wrappedValue.count - 1 - index
                    let defaultYOffset = CGFloat(index) * stackOffset + 8 // Simple stacked offset
                    
                    if zikr.id != selectedZikr?.id {
                        TasbeehCard(zikr: zikr, namespace: namespace)
                            .padding(.horizontal, 24)
                            
                            // Use simple stacking offset
                            .offset(y: defaultYOffset)
                            
                            .zIndex(Double(reversedIndex))
                            
                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 5)
                            
                            .onTapGesture {
                                // 🔑 FIX: Direct open on a single tap
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                    self.selectedZikr = zikr
                                }
                            }
                            .allowsHitTesting(selectedZikr == nil) // Only allow taps if no card is open
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - 4. Tasbeeh Card View (FIXED: Corner Radius Logic)
struct TasbeehCard: View {
    let zikr: ZikrItem
    let namespace: Namespace.ID
    var isDetail: Bool = false
    
    // Calculate the material style for the current Zikr
    var materialStyle: CardMaterialStyle {
        getMaterialStyle(for: zikr.transliteration)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Content setup (Arabic, Translation, Transliteration, Count)
            VStack(alignment: .leading, spacing: 4) {
                Text(zikr.arabic)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(zikr.translation)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            
            Spacer()
            
            HStack(alignment: .bottom) {
                Text(zikr.transliteration)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(zikr.count)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(height: 220)
        // 🔑 FIX: We apply the fill to the background, and the corner radius
        // only when we are NOT in detail mode (isDetail == false).
        // This ensures the detail view takes up the full screen rect.
        .background(
            CardMaterialBackground(materialStyle: materialStyle)
        )
        // Apply corner radius only when stacked
        .cornerRadius(isDetail ? 0 : 20, antialiased: true)
        
        .matchedGeometryEffect(id: zikr.id, in: namespace)
    }
}

// MARK: - 5. TasbeehDetailView (COMPLETELY REDESIGNED - Apple-esque)
struct TasbeehDetailView: View {
    @Binding var zikr: ZikrItem
    @EnvironmentObject var manager: TasbeehManager
    @Binding var selectedZikr: ZikrItem?
    @Namespace var namespace
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    
    // Get the correct material-specific accent color for the UI elements
    var accentColor: Color {
        let style = getMaterialStyle(for: zikr.transliteration)
        return getCardColor(for: style)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - Top Card Section
                // Safe area spacer to push content below Dynamic Island/notch
                Color.clear
                    .frame(height: geometry.safeAreaInsets.top)
                
                // ZStack to allow the close button to overlay the card
                ZStack(alignment: .topTrailing) {
                    // The TasbeehCard itself, in its detail state (isDetail: true)
                    TasbeehCard(zikr: zikr, namespace: namespace, isDetail: true)
                        .frame(height: 220)
                        .padding(.horizontal, 0) // No horizontal padding for detail card
                    
                    // Close button (standard Apple style)
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            selectedZikr = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 28)
                }
                
                // MARK: - Main Content Area (White Background)
                // This ScrollView contains all the interactive and informational elements
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Spacer to create visual separation below the card
                        Color.clear.frame(height: 40)
                        
                        // MARK: Current Count Display & Tap Area
                        Button {
                            zikr.count += 1
                            manager.saveCount(for: $zikr.wrappedValue)
                            // Haptic feedback removed for macOS compatibility
                        } label: {
                            VStack(spacing: 12) {
                                Text("\(zikr.count)")
                                    .font(.system(size: 72, weight: .bold, design: .rounded))
                                    .foregroundColor(accentColor) // Use card's accent color
                                    .monospacedDigit() // Ensures numbers don't jump around
                                
                                Text("Current Count")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.secondary) // Subtle system secondary color
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40) // Large tap target area
                            .contentShape(Rectangle()) // Makes the entire area tappable
                        }
                        .buttonStyle(.plain) // Remove default button styling
                        
                        // MARK: Reset Button
                        Button {
                            manager.resetCount(for: $zikr.wrappedValue)
                            // Haptic feedback removed for macOS compatibility
                        } label: {
                            Text("Reset")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.red) // Standard red for destructive actions
                                .frame(width: 120, height: 36)
                                .background(Color.red.opacity(0.1)) // Subtle red background
                                .cornerRadius(18) // Pill shape
                        }
                        .padding(.bottom, 20)
                        
                        // MARK: Info Sections (Arabic, Translation, Transliteration, Benefit)
                        VStack(spacing: 20) {
                            InfoSection(title: "TRANSLITERATION", value: zikr.transliteration)
                            Divider().padding(.leading, 16) // Divider with leading padding
                            InfoSection(title: "ARABIC", value: zikr.arabic, isLarge: true) // Larger font for Arabic
                            Divider().padding(.leading, 16)
                            InfoSection(title: "TRANSLATION", value: zikr.translation)
                            
                            if let benefit = zikr.benefit {
                                Divider().padding(.leading, 16)
                                InfoSection(title: "BENEFIT", value: benefit)
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 50) // Ensure enough scroll room at bottom
                    }
                    .padding(.horizontal, 16) // Overall horizontal padding for content
                }
                #if os(iOS)
                .background(Color(.systemBackground)) // White background for the scrollable content
                #else
                .background(Color(nsColor: .windowBackgroundColor))
                #endif
                .cornerRadius(20, corners: [.topLeft, .topRight]) // Rounded top corners
                .offset(y: -20) // Overlap the card slightly for a continuous look
                
                // Spacer for safe area at the bottom, blended with the white background
                #if os(iOS)
                Color(.systemBackground)
                    .frame(height: geometry.safeAreaInsets.bottom)
                #else
                Color(nsColor: .windowBackgroundColor)
                    .frame(height: geometry.safeAreaInsets.bottom)
                #endif
            }
            .offset(y: offset) // For drag-to-dismiss
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 { // Only allow dragging downwards
                            offset = value.translation.height
                            isDragging = true
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        if value.translation.height > 150 { // Threshold for dismissing
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                selectedZikr = nil
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                offset = 0 // Snap back
                            }
                        }
                    }
            )
            // Apply a conditional mask to the entire detail view for the smooth animation
            .mask(
                RoundedRectangle(cornerRadius: selectedZikr == nil ? 20 : 0, style: .continuous)
            )
        }
        .edgesIgnoringSafeArea(.all) // Extend background to all edges
    }
}
// MARK: - 6. Utility Extensions
#if os(iOS)
import UIKit

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#else
// macOS alternative using SwiftUI's UnevenRoundedRectangle (iOS 16+ / macOS 13+)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(UnevenRoundedRectangle(
            topLeadingRadius: corners.contains(.topLeft) ? radius : 0,
            bottomLeadingRadius: corners.contains(.bottomLeft) ? radius : 0,
            bottomTrailingRadius: corners.contains(.bottomRight) ? radius : 0,
            topTrailingRadius: corners.contains(.topRight) ? radius : 0
        ))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
}
#endif

// MARK: - 7. Main Tasbeeh View
struct TasbeehView: View {
    @StateObject var manager = TasbeehManager()
    @State private var selectedZikr: ZikrItem? = nil
    @State private var showingResetAllAlert = false
    
    var body: some View {
        #if os(macOS)
        TasbeehView_macOS()
        #else
        TasbeehView_iOS()
        #endif
    }
}

struct TasbeehView_iOS: View {
    @StateObject var manager = TasbeehManager()
    @State private var selectedZikr: ZikrItem? = nil
    @State private var showingResetAllAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                #if os(iOS)
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                #else
                Color(nsColor: .windowBackgroundColor)
                    .edgesIgnoringSafeArea(.all)
                #endif
                
                ZStack {
                    WalletStackView(
                        zikrList: $manager.zikrList,
                        selectedZikr: $selectedZikr
                    )
                    .zIndex(1)
                    
                    // Detail overlay (Animation handled by Matched Geometry Effect)
                    if let zikr = selectedZikr,
                       let index = manager.zikrList.firstIndex(where: { $0.id == zikr.id }) {
                        
                        // Outer ZStack for the overlay background fade
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                            
                            TasbeehDetailView(
                                zikr: $manager.zikrList[index],
                                selectedZikr: $selectedZikr
                            )
                        }
                        .transition(.opacity) // Fades the background in/out
                        .zIndex(2)
                    }
                }
            }
            .navigationTitle("Tasbeeh")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingResetAllAlert = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingResetAllAlert = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
            }
        }
        .environmentObject(manager)
        .alert("Reset All Counters?", isPresented: $showingResetAllAlert) {
            Button("Reset All", role: .destructive) {
                manager.resetAllCounts()
                // Haptic feedback removed for macOS compatibility
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset the count for all Zikr items to zero.")
        }
    }
}

struct InfoSection: View {
    let title: String
    let value: String
    var isLarge: Bool = false // For Arabic text
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary) // Subtle title color
                .tracking(0.5) // Slight letter spacing
            Text(value)
                .font(.system(size: isLarge ? 24 : 17, weight: .regular)) // Dynamic font size
                .foregroundColor(.primary) // Main text color
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Push content to the left
        .padding(.horizontal, 16) // Consistent padding
    }
}

