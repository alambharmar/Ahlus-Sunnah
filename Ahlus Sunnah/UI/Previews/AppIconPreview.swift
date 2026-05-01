import SwiftUI

struct AppIconPreview: View {
    // Define the vibrant green accent color consistently
    let accentGreen = Color(red: 0.0, green: 0.8, blue: 0.2) // A bright, recognizable green

    var body: some View {
        // Define the size of the icon container
        ZStack {
            // 1. Pure Black Background (Matches your final app background)
            RoundedRectangle(cornerRadius: 80) // Larger corner radius for icon look
                .fill(Color.black)
                .frame(width: 300, height: 300) // Adjust size as needed for preview

            // 2. Main Element: The Clock (Sleek Time Representation)
            VStack {
                // Time Hand/Pointer
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentGreen)
                    .frame(width: 8, height: 80)
                    .rotationEffect(.degrees(-30)) // Slight rotation for dynamism
                    .offset(y: -20)
                
                // Hour marker (The center dot)
                Circle()
                    .fill(accentGreen)
                    .frame(width: 25, height: 25)
            }
            .offset(x: 0, y: -20) // Shift slightly up for the crescent

            // 3. Secondary Element: The Crescent/Qibla Indicator
            Image(systemName: "moon.haze.fill") // Using a crescent-like SF symbol
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(accentGreen.opacity(0.8)) // Slightly softer green
                .rotationEffect(.degrees(90)) // Rotate to look like a standard crescent
                .offset(x: 50, y: 10) // Positioned to frame the clock

        }
    }
}

// To preview the icon in Xcode
#Preview {
    AppIconPreview()
        .preferredColorScheme(.dark)
}
