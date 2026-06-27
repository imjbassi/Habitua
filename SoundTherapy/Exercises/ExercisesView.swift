import SwiftUI

/// A guided, step-based exercise. Each step shows a prompt for a set duration.
struct GuidedExercise: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let kind: SessionRecord.Kind
    let steps: [Step]

    struct Step: Identifiable {
        let id = UUID()
        let text: String
        let seconds: Int
    }

    var totalSeconds: Int { steps.reduce(0) { $0 + $1.seconds } }
}

enum ExerciseLibrary {
    static let all: [GuidedExercise] = [attentionShift, soundWidening, breathing, bodyScan]

    /// Attention retraining - deliberately moving the spotlight off the tinnitus.
    static let attentionShift = GuidedExercise(
        title: "Attention Shift",
        subtitle: "Move the spotlight off the ringing",
        symbol: "brain.head.profile",
        tint: Theme.lilac,
        kind: .attention,
        steps: [
            .init(text: "Settle in. Let the tinnitus be there. No need to change it.", seconds: 15),
            .init(text: "Now find the quietest real sound around you. The hum of a room, distant traffic.", seconds: 25),
            .init(text: "Rest your attention on that outside sound. When you drift back to the ringing, gently return.", seconds: 40),
            .init(text: "Notice you can hold both the tinnitus and the world without alarm.", seconds: 30),
            .init(text: "Let attention float freely. Nothing to fix. You're training choice.", seconds: 30)
        ])

    /// Sound widening - perceiving tinnitus as one element in a wide field.
    static let soundWidening = GuidedExercise(
        title: "Sound Widening",
        subtitle: "Make the ringing one sound among many",
        symbol: "circle.hexagongrid.fill",
        tint: Theme.accent,
        kind: .attention,
        steps: [
            .init(text: "Close your eyes. Listen to the furthest sound you can hear.", seconds: 20),
            .init(text: "Now the nearest sound: your breath, your clothing.", seconds: 20),
            .init(text: "Open your awareness to everything at once, a wide soundscape.", seconds: 30),
            .init(text: "Place the tinnitus inside that field. It's just one voice in a choir.", seconds: 35),
            .init(text: "Let it shrink to its true size. Small. Distant. Harmless.", seconds: 25)
        ])

    /// Relaxation breathing - lowers the autonomic arousal that amplifies distress.
    static let breathing = GuidedExercise(
        title: "Calm Breathing",
        subtitle: "Quiet the alarm response",
        symbol: "wind",
        tint: Theme.mint,
        kind: .relaxation,
        steps: [
            .init(text: "Breathe in slowly through your nose… 1, 2, 3, 4.", seconds: 16),
            .init(text: "Hold gently… 1, 2.", seconds: 8),
            .init(text: "Breathe out longer than you breathed in… 1, 2, 3, 4, 5, 6.", seconds: 18),
            .init(text: "Again, in for four. The tinnitus may rise or fall. Let it.", seconds: 24),
            .init(text: "Out for six. Your nervous system is learning: this sound is safe.", seconds: 30),
            .init(text: "Keep the rhythm. Slow out-breaths tell the brain there's no threat.", seconds: 30)
        ])

    /// Body scan - decouples the sound from physical tension.
    static let bodyScan = GuidedExercise(
        title: "Tension Release",
        subtitle: "Unclench from the sound",
        symbol: "figure.mind.and.body",
        tint: Theme.warmth,
        kind: .relaxation,
        steps: [
            .init(text: "Notice your jaw. Tinnitus distress often hides here. Let it loosen.", seconds: 20),
            .init(text: "Soften the muscles around your ears and temples.", seconds: 20),
            .init(text: "Drop your shoulders away from your ears.", seconds: 20),
            .init(text: "Unclench your hands. Let your whole body go heavy.", seconds: 25),
            .init(text: "The sound is still there, but your body no longer braces against it.", seconds: 25)
        ])
}

struct ExercisesView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ScreenHeader(title: "Train",
                                 subtitle: "Retrain attention and calm the reaction. A little every day.")

                    // Progressive exposure highlight
                    NavigationLink {
                        SilenceExposureView()
                    } label: { silenceCard }
                    .buttonStyle(.plain)

                    ForEach(ExerciseLibrary.all) { ex in
                        NavigationLink {
                            ExercisePlayerView(exercise: ex)
                        } label: { exerciseRow(ex) }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
    }

    private var silenceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Progressive Exposure", systemImage: "ear.fill")
                        .font(.headline).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("Level \(state.toleranceLevel)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(Theme.mint.opacity(0.22)))
                        .foregroundStyle(Theme.mint)
                }
                Text("Sit with \(timeString(state.silenceExposureSeconds)) of quiet. Each level grows the window, building lasting tolerance.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressView(value: Double(state.sessionsIntoCurrentLevel), total: 5)
                    .tint(Theme.mint)
                Text("\(state.sessionsIntoCurrentLevel)/5 sessions to next level")
                    .font(.caption).foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private func exerciseRow(_ ex: GuidedExercise) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ex.tint.opacity(0.18)).frame(width: 50, height: 50)
                Image(systemName: ex.symbol).font(.system(size: 20)).foregroundStyle(ex.tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(ex.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text(ex.subtitle).font(.caption).foregroundStyle(Theme.textSecondary)
                Text("\(ex.totalSeconds / 60 == 0 ? "\(ex.totalSeconds)s" : "\(ex.totalSeconds / 60) min") · \(ex.steps.count) steps")
                    .font(.caption2).foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }
}
