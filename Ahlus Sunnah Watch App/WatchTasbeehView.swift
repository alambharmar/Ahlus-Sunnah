//
//  WatchTasbeehView.swift
//  WaslWatch Watch App
//
//  Digital Tasbeeh counter for Watch
//

import SwiftUI

struct WatchTasbeehView: View {
    @State private var count = 0
    @State private var target = 33
    
    var body: some View {
        VStack {
            Text("Tasbeeh")
                .font(.caption)
            
            Spacer()
            
            // Counter Display
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(count) / CGFloat(target))
                    .stroke(Color.green, lineWidth: 8)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                Text("\(count)")
                    .font(.system(size: 36, weight: .bold))
            }
            
            Text("\(count)/\(target)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Buttons
            HStack {
                Button {
                    if count > 0 {
                        count -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                
                Button {
                    count += 1
                    if count >= target {
                        // Haptic feedback
                        WKInterfaceDevice.current().play(.notification)
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    count = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    WatchTasbeehView()
}
