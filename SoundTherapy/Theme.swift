import SwiftUI

/// Centralized design tokens for Habitua.
///
/// The palette leans on deep, calm indigo/teal tones - chosen to feel
/// grounding rather than clinical, supporting the app's goal of lowering
/// the emotional charge around tinnitus.
enum Theme {

    // MARK: Colors

    static let bgTop = Color(red: 0.06, green: 0.08, blue: 0.16)
    static let bgBottom = Color(red: 0.10, green: 0.13, blue: 0.24)
    static let surface = Color(red: 0.14, green: 0.17, blue: 0.30)
    static let surfaceRaised = Color(red: 0.18, green: 0.22, blue: 0.37)

    static let accent = Color(red: 0.47, green: 0.73, blue: 0.89)   // calm teal-blue
    static let accentSoft = Color(red: 0.47, green: 0.73, blue: 0.89).opacity(0.18)
    static let lilac = Color(red: 0.70, green: 0.64, blue: 0.92)
    static let mint = Color(red: 0.55, green: 0.86, blue: 0.78)
    static let warmth = Color(red: 0.96, green: 0.78, blue: 0.55)

    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.40)

    static let hairline = Color.white.opacity(0.10)

    // MARK: Gradients

    static var background: LinearGradient {
        LinearGradient(
            colors: [bgTop, bgBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, lilac],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var calmGradient: LinearGradient {
        LinearGradient(
            colors: [mint.opacity(0.9), accent.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Metrics

    static let corner: CGFloat = 22
    static let cardCorner: CGFloat = 18
}

// MARK: - Reusable view styling

/// A frosted card container used throughout the app.
struct Card<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
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

/// Primary filled call-to-action button.
struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.16))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(enabled ? AnyShapeStyle(Theme.accentGradient)
                                  : AnyShapeStyle(Theme.surfaceRaised))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Secondary, outline-style button.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.surfaceRaised)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    /// Applies the app's standard screen background.
    func themedBackground() -> some View {
        self.background(Theme.background.ignoresSafeArea())
    }
}
