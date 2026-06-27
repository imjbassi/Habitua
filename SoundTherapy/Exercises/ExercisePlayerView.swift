import SwiftUI

struct ExercisePlayerView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    let exercise: GuidedExercise

    @State private var stepIndex = 0
    @State private var stepRemaining = 0
    @State private var elapsed = 0
    @State private var running = false
    @State private var finished = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                PulsingOrb(active: running, tint: exercise.tint)
                if finished {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44)).foregroundStyle(exercise.tint)
                        Text("Done").font(.headline).foregroundStyle(Theme.textPrimary)
                    }
                } else {
                    Text(timeString(stepRemaining))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary).monospacedDigit()
                }
            }
            .frame(height: 260)

            // Prompt text
            Text(finished ? "Notice how you feel now versus when you started." : currentStep.text)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 100)
                .padding(.horizontal, 8)
                .id(stepIndex)
                .transition(.opacity)

            // Step progress dots
            if !finished {
                HStack(spacing: 6) {
                    ForEach(exercise.steps.indices, id: \.self) { i in
                        Capsule()
                            .fill(i <= stepIndex ? exercise.tint : Theme.surfaceRaised)
                            .frame(width: i == stepIndex ? 20 : 7, height: 7)
                    }
                }
            }

            Spacer()

            controls
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .themedBackground()
        .navigationTitle(exercise.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { stepRemaining = exercise.steps.first?.seconds ?? 0 }
        .onDisappear { stopTimer() }
    }

    private var currentStep: GuidedExercise.Step {
        exercise.steps[min(stepIndex, exercise.steps.count - 1)]
    }

    @ViewBuilder private var controls: some View {
        if finished {
            Button("Finish") {
                Haptics.success()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        } else {
            VStack(spacing: 12) {
                Button {
                    Haptics.tap()
                    running ? pause() : start()
                } label: {
                    HStack {
                        Image(systemName: running ? "pause.fill" : "play.fill")
                        Text(running ? "Pause" : (elapsed == 0 ? "Begin" : "Resume"))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Skip step") { advance() }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    // MARK: - Timing

    private func start() {
        running = true
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in tick() }
        }
    }

    private func pause() {
        running = false
        stopTimer()
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func tick() {
        elapsed += 1
        stepRemaining -= 1
        if stepRemaining <= 0 { advance() }
    }

    private func advance() {
        if stepIndex < exercise.steps.count - 1 {
            withAnimation { stepIndex += 1 }
            stepRemaining = currentStep.seconds
            Haptics.soft()
        } else {
            complete()
        }
    }

    private func complete() {
        running = false
        finished = true
        stopTimer()
        Haptics.success()
        state.recordSession(kind: exercise.kind, seconds: max(elapsed, 1))
    }
}
