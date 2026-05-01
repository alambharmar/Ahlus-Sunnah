import Combine
import CoreLocation
import SwiftUI

// MARK: - Shallow Bezier Curve Shape (The Slim Line)
struct ShallowBezierProgress: Shape {
    var progress: Double
    var curveDepth: CGFloat
    var sidePadding: CGFloat

    init(progress: Double, curveDepth: CGFloat = 90, sidePadding: CGFloat = 18) {
        self.progress = progress
        self.curveDepth = curveDepth
        self.sidePadding = sidePadding
    }

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let paddedRect = rect.insetBy(dx: sidePadding, dy: 0)
        let startPoint = CGPoint(x: paddedRect.minX, y: paddedRect.maxY)
        let endPoint = CGPoint(x: paddedRect.maxX, y: paddedRect.maxY)
        let controlPoint = CGPoint(x: paddedRect.midX, y: paddedRect.maxY - curveDepth)

        var path = Path()

        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, control: controlPoint)

        return path
    }

    func pointOnCurve(ratio t: Double, rect: CGRect) -> CGPoint {
        let t = CGFloat(t)
        let t_sq = t * t
        let one_minus_t = 1 - t
        let one_minus_t_sq = one_minus_t * one_minus_t

        let paddedRect = rect.insetBy(dx: sidePadding, dy: 0)
        let startPoint = CGPoint(x: paddedRect.minX, y: paddedRect.maxY)
        let endPoint = CGPoint(x: paddedRect.maxX, y: paddedRect.maxY)
        let controlPoint = CGPoint(x: paddedRect.midX, y: paddedRect.maxY - curveDepth)

        let x =
            one_minus_t_sq * startPoint.x + 2 * one_minus_t * t * controlPoint.x + t_sq * endPoint.x
        let y =
            one_minus_t_sq * startPoint.y + 2 * one_minus_t * t * controlPoint.y + t_sq * endPoint.y

        return CGPoint(x: x, y: y)
    }
}

// MARK: - JELLY BUTTON VIEW
struct JellyButtonView<Content: View>: View {
    @GestureState private var press = false
    @GestureState private var translation: CGSize = .zero

    var action: () -> Void
    var content: Content

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    private var currentScale: CGFloat {
        if press { return 0.98 }
        let maxStretch: CGFloat = 0.005
        let dragMagnitude = sqrt(
            translation.width * translation.width + translation.height * translation.height)
        let normalizedDrag = min(dragMagnitude / 100, 1.0)
        return 1.0 + (maxStretch * normalizedDrag)
    }

    private var xShear: CGFloat { translation.width * 0.0001 }
    private var yShear: CGFloat { translation.height * 0.0001 }

    var body: some View {
        content
            .background(
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(currentScale)
                        .offset(x: translation.width * 0.01, y: translation.height * 0.01)
                        .transformEffect(
                            CGAffineTransform(
                                a: 1.0 + xShear, b: yShear, c: xShear, d: 1.0 + yShear, tx: 0, ty: 0
                            ))
                }
            )
            .scaleEffect(press ? 0.98 : 1.0)
            .offset(
                x: press ? translation.width * 0.01 : 0, y: press ? translation.height * 0.01 : 0
            )
            .animation(
                .interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5),
                value: press
            )
            .animation(
                .interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5),
                value: translation
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($press) { value, state, transaction in
                        state = true
                    }
                    .updating($translation) { value, state, transaction in
                        state = value.translation
                    }
                    .onEnded { value in
                        if abs(value.translation.width) < 20 && abs(value.translation.height) < 20 {
                            action()
                        }
                    }
            )
    }
}

// MARK: - PrayerHeaderView
struct PrayerHeaderView: View {
    @ObservedObject var manager: PrayerManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    private var nextPrayerTime: Date {
        manager.nextPrayer?.time ?? Date()
    }

    private var nextPrayerName: String {
        manager.nextPrayer?.prayer.rawValue ?? "Fajr"
    }

    private var activeProgressPrayers: [Prayer] {
        manager.getActiveProgressPrayers()
    }

    private var currentProgressRatio: Double {
        manager.trackerRatio()
    }

    private var nextPrayerDisplayColor: Color {
        manager.nextPrayer?.prayer.displayColor ?? .white
    }

    // Adaptive colors for light/dark mode
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : Color(white: 0.4)
    }

    private var progressBarBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.2)
    }

    private var dotFillColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var lineColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.5)
    }

    var body: some View {
        VStack(spacing: 6) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT PRAYER")
                        #if os(macOS)
                            .font(.system(.caption, design: .rounded))
                        #else
                            .font(.system(.caption, design: .rounded))
                        #endif
                        .fontWeight(.bold)
                        .foregroundColor(secondaryTextColor)

                    Text(nextPrayerName)
                        #if os(macOS)
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                        #else
                            .font(.system(.title, design: .rounded).weight(.heavy))
                        #endif
                        .foregroundColor(nextPrayerDisplayColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text(nextPrayerTime, style: .time)
                        #if os(macOS)
                            .font(.system(size: 36, weight: .light, design: .rounded))
                        #else
                            .font(.system(size: 32, weight: .light, design: .rounded))
                        #endif
                        .foregroundColor(primaryTextColor)

                    HStack(spacing: 4) {
                        Text("Iqama")
                            #if os(macOS)
                                .font(.caption)
                            #else
                                .font(.caption)
                            #endif
                            .fontWeight(.regular)
                            .foregroundColor(secondaryTextColor)

                        Text(manager.calculateIqamaTime(for: nextPrayerTime), style: .time)
                            #if os(macOS)
                                .font(.body)
                            #else
                                .font(.caption)
                            #endif
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }

                    HStack(spacing: 4) {
                        Text("Qaza")
                            #if os(macOS)
                                .font(.caption)
                            #else
                                .font(.caption)
                            #endif
                            .fontWeight(.regular)
                            .foregroundColor(secondaryTextColor)

                        Text(manager.calculateQazaTime(for: nextPrayerTime), style: .time)
                            #if os(macOS)
                                .font(.body)
                            #else
                                .font(.caption)
                            #endif
                            .fontWeight(.medium)
                            .foregroundColor(manager.qazaPurple)
                    }
                }
            }
            .padding(.horizontal, 12)
            #if os(macOS)
                .padding(.top, 10)
            #else
                .padding(.top, 10)
            #endif

            GeometryReader { geo in
                let cardWidth = geo.size.width
                #if os(macOS)
                    let curveDepth: CGFloat = 80
                    let sidePadding: CGFloat = 0
                    let visualCorrectionOffset: CGFloat = 10
                    let lineWidth: CGFloat = 5
                    let dotDiameter: CGFloat = 10
                    let lineLength: CGFloat = 14
                    let labelEdgeInset: CGFloat = 14
                    let arcBaselineOffset: CGFloat = 4
                #else
                    let curveDepth: CGFloat = 90
                    let sidePadding: CGFloat = 18
                    let visualCorrectionOffset: CGFloat = 0
                    let lineWidth: CGFloat = 6
                    let dotDiameter: CGFloat = 12
                    let lineLength: CGFloat = 18
                    let labelEdgeInset: CGFloat = 0
                    let arcBaselineOffset: CGFloat = 0
                #endif

                let baseArcShape = ShallowBezierProgress(
                    progress: 0,
                    curveDepth: curveDepth,
                    sidePadding: sidePadding
                )
                let arcHeight: CGFloat = curveDepth
                let labelPositionOffset: CGFloat = visualCorrectionOffset - lineLength - 6
                let dotVerticalOffset: CGFloat = 3
                let dotEdgeInset: CGFloat = dotDiameter * 0.6
                let edgeRatioInset = min(0.08, Double(dotEdgeInset / max(cardWidth, 1)))

                ZStack {
                    baseArcShape
                        .stroke(progressBarBackgroundColor, lineWidth: lineWidth)
                        .frame(width: cardWidth, height: arcHeight)

                    ShallowBezierProgress(
                        progress: currentProgressRatio,
                        curveDepth: curveDepth,
                        sidePadding: sidePadding
                    )
                    .trim(from: 0, to: currentProgressRatio)
                    .stroke(
                        Color(red: 0.831, green: 0.667, blue: 0.333), lineWidth: lineWidth
                    )
                    .frame(width: cardWidth, height: arcHeight)
                    .animation(
                        currentProgressRatio < 0.05 ? nil : .linear(duration: 1.0),
                        value: currentProgressRatio
                    )

                    let startPoint = baseArcShape.pointOnCurve(
                        ratio: 0.0, rect: CGRect(x: 0, y: 0, width: cardWidth, height: arcHeight))
                    let startDotPoint = baseArcShape.pointOnCurve(
                        ratio: edgeRatioInset,
                        rect: CGRect(x: 0, y: 0, width: cardWidth, height: arcHeight))

                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 1.5, height: lineLength)
                        .position(x: startDotPoint.x, y: startDotPoint.y)
                        .offset(y: (lineLength / 2) + visualCorrectionOffset + 1)

                    Circle()
                        .fill(dotFillColor)
                        .frame(width: dotDiameter, height: dotDiameter)
                        .overlay(
                            Circle().stroke(
                                colorScheme == .dark
                                    ? Color.black.opacity(0.8) : Color.white.opacity(0.8),
                                lineWidth: 1)
                        )
                        .position(startDotPoint)
                        .offset(y: dotVerticalOffset)

                    Text("Fajr")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(secondaryTextColor)
                        .position(startDotPoint)
                        .offset(x: labelEdgeInset, y: labelPositionOffset)

                    let endPoint = baseArcShape.pointOnCurve(
                        ratio: 1.0, rect: CGRect(x: 0, y: 0, width: cardWidth, height: arcHeight))
                    let endDotPoint = baseArcShape.pointOnCurve(
                        ratio: 1.0 - edgeRatioInset,
                        rect: CGRect(x: 0, y: 0, width: cardWidth, height: arcHeight))

                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 1.5, height: lineLength)
                        .position(x: endDotPoint.x, y: endDotPoint.y)
                        .offset(y: (lineLength / 2) + visualCorrectionOffset + 1)

                    Circle()
                        .fill(dotFillColor)
                        .frame(width: dotDiameter, height: dotDiameter)
                        .overlay(
                            Circle().stroke(
                                colorScheme == .dark
                                    ? Color.black.opacity(0.8) : Color.white.opacity(0.8),
                                lineWidth: 1)
                        )
                        .position(endDotPoint)
                        .offset(y: dotVerticalOffset)

                    Text("Isha")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(secondaryTextColor)
                        .position(endDotPoint)
                        .offset(x: -labelEdgeInset, y: labelPositionOffset)

                    ForEach(activeProgressPrayers, id: \.self) { prayer in
                        let ratio = manager.getProgressRatioPoint(for: prayer)
                        let dotPosition = baseArcShape.pointOnCurve(
                            ratio: ratio,
                            rect: CGRect(x: 0, y: 0, width: cardWidth, height: arcHeight))

                        Circle()
                            .fill(dotFillColor)
                            .frame(width: dotDiameter, height: dotDiameter)
                            .overlay(
                                Circle().stroke(
                                    colorScheme == .dark
                                        ? Color.black.opacity(0.8) : Color.white.opacity(0.8),
                                    lineWidth: 1)
                            )
                            .position(dotPosition)
                            .offset(y: dotVerticalOffset)

                        Text(prayer.shortName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(secondaryTextColor)
                            .position(dotPosition)
                            .offset(y: labelPositionOffset)
                    }

                    let trackerDotPosition = baseArcShape.pointOnCurve(
                        ratio: currentProgressRatio,
                        rect: CGRect(x: 0, y: 0, width: cardWidth, height: arcHeight))

                    Circle()
                        .fill(dotFillColor)
                        .frame(width: dotDiameter * 1.5, height: dotDiameter * 1.5)
                        .overlay(
                            Circle().strokeBorder(
                                themeManager.accentColorManager.accentColor, lineWidth: 2)
                        )
                        .shadow(
                            color: themeManager.accentColorManager.accentColor.opacity(0.5),
                            radius: 5
                        )
                        .position(trackerDotPosition)
                        .offset(y: dotVerticalOffset)
                        .animation(
                            currentProgressRatio < 0.05 || currentProgressRatio > 0.95
                                ? nil : .linear(duration: 1.0), value: currentProgressRatio)
                }
                .offset(y: geo.size.height - arcHeight - arcBaselineOffset)
            }
            #if os(macOS)
                .frame(height: 84)
                .padding(.bottom, 10)
            #else
                .frame(height: 85)
                .padding(.bottom, 10)
            #endif
        }
        .frame(maxWidth: .infinity)
        .modifier(GlassyCardModifier())
        .headerCardBorder()
        #if os(macOS)
            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
        #else
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        #endif
    }
}

// MARK: - Individual Prayer Time Card
struct PrayerTimeCard: View {
    @Binding var pTime: PrayerTime
    @ObservedObject var manager: PrayerManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    private var isNextPrayerCard: Bool {
        guard let nextTime = manager.nextPrayer?.time else { return false }
        let isSameTime = abs(pTime.time.timeIntervalSince(nextTime)) < 1.0
        return isSameTime
    }

    private func tintedMaterialBackground(for prayer: Prayer) -> some View {
        return RoundedRectangle(cornerRadius: 15)
            .fill(.ultraThinMaterial)
    }

    private var activeTimeColor: Color {
        if manager.showIqamaInGrid { return .blue }
        if manager.showQazaInGrid { return manager.qazaPurple }
        return colorScheme == .dark ? .white : .black
    }

    private var strokeColorBorder: Color {
        if isNextPrayerCard {
            return themeManager.accentColorManager.accentColor
        }
        return colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.2)
    }

    private var strokeLineWidth: CGFloat {
        if isNextPrayerCard { return 2 }
        return 1
    }

    private var bellColor: Color {
        if pTime.isMuted { return .red }
        return .gray
    }

    private var cardAnimation: Animation {
        .interactiveSpring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.5)
    }

    var body: some View {
        let timeToDisplay: Date =
            (manager.showQazaInGrid
                ? manager.calculateQazaTime(for: pTime.time)
                : manager.showIqamaInGrid
                    ? manager.calculateIqamaTime(for: pTime.time) : pTime.time)

        HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pTime.prayer.rawValue)
                    #if os(macOS)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                    #else
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                    #endif
                    .foregroundColor(pTime.prayer.displayColor)

                Text(timeToDisplay, style: .time)
                    #if os(macOS)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                    #else
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                    #endif
                    .foregroundColor(activeTimeColor)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button {
                pTime.isMuted.toggle()
            } label: {
                Image(systemName: pTime.isMuted ? "bell.slash.fill" : "bell.fill")
                    #if os(macOS)
                        .font(.title3)
                    #else
                        .font(.title3)
                    #endif
                    .frame(width: 26)
                    .foregroundColor(bellColor)
            }
            .buttonStyle(.plain)
        }
        #if os(macOS)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(height: 60)
        #else
            .padding(.vertical, 15)
            .padding(.horizontal, 15)
            .frame(height: 75)
        #endif
        .background {
            self.tintedMaterialBackground(for: pTime.prayer)
                .shadow(
                    color: isNextPrayerCard
                        ? themeManager.accentColorManager.accentColor.opacity(0.4) : .clear,
                    radius: 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .prayerCardBorder(isHighlighted: isNextPrayerCard)
        .animation(cardAnimation, value: activeTimeColor)
        .animation(cardAnimation, value: strokeColorBorder)
        .animation(.default, value: timeToDisplay)
    }
}

// MARK: - PrayerTimesGrid
struct PrayerTimesGrid: View {
    @ObservedObject var manager: PrayerManager

    init(manager: PrayerManager) {
        self._manager = ObservedObject(wrappedValue: manager)
    }

    private var gridSpacing: CGFloat {
        #if os(macOS)
            8
        #else
            12
        #endif
    }

    private var columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: gridSpacing) {
            HStack {
                Text("Today's Timings")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 8) {
                    JellyButtonView(action: {
                        withAnimation {
                            manager.showQazaInGrid.toggle()
                            if manager.showQazaInGrid { manager.showIqamaInGrid = false }
                        }
                    }) {
                        Text("Qaza")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(manager.showQazaInGrid ? manager.qazaPurple : .gray)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule().stroke(
                                            manager.showQazaInGrid
                                                ? manager.qazaPurple : Color.gray.opacity(0.3),
                                            lineWidth: 1.5))
                            }
                    }
                    .buttonStyle(.plain)

                    JellyButtonView(action: {
                        withAnimation {
                            manager.showIqamaInGrid.toggle()
                            if manager.showIqamaInGrid { manager.showQazaInGrid = false }
                        }
                    }) {
                        Text("Iqama")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(manager.showIqamaInGrid ? .blue : .gray)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule().stroke(
                                            manager.showIqamaInGrid
                                                ? Color.blue : Color.gray.opacity(0.3),
                                            lineWidth: 1.5))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(manager.prayerTimes.indices, id: \.self) { index in
                    PrayerTimeCard(pTime: $manager.prayerTimes[index], manager: manager)
                }
            }
        }
    }
}

// MARK: - Glassy Card Modifier
struct GlassyCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    // Royal gold tint for card borders
    private let royalGold = Color(red: 0.831, green: 0.667, blue: 0.333)

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.06)
                            : Color.white.opacity(0.75)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                colorScheme == .dark
                                    ? royalGold.opacity(0.18)
                                    : royalGold.opacity(0.22),
                                lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

// MARK: - TimesView Main Structure
struct TimesView: View {
    @EnvironmentObject var manager: PrayerManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingSettings = false
    @Environment(\.colorScheme) var colorScheme

    private let fullDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var dayLabels: [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let weekdayIndex = (calendar.component(.weekday, from: today) + 5) % 7

        var rotatedDays = fullDays
        for _ in 0..<weekdayIndex {
            if let first = rotatedDays.first {
                rotatedDays.append(first)
                rotatedDays.removeFirst()
            }
        }

        var finalDays = rotatedDays
        if !finalDays.isEmpty {
            finalDays[0] = "Today"
        }
        return finalDays
    }

    @State private var selectedDayIndex: Int = 0

    private var finalCountdownString: String {
        let fullString = manager.countdownString
        let prefix = "NEXT IN"

        if fullString.uppercased().starts(with: prefix) {
            return String(fullString.dropFirst(prefix.count)).trimmingCharacters(
                in: .whitespacesAndNewlines)
        }
        return fullString
    }

    private func strippedHijriDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = .current
        let template = "d MMMM y"
        if let pattern = DateFormatter.dateFormat(
            fromTemplate: template, options: 0, locale: formatter.locale)
        {
            formatter.dateFormat = pattern
        } else {
            formatter.dateFormat = "d MMMM y"
        }
        return formatter.string(from: date)
    }

    private var gregorianDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: manager.selectedDate)
    }

    var body: some View {
        #if os(macOS)
            macOSView
        #else
            iOSView
        #endif
    }

    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                #if os(iOS)
                    ThemeManager.iOSDarkBackground
                #else
                    ThemeManager.darkBackground
                #endif
            } else {
                ThemeManager.lightBackground
            }
        }
    }

    // MARK: - macOS Layout
    private var macOSView: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(finalCountdownString)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(themeManager.accentColorManager.accentColor)

                        Spacer()

                        Text(manager.locationManager.locationName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6)
                            )
                    }
                    .frame(maxWidth: .infinity)

                    HStack {
                        Text(strippedHijriDateString(from: manager.selectedDate))
                        Spacer()
                        Text(gregorianDateString)
                    }
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.horizontal, 12)

                VStack {
                    Picker("Day", selection: $selectedDayIndex) {
                        ForEach(0..<7, id: \.self) { index in
                            Text(dayLabels[index])
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                    .tint(themeManager.accentColorManager.accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.top, 0)
                .onChange(of: selectedDayIndex) { oldValue, newValue in
                    manager.selectedDate = manager.date(for: newValue)
                }

                PrayerHeaderView(manager: manager)
                    .padding(.horizontal, 12)
                    .padding(.top, 2)

                PrayerTimesGrid(manager: manager)
                    .padding(.horizontal, 12)
                    .onChange(of: manager.selectedDate) { oldValue, newValue in
                        manager.updateSelectedDayTimes(for: manager.selectedDate)
                    }

                Spacer(minLength: 0)
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(themeManager.accentColorManager.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(manager)
                .environmentObject(themeManager)
                #if os(macOS)
                    .frame(width: 560, height: 520)
                #else
                    .presentationDetents([.large])
                #endif
        }
        .onAppear {
            if manager.prayerTimes.isEmpty {
                manager.selectedDate = manager.date(for: selectedDayIndex)
                manager.updateSelectedDayTimes(for: manager.selectedDate)
                manager.setupTimer()
            }
            manager.locationManager.checkLocationAuthorization()
        }
    }

    // MARK: - iOS Layout (Original)
    private var iOSView: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(finalCountdownString)
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            themeManager.accentColorManager.accentColor)

                                    Spacer()

                                    Text(manager.locationManager.locationName)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(
                                            colorScheme == .dark
                                                ? .white.opacity(0.8) : .black.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)

                                HStack {
                                    Text(strippedHijriDateString(from: manager.selectedDate))
                                    Spacer()
                                    Text(gregorianDateString)
                                }
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)

                            VStack {
                                Picker("Day", selection: $selectedDayIndex) {
                                    ForEach(0..<7, id: \.self) { index in
                                        Text(dayLabels[index])
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.vertical, 4)
                                .tint(themeManager.accentColorManager.accentColor)
                            }
                            .padding(.horizontal)
                            .padding(.top, 0)
                            .onChange(of: selectedDayIndex) { oldValue, newValue in
                                manager.selectedDate = manager.date(for: newValue)
                            }

                            PrayerHeaderView(manager: manager)
                                .padding(.horizontal)
                                .padding(.top, 2)

                            PrayerTimesGrid(manager: manager)
                                .padding(.horizontal)
                                .onChange(of: manager.selectedDate) { oldValue, newValue in
                                    manager.updateSelectedDayTimes(for: manager.selectedDate)
                                }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Times")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(themeManager.accentColorManager.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(manager)
                    .environmentObject(themeManager)
                    #if os(macOS)
                        .frame(width: 560, height: 520)
                    #else
                        .presentationDetents([.large])
                    #endif
            }
            .preferredColorScheme(.dark)
            .onAppear {
                if manager.prayerTimes.isEmpty {
                    manager.selectedDate = manager.date(for: selectedDayIndex)
                    manager.updateSelectedDayTimes(for: manager.selectedDate)
                    manager.setupTimer()
                }
                manager.locationManager.checkLocationAuthorization()
            }
        }
    }
}
