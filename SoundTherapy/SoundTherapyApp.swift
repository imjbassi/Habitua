import SwiftUI

@main
struct HabituaApp: App {
    @StateObject private var state = AppState()
    @StateObject private var audio = AudioEngine()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .environmentObject(audio)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .onAppear {
                    Haptics.enabled = state.data.hapticsEnabled
                    audio.configure(preset: state.data.lastPreset,
                                    notchFrequency: state.data.profile.frequencyHz)
                }
        }
    }
}

/// Gates between onboarding and the main experience.
struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Group {
            if state.data.hasOnboarded {
                RootTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: state.data.hasOnboarded)
    }
}
