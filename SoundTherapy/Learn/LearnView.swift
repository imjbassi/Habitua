import SwiftUI

struct Article: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let minutes: Int
    let symbol: String
    let tint: Color
    /// Body as an array of (heading?, paragraph) blocks.
    let blocks: [Block]

    struct Block: Identifiable {
        let id = UUID()
        var heading: String? = nil
        let text: String
    }
}

enum LearnLibrary {
    static let articles: [Article] = [
        Article(
            title: "Why masking can backfire",
            summary: "Covering the sound can keep your brain on alert.",
            minutes: 3, symbol: "speaker.slash.fill", tint: Theme.warmth,
            blocks: [
                .init(text: "Masking means playing noise loud enough to cover your tinnitus. It can bring relief in the moment, but there's a catch."),
                .init(heading: "The rebound effect",
                      text: "When the masking sound stops, many people find the ringing feels sharper than before. The contrast makes it stand out, and your attention snaps right back to it."),
                .init(heading: "Keeping the alarm on",
                      text: "Tinnitus becomes distressing when the brain tags it as a threat worth monitoring. Masking it completely reinforces the idea that the sound is something to escape, keeping the threat response switched on."),
                .init(heading: "A different aim",
                      text: "Habitua uses sound at a lower, blending level instead. The goal isn't to hide the tinnitus, but to let your brain hear it in a calm context until it stops flagging it as important.")
            ]),
        Article(
            title: "What habituation actually is",
            summary: "How the brain learns to ignore a constant sound.",
            minutes: 4, symbol: "brain.head.profile", tint: Theme.lilac,
            blocks: [
                .init(text: "Your brain is brilliant at tuning out constant, meaningless signals: the feeling of your clothes, the hum of a fridge. This filtering is called habituation."),
                .init(heading: "Two kinds of habituation",
                      text: "First, you habituate to the *reaction*: the sound stops triggering fear, frustration or anxiety. Then you habituate to the *perception*: you simply notice it less and less, even in quiet."),
                .init(heading: "Reaction comes first",
                      text: "This is why we track distress, not loudness. The ringing may sound the same for a while, yet bother you far less. That emotional shift is the foundation everything else is built on."),
                .init(heading: "Why it takes time",
                      text: "Habituation is a gradual relearning, usually over weeks to months. It's rarely linear. Good days and harder days are both part of the curve.")
            ]),
        Article(
            title: "The fear–attention loop",
            summary: "Why the more you fight it, the louder it gets.",
            minutes: 3, symbol: "arrow.triangle.2.circlepath", tint: Theme.accent,
            blocks: [
                .init(text: "Tinnitus distress runs on a loop: you notice the sound → it feels threatening → that triggers anxiety → anxiety sharpens your focus → which makes the sound more noticeable."),
                .init(heading: "Breaking the loop",
                      text: "You can't force yourself to stop hearing it. But you can lower the threat signal through calm breathing, acceptance, and gently redirecting attention. As the fear drops, the loop loses its fuel."),
                .init(heading: "Acceptance isn't giving up",
                      text: "Letting the sound be there, without bracing against it, is an active skill. Paradoxically, it's what allows the brain to finally let go of it.")
            ]),
        Article(
            title: "Sleep and tinnitus",
            summary: "Practical ways to rest when it's quiet.",
            minutes: 3, symbol: "moon.stars.fill", tint: Theme.mint,
            blocks: [
                .init(text: "Bedtime quiet often makes tinnitus loom large. A few habits help you fall asleep without becoming dependent on sound."),
                .init(heading: "Low, not loud",
                      text: "If you use sound at night, keep it faint: a soft enrichment under your tinnitus, not a blanket over it. A sleep timer prevents all-night reliance."),
                .init(heading: "Wind-down counts",
                      text: "Calm breathing or a body scan before bed lowers arousal, so the ringing has less emotional charge when the lights go out."),
                .init(heading: "If you wake at 3am",
                      text: "Don't fight it. Slow your out-breath, let the sound be background, and remind yourself: it's safe, and it doesn't require your attention.")
            ]),
        Article(
            title: "When to see a professional",
            summary: "Habitua complements care. It doesn't replace it.",
            minutes: 2, symbol: "cross.case.fill", tint: Theme.warmth,
            blocks: [
                .init(text: "Habitua is an educational wellness tool, not a medical device, and it doesn't diagnose or treat any condition."),
                .init(heading: "See a clinician if you have",
                      text: "Tinnitus in only one ear, pulsing tinnitus that beats with your heart, sudden hearing loss, dizziness, or tinnitus after a head injury. These deserve prompt medical attention."),
                .init(heading: "Worth a referral",
                      text: "If tinnitus is seriously affecting your mood, sleep, or daily life, an audiologist or ENT can assess your hearing and discuss options like formal Tinnitus Retraining Therapy or CBT, which this app is inspired by.")
            ])
    ]
}

struct LearnView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ScreenHeader(title: "Learn",
                                 subtitle: "Understanding tinnitus is part of defusing it.")
                    ForEach(LearnLibrary.articles) { article in
                        NavigationLink {
                            ArticleView(article: article)
                        } label: { row(article) }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ a: Article) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(a.tint.opacity(0.18)).frame(width: 50, height: 50)
                Image(systemName: a.symbol).font(.system(size: 20)).foregroundStyle(a.tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(a.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text(a.summary).font(.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(a.minutes) min read").font(.caption2).foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }
}

struct ArticleView: View {
    let article: Article

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(article.tint.opacity(0.18)).frame(width: 64, height: 64)
                    Image(systemName: article.symbol).font(.system(size: 28)).foregroundStyle(article.tint)
                }
                Text(article.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                ForEach(article.blocks) { block in
                    VStack(alignment: .leading, spacing: 6) {
                        if let heading = block.heading {
                            Text(heading).font(.headline).foregroundStyle(Theme.textPrimary)
                                .padding(.top, 4)
                        }
                        Text(block.text)
                            .font(.body).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(20)
        }
        .themedBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}
