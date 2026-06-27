import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "sun.haze.fill") }

            NavigationStack { TherapyPlayerView() }
                .tabItem { Label("Sound", systemImage: "waveform") }

            NavigationStack { ExercisesView() }
                .tabItem { Label("Train", systemImage: "brain.head.profile") }

            NavigationStack { ProgressDashboardView() }
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            NavigationStack { LearnView() }
                .tabItem { Label("Learn", systemImage: "book.fill") }
        }
        .tint(Theme.accent)
    }
}
