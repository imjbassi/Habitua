import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var audio: AudioEngine

    @State private var step = 0
    @State private var profile = TinnitusProfile()

    private let lastStep = 5

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0...lastStep, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Theme.accent : Theme.surfaceRaised)
                            .frame(width: i == step ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: step)
                    }
                }
                .padding(.top, 16)

                TabView(selection: $step) {
                    welcome.tag(0)
                    howItWorks.tag(1)
                    character.tag(2)
                    pitchMatch.tag(3)
                    baseline.tag(4)
                    consent.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                footer
            }
            .padding(.horizontal, 22)
        }
    }

    // MARK: - Steps

    private var welcome: some View {
        OnboardingScaffold {
            VStack(spacing: 24) {
                Spacer()
                PulsingOrb(active: true)
                    .frame(maxWidth: .infinity)
                VStack(spacing: 12) {
                    Text("Habitua")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Train your brain to stop fearing the ringing. It fades into the background on its own.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }

    private var howItWorks: some View {
        OnboardingScaffold {
            VStack(alignment: .leading, spacing: 22) {
                Text("Not masking. Habituation.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Most apps drown out tinnitus with noise. The moment it stops, the ringing feels louder. Your brain stays on alert.\n\nHabitua works the opposite way.")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                pillar(symbol: "waveform.path.ecg",
                       title: "Sound enrichment",
                       text: "Gentle sound played *below* your tinnitus, so the brain learns it isn't a threat.")
                pillar(symbol: "brain.head.profile",
                       title: "Attention retraining",
                       text: "Short exercises that shift focus away from the sound and calm the alarm response.")
                pillar(symbol: "figure.mind.and.body",
                       title: "Progressive exposure",
                       text: "Small, growing windows of quiet that build real tolerance instead of dependence.")
                Spacer()
            }
        }
    }

    private func pillar(symbol: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
                Text(.init(text)).font(.subheadline).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var character: some View {
        OnboardingScaffold {
            VStack(alignment: .leading, spacing: 22) {
                Text("What does yours sound like?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("This personalises your sound therapy. There are no wrong answers.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)

                Text("Character").font(.headline).foregroundStyle(Theme.textPrimary)
                FlowChips(items: TinnitusProfile.Quality.allCases.map { ($0.label, $0 == profile.quality) }) { idx in
                    profile.quality = TinnitusProfile.Quality.allCases[idx]
                }

                Text("Where you hear it").font(.headline).foregroundStyle(Theme.textPrimary)
                    .padding(.top, 4)
                FlowChips(items: TinnitusProfile.Laterality.allCases.map { ($0.label, $0 == profile.laterality) }) { idx in
                    profile.laterality = TinnitusProfile.Laterality.allCases[idx]
                }
                Spacer()
            }
        }
    }

    private var pitchMatch: some View {
        OnboardingScaffold {
            FrequencyMatchView(frequency: $profile.frequencyHz)
        }
    }

    private var baseline: some View {
        OnboardingScaffold {
            VStack(alignment: .leading, spacing: 24) {
                Text("Where are you today?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("We'll measure progress against this baseline. We track your *reaction* to tinnitus. That's what improves first.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Card {
                    ScaleSlider(title: "How loud does it feel?",
                                value: $profile.baselineLoudness,
                                lowLabel: "Faint", highLabel: "Overwhelming")
                }
                Card {
                    ScaleSlider(title: "How much does it distress you?",
                                value: $profile.baselineDistress,
                                lowLabel: "Not at all", highLabel: "Severely",
                                tint: Theme.warmth)
                }
                Spacer()
            }
        }
    }

    private var consent: some View {
        OnboardingScaffold {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.mint)
                Text("You're set up.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("A few things to remember:")
                    .font(.headline).foregroundStyle(Theme.textPrimary)
                bullet("Habituation takes weeks, not days. Small, consistent practice wins.")
                bullet("Keep sound therapy quiet. It should blend with your tinnitus, never cover it.")
                bullet("Habitua is an educational wellness tool, not a medical device. See an audiologist or ENT for diagnosis, sudden changes, or one-sided symptoms.")
                Spacer()
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(Theme.accent).frame(width: 6, height: 6).padding(.top, 7)
            Text(text).font(.subheadline).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Footer navigation

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") {
                    Haptics.tap()
                    audio.stopTone()
                    withAnimation { step -= 1 }
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: 110)
            }
            Button(step == lastStep ? "Begin" : "Continue") {
                Haptics.tap()
                audio.stopTone()
                if step == lastStep {
                    finish()
                } else {
                    withAnimation { step += 1 }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.vertical, 16)
    }

    private func finish() {
        Haptics.success()
        audio.configure(preset: state.data.lastPreset, notchFrequency: profile.frequencyHz)
        state.completeOnboarding(profile: profile)
    }
}

/// Wraps step content in a scroll view with consistent spacing.
private struct OnboardingScaffold<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .frame(minHeight: 480, alignment: .top)
        }
    }
}

/// A simple wrapping row of selectable chips.
struct FlowChips: View {
    /// (label, isSelected)
    let items: [(String, Bool)]
    let onSelect: (Int) -> Void

    var body: some View {
        FlexibleWrap(items.indices.map { $0 }) { index in
            SelectChip(label: items[index].0, selected: items[index].1) {
                onSelect(index)
            }
        }
    }
}

/// Lightweight flow layout that wraps its children onto multiple lines.
struct FlexibleWrap<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        Wrap(spacing: 10, lineSpacing: 10) {
            ForEach(Array(data), id: \.self) { content($0) }
        }
    }
}

/// A custom Layout that arranges subviews in wrapping rows.
struct Wrap: Layout {
    var spacing: CGFloat = 10
    var lineSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0, rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0, totalWidth: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + lineSpacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0; rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
