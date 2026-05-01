import SwiftUI

struct PrayerTimeCardView: View {
    let title: String
    let count: Int
    let iconName: String
    let tintColor: Color

    var body: some View {
        ZStack {
            // Translucent dark background using system material
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .opacity(0.8)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    // Icon and color indicator
                    ZStack {
                        Circle()
                            .fill(tintColor.opacity(0.2))
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(tintColor)
                    }
                    
                    Spacer()
                    
                    // Count
                    Text("\(count)")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                }
                
                // Title
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(12)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 90, maxHeight: 100)
    }
}
