import SwiftUI

/// The splash screen shown briefly after app launch.
struct LaunchView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            LaunchWordmarkLabel()
        }
    }
}

#Preview {
    LaunchView()
}
