import SwiftUI

struct RemindersListItem: View {
    let title: String
    let value: String
    let listColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // List indicator dot
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(listColor)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(value)
                    .foregroundColor(.gray)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            
            // Thin separator line
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 15)
        }
    }
}
