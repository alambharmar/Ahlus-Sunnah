import SwiftUI

#if os(iOS)
struct iPadRootView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    iPadRootView()
}
#endif
