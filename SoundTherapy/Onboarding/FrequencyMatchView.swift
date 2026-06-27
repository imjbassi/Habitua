import SwiftUI

/// Interactive tinnitus pitch-matching tool. The user sweeps a pure tone until
/// it matches the pitch of their ringing. Mapped logarithmically because pitch
/// perception is logarithmic.
struct FrequencyMatchView: View {
    @EnvironmentObject private var audio: AudioEngine
    @Binding var frequency: Double

    // Slider works in log space over the audiometric range.
    private let minHz: Double = 250
    private let maxHz: Double = 12000

    private var sliderValue: Binding<Double> {
        Binding(
            get: { log2(frequency / minHz) / log2(maxHz / minHz) },
            set: { t in
                frequency = minHz * pow(maxHz / minHz, t)
                audio.matchToneFrequency = frequency
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Find your pitch")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Play the tone and slide until it matches the pitch of your tinnitus. Keep the volume low and comfortable.")
                .font(.subheadline).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Tone toggle + readout
            VStack(spacing: 18) {
                Button {
                    Haptics.tap()
                    audio.toggleTone()
                } label: {
                    HStack {
                        Image(systemName: audio.isToneOn ? "stop.fill" : "play.fill")
                        Text(audio.isToneOn ? "Stop tone" : "Play tone")
                    }
                }
                .buttonStyle(audio.isToneOn ? AnyButtonStyle(SecondaryButtonStyle())
                                            : AnyButtonStyle(PrimaryButtonStyle()))

                Text("\(Int(frequency)) Hz")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: Int(frequency))

                Slider(value: sliderValue, in: 0...1)
                    .tint(Theme.accent)

                HStack {
                    Text("Low").font(.caption).foregroundStyle(Theme.textTertiary)
                    Spacer()
                    Text("High").font(.caption).foregroundStyle(Theme.textTertiary)
                }

                // Fine adjust
                HStack(spacing: 12) {
                    fineButton("-100 Hz") { adjust(-100) }
                    fineButton("-10 Hz") { adjust(-10) }
                    fineButton("+10 Hz") { adjust(10) }
                    fineButton("+100 Hz") { adjust(100) }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(Theme.surface)
            )

            Label("Most tinnitus matches a high pitch, between 4,000 and 8,000 Hz.",
                  systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func fineButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.soft()
            action()
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Capsule().fill(Theme.surfaceRaised))
        }
        .buttonStyle(.plain)
    }

    private func adjust(_ delta: Double) {
        frequency = min(maxHz, max(minHz, frequency + delta))
        audio.matchToneFrequency = frequency
    }
}

/// Type-erasing button style so we can swap styles conditionally.
struct AnyButtonStyle: ButtonStyle {
    private let _make: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) {
        _make = { AnyView(style.makeBody(configuration: $0)) }
    }
    func makeBody(configuration: Configuration) -> some View { _make(configuration) }
}
