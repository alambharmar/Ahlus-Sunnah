import SwiftUI

// MARK: - Simple Border View
// Clean, simple borders with gold accent color

/// Gold accent color for borders
private let islamicGold = Color(red: 0.937, green: 0.902, blue: 0.314)

// MARK: - Prayer Card Border (6 small cards)
// Simple clean border
struct PrayerCardBorderModifier: ViewModifier {
    var isHighlighted: Bool = false
    var accentColor: Color = islamicGold
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isHighlighted ? accentColor : accentColor.opacity(0.3),
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
    }
}

// MARK: - Header Card Border (Big card)
// Simple clean border
struct HeaderCardBorderModifier: ViewModifier {
    var accentColor: Color = islamicGold
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor.opacity(0.5), lineWidth: 2)
            )
    }
}

// MARK: - Generic Border (for other views)
struct IslamicBorderModifier: ViewModifier {
    var cornerRadius: CGFloat = 15
    var borderWidth: CGFloat = 1.5
    var accentColor: Color = islamicGold
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(accentColor.opacity(0.4), lineWidth: borderWidth)
            )
    }
}

// MARK: - View Extensions
extension View {
    /// Adds a simple border with gold accent
    func islamicBorder(
        cornerRadius: CGFloat = 15,
        borderWidth: CGFloat = 1.5,
        accentColor: Color = islamicGold
    ) -> some View {
        self.modifier(IslamicBorderModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            accentColor: accentColor
        ))
    }
    
    /// Adds simple border for prayer cards
    func prayerCardBorder(
        isHighlighted: Bool = false,
        accentColor: Color = islamicGold
    ) -> some View {
        self.modifier(PrayerCardBorderModifier(
            isHighlighted: isHighlighted,
            accentColor: accentColor
        ))
    }
    
    /// Adds simple border for header card
    func headerCardBorder(
        accentColor: Color = islamicGold
    ) -> some View {
        self.modifier(HeaderCardBorderModifier(
            accentColor: accentColor
        ))
    }
}

// MARK: - Preview
#Preview("Simple Borders") {
    VStack(spacing: 20) {
        // Header card
        VStack {
            Text("NEXT PRAYER")
                .font(.caption)
                .foregroundColor(.gray)
            Text("Isha")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("6:54 PM")
                .font(.title2)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .headerCardBorder()
        
        // Prayer cards
        HStack(spacing: 12) {
            VStack {
                Text("Fajr")
                    .foregroundColor(.yellow)
                Text("5:40 AM")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .prayerCardBorder(isHighlighted: true)
            
            VStack {
                Text("Dhuhr")
                    .foregroundColor(.yellow)
                Text("12:19 PM")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .prayerCardBorder(isHighlighted: false)
        }
    }
    .padding()
    .background(Color.black)
}





