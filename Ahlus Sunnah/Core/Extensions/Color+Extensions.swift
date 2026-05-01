import SwiftUI

// You may need to replace this with your exact implementation if it's different.
extension Color {
    
    // Custom initializer to create a Color from a Hex string with an optional alpha.
    init(hex: String, alpha: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        // Determine the number of components based on the hex string length
        let r, g, b: Double
        
        switch hex.count {
        case 3: // RGB (e.g., #123)
            (r, g, b) = (
                Double((int >> 8) * 17) / 255,
                Double((int >> 4 & 0xF) * 17) / 255,
                Double((int & 0xF) * 17) / 255
            )
        case 6: // RRGGBB (e.g., #112233)
            (r, g, b) = (
                Double(int >> 16) / 255,
                Double(int >> 8 & 0xFF) / 255,
                Double(int & 0xFF) / 255
            )
        default:
            (r, g, b) = (0, 0, 0)
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
