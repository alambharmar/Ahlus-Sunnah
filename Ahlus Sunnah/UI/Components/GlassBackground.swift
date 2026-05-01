// GlassBackground.swift
import SwiftUI

struct GlassBackground: View {
    var body: some View {
        ZStack {
            // Use Color(nsColor:) on macOS for proper background colors
            #if canImport(AppKit)
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            #else
            // THE FIX: Use .systemBackground which automatically becomes:
            // - PURE BLACK (or nearly pure) in Dark Mode
            // - PURE WHITE in Light Mode
            Color(.systemBackground)
                .ignoresSafeArea()
            #endif

            // NOTE: The VisualEffectBlur and the shine gradient have been removed
            // to eliminate the gray tinting and achieve pure Black/White.
        }
    }
}

// NOTE: The VisualEffectBlur helper struct is no longer used, but if other parts
// of your app reference it, you might need to keep it defined:

// Helper for bridging UIKit's blur into SwiftUI (iOS only)
#if os(iOS)
import UIKit

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#endif
