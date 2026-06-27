import SwiftUI

struct TherapyPlayerView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var audio: AudioEngine

    @State private var preset: SoundPreset = .pinkNoise
    @State private var minutes: Int = 20
    @State private var remaining: Int = 0
    @State private var elapsed: Int = 0
    @State private var running = false
    @State private var timer: Timer?

    private let minuteOptions = [5, 10, 20, 30, 45, 60]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                ScreenHeader(title: "Sound Enrichment",
                                 subtitle: "Blend gentle sound with your tinnitus, never louder than it.")

                    orb

                    transportControls

                    mixingPointGuide

                    presetPicker

                    durationPicker
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { restoreState() }
            .onDisappear { stopTimer() }
    }

    // MARK: - Sections

    private var orb: some View {
        VStack(spacing: 12) {
            ZStack {
                PulsingOrb(active: audio.isPlaying, tint: preset.isNotched ? Theme.lilac : Theme.accent)
                if running {
                    VStack(spacing: 4) {
                        Text(timeString(remaining))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .monospacedDigit()
                        Text("remaining")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    Image(systemName: preset.symbol)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            if !running {
                Text(preset.title)
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var transportControls: some View {
        VStack(spacing: 16) {
            Button {
                Haptics.tap()
                toggle()
            } label: {
                HStack {
                    Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    Text(audio.isPlaying ? "Pause" : (running ? "Resume" : "Start session"))
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            if running {
                Button("End session") { endSession(completed: false) }
                    .buttonStyle(SecondaryButtonStyle())
            }

            // Volume
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "speaker.fill").foregroundStyle(Theme.textTertiary)
                    Slider(value: $audio.volume, in: 0...0.85)
                        .tint(Theme.accent)
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(Theme.textTertiary)
                }
                Text("Volume \(Int(audio.volume / 0.85 * 100))%")
                    .font(.caption).foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private var mixingPointGuide: some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "scope").foregroundStyle(Theme.mint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Find the mixing point")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                    Text("Raise the volume until the sound just begins to blend with your tinnitus, where you can still hear both. Don't cover it. Suggested level for level \(state.toleranceLevel): \(Int(state.recommendedEnrichmentVolume / 0.85 * 100))%.")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sound").font(.headline).foregroundStyle(Theme.textPrimary)
            ForEach(SoundPreset.allCases) { p in
                Button {
                    Haptics.tap()
                    select(p)
                } label: { presetRow(p) }
                .buttonStyle(.plain)
            }
        }
    }

    private func presetRow(_ p: SoundPreset) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill((p.isNotched ? Theme.lilac : Theme.accent).opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: p.symbol).foregroundStyle(p.isNotched ? Theme.lilac : Theme.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(p.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                    if p.isNotched {
                        Text("personalised")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.lilac.opacity(0.25)))
                            .foregroundStyle(Theme.lilac)
                    }
                }
                Text(p.isNotched ? "Notched at \(Int(state.data.profile.frequencyHz)) Hz" : p.subtitle)
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: preset == p ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(preset == p ? Theme.accent : Theme.textTertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(preset == p ? Theme.surfaceRaised : Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .strokeBorder(preset == p ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
        )
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Session length").font(.headline).foregroundStyle(Theme.textPrimary)
            Wrap(spacing: 10, lineSpacing: 10) {
                ForEach(minuteOptions, id: \.self) { m in
                    SelectChip(label: "\(m) min", selected: minutes == m) {
                        minutes = m
                        if !running { remaining = m * 60 }
                    }
                }
            }
        }
        .opacity(running ? 0.5 : 1)
        .disabled(running)
    }

    // MARK: - Logic

    private func restoreState() {
        preset = state.data.lastPreset
        minutes = state.data.defaultSessionMinutes
        audio.volume = state.recommendedEnrichmentVolume
        audio.configure(preset: preset, notchFrequency: state.data.profile.frequencyHz)
        if remaining == 0 { remaining = minutes * 60 }
    }

    private func select(_ p: SoundPreset) {
        preset = p
        audio.setPreset(p)
        if p.isNotched {
            audio.configure(preset: p, notchFrequency: state.data.profile.frequencyHz)
        }
        state.setLastPreset(p)
    }

    private func toggle() {
        if audio.isPlaying {
            audio.pause()
            stopTimer()
        } else {
            if !running { startSession() }
            audio.play()
            startTimer()
        }
    }

    private func startSession() {
        running = true
        elapsed = 0
        remaining = minutes * 60
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in tick() }
        }
    }

    private func stopTimer() {
        timer?.invalidate(); timer = nil
    }

    private func tick() {
        guard audio.isPlaying else { return }
        elapsed += 1
        remaining = max(0, remaining - 1)
        if remaining == 0 {
            endSession(completed: true)
        }
    }

    private func endSession(completed: Bool) {
        Haptics.success()
        audio.pause()
        stopTimer()
        state.recordSession(kind: .soundTherapy, seconds: elapsed)
        running = false
        remaining = minutes * 60
        elapsed = 0
    }
}
