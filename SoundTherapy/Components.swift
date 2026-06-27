import SwiftUI

/// Large screen title with optional subtitle, used at the top of tab screens.
struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A compact metric tile (streak, minutes, etc.).
struct StatTile: View {
    let value: String
    let label: String
    var symbol: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }
}

/// A 0–10 scale slider with descriptive end labels.
struct ScaleSlider: View {
    let title: String
    @Binding var value: Int
    var lowLabel: String
    var highLabel: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(value)")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }
            Slider(value: Binding(
                get: { Double(value) },
                set: { newValue in
                    let rounded = Int(newValue.rounded())
                    if rounded != value { Haptics.soft() }
                    value = rounded
                }
            ), in: 0...10, step: 1)
            .tint(tint)
            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.caption)
            .foregroundStyle(Theme.textTertiary)
        }
    }
}

/// A selectable chip for enums (quality, laterality, etc.).
struct SelectChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selected ? Color(red: 0.06, green: 0.08, blue: 0.16) : Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(selected ? AnyShapeStyle(Theme.accentGradient)
                                            : AnyShapeStyle(Theme.surfaceRaised))
                )
        }
        .buttonStyle(.plain)
    }
}

/// A softly pulsing concentric orb - the calming visual centrepiece used in
/// the player and exercise screens. Pulses faster/brighter when `active`.
///
/// Everything is sized relative to `size` and stays *within* the declared
/// frame (the largest ring tops out at ~0.9·size), so the orb never spills
/// past its bounds or the screen edges, however it animates.
struct PulsingOrb: View {
    var active: Bool
    var tint: Color = Theme.accent
    var size: CGFloat = 240
    @State private var animate = false

    var body: some View {
        ZStack {
            // Concentric halo rings: 0.5·, 0.7·, 0.9· of size at full pulse.
            ForEach(0..<3) { i in
                let ring = size * (0.5 + CGFloat(i) * 0.2)
                Circle()
                    .fill(tint.opacity(0.18 - Double(i) * 0.045))
                    .frame(width: ring, height: ring)
                    .scaleEffect(animate ? 1.0 : 0.86)
            }
            // Solid glowing core.
            Circle()
                .fill(
                    RadialGradient(colors: [tint.opacity(0.9), tint.opacity(0.25)],
                                   center: .center, startRadius: 4, endRadius: size * 0.23)
                )
                .frame(width: size * 0.46, height: size * 0.46)
                .scaleEffect(animate ? 1.05 : 0.94)
                .shadow(color: tint.opacity(active ? 0.55 : 0.2), radius: 26)
        }
        .frame(width: size, height: size)
        .onAppear { startAnimation() }
        .onChange(of: active) { _, _ in startAnimation() }
    }

    private func startAnimation() {
        let duration = active ? 3.4 : 5.0
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            animate = true
        }
    }
}

/// Formats seconds as m:ss for timers.
func timeString(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
