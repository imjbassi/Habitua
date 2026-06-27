import SwiftUI

/// Progressive-exposure exercise. The user sits with quiet for a window that
/// grows with their tolerance level. Reassurance prompts fade in along the way,
/// and a gentle "safety net" sound is one tap away - exposure should always
/// feel optional and safe, never like white-knuckling.
struct SilenceExposureView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var audio: AudioEngine
    @Environment(\.dismiss) private var dismiss

    @State private var total = 0
    @State private var remaining = 0
    @State private var running = false
    @State private var finished = false
    @State private var safetyOn = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            ZStack {
                PulsingOrb(active: running, tint: Theme.mint)
                VStack(spacing: 6) {
                    if finished {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44)).foregroundStyle(Theme.mint)
                        Text("You did it").font(.headline).foregroundStyle(Theme.textPrimary)
                    } else {
                        Text(timeString(remaining))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary).monospacedDigit()
                        Text(running ? "stay with the quiet" : "ready when you are")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .frame(height: 260)

            Text(promptText)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 80)
                .animation(.easeInOut, value: promptText)

            Spacer()

            controls
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .themedBackground()
        .navigationTitle("Silence Tolerance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            total = state.silenceExposureSeconds
            remaining = total
            audio.volume = 0.2
        }
        .onDisappear { cleanUp() }
    }

    private var progress: Double {
        total == 0 ? 0 : Double(total - remaining) / Double(total)
    }

    private var promptText: String {
        if finished {
            return "Quiet didn't make the tinnitus dangerous. Each window you sit with makes the next one easier."
        }
        if !running { return "We'll spend \(timeString(total)) with no added sound. The ringing may seem louder at first. That's expected, and it's safe." }
        switch progress {
        case ..<0.25: return "Let the sound be present. You don't have to do anything about it."
        case ..<0.5:  return "If your attention hooks onto the ringing, gently widen it to the whole room."
        case ..<0.8:  return "Notice you're okay. The alarm is quieting, even if the sound isn't."
        default:      return "Almost there. Feel how you've stayed steady through the quiet."
        }
    }

    @ViewBuilder private var controls: some View {
        if finished {
            Button("Finish") { Haptics.success(); dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        } else {
            VStack(spacing: 12) {
                Button {
                    Haptics.tap()
                    running ? pause() : start()
                } label: {
                    HStack {
                        Image(systemName: running ? "pause.fill" : "play.fill")
                        Text(running ? "Pause" : (remaining == total ? "Begin" : "Resume"))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    Haptics.soft()
                    toggleSafety()
                } label: {
                    HStack {
                        Image(systemName: safetyOn ? "speaker.wave.2.fill" : "lifepreserver")
                        Text(safetyOn ? "Turn off safety sound" : "I need a little sound")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    // MARK: - Logic

    private func start() {
        running = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in tick() }
        }
    }

    private func pause() {
        running = false
        timer?.invalidate(); timer = nil
    }

    private func tick() {
        remaining = max(0, remaining - 1)
        if remaining == 0 { complete() }
    }

    private func toggleSafety() {
        safetyOn.toggle()
        if safetyOn {
            audio.setPreset(.pinkNoise)
            audio.volume = 0.18
            audio.play()
        } else {
            audio.pause()
        }
    }

    private func complete() {
        running = false
        finished = true
        timer?.invalidate(); timer = nil
        audio.pause()
        safetyOn = false
        Haptics.success()
        state.recordSession(kind: .silenceExposure, seconds: total)
    }

    private func cleanUp() {
        timer?.invalidate(); timer = nil
        if safetyOn { audio.pause() }
    }
}
