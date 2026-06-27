import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var audio: AudioEngine
    @Environment(\.dismiss) private var dismiss

    @State private var showResetConfirm = false
    @State private var showPitchEditor = false
    @State private var haptics = true

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Profile
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your tinnitus").font(.headline).foregroundStyle(Theme.textPrimary)
                            infoRow("Pitch", "\(Int(state.data.profile.frequencyHz)) Hz")
                            infoRow("Character", state.data.profile.quality.label)
                            infoRow("Location", state.data.profile.laterality.label)
                            Button("Re-match pitch") { showPitchEditor = true }
                                .font(.subheadline).foregroundStyle(Theme.accent)
                        }
                    }

                    // Session defaults
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Default session length").font(.headline).foregroundStyle(Theme.textPrimary)
                            Wrap(spacing: 10, lineSpacing: 10) {
                                ForEach([5, 10, 20, 30, 45, 60], id: \.self) { m in
                                    SelectChip(label: "\(m) min",
                                               selected: state.data.defaultSessionMinutes == m) {
                                        state.setDefaultMinutes(m)
                                    }
                                }
                            }
                        }
                    }

                    // Preferences
                    Card {
                        Toggle(isOn: $haptics) {
                            Text("Haptic feedback").font(.headline).foregroundStyle(Theme.textPrimary)
                        }
                        .tint(Theme.accent)
                        .onChange(of: haptics) { _, on in
                            Haptics.enabled = on
                            state.setHaptics(on)
                        }
                    }

                    // About / disclaimer
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Habitua").font(.headline).foregroundStyle(Theme.textPrimary)
                            Text("Habitua is an educational wellness app inspired by Tinnitus Retraining Therapy (TRT) and cognitive behavioural principles. It is not a medical device and does not diagnose or treat any condition. For persistent, one-sided, pulsing, or sudden tinnitus, or any hearing loss, please consult an audiologist or ENT.")
                                .font(.caption).foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Version 1.0").font(.caption2).foregroundStyle(Theme.textTertiary)
                        }
                    }

                    Button("Reset all data") { showResetConfirm = true }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.warmth)
                        .padding(.top, 4)
                }
                .padding(18)
            }
            .themedBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.accent)
                }
            }
            .onAppear { haptics = state.data.hapticsEnabled }
            .alert("Reset everything?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) {
                    state.resetAll()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently erases your profile, check-ins, and progress.")
            }
            .sheet(isPresented: $showPitchEditor) { PitchEditorSheet() }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Theme.textPrimary)
        }
    }
}

/// Lets the user re-run the pitch match after onboarding.
private struct PitchEditorSheet: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var audio: AudioEngine
    @Environment(\.dismiss) private var dismiss
    @State private var freq: Double = 6000

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                FrequencyMatchView(frequency: $freq)
                    .padding(18)
            }
            .themedBackground()
            .navigationTitle("Re-match pitch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { audio.stopTone(); dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        audio.stopTone()
                        var p = state.data.profile
                        p.frequencyHz = freq
                        state.updateProfile(p)
                        audio.configure(preset: state.data.lastPreset, notchFrequency: freq)
                        Haptics.success()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            .onAppear { freq = state.data.profile.frequencyHz }
        }
    }
}
