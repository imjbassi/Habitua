import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ScreenHeader(title: "Progress",
                                 subtitle: "Habituation is measured by how little it bothers you, not by how loud it is.")

                    trendSummary

                    distressChart

                    HStack(spacing: 12) {
                        StatTile(value: "\(state.streak)", label: "day streak",
                                 symbol: "flame.fill", tint: Theme.warmth)
                        StatTile(value: "\(state.data.sessions.count)", label: "sessions done",
                                 symbol: "checkmark.seal.fill", tint: Theme.mint)
                    }

                    toleranceCard

                    practiceBreakdown

                    if state.data.checkIns.count < 3 {
                        emptyHint
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Trend summary

    private var trendSummary: some View {
        Card {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(trendColor.opacity(0.18)).frame(width: 56, height: 56)
                    Image(systemName: trendSymbol).font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(trendColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(trendHeadline).font(.headline).foregroundStyle(Theme.textPrimary)
                    Text(trendDetail).font(.subheadline).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }

    private var distressChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Distress & awareness over time")
                    .font(.headline).foregroundStyle(Theme.textPrimary)

                if state.data.checkIns.count < 2 {
                    Text("Check in for a couple of days to see your trend appear here.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                        .frame(height: 160, alignment: .center)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart {
                        ForEach(state.data.checkIns) { c in
                            LineMark(x: .value("Date", c.date),
                                     y: .value("Level", c.distress),
                                     series: .value("Metric", "Distress"))
                                .foregroundStyle(by: .value("Metric", "Distress"))
                                .interpolationMethod(.catmullRom)
                        }
                        ForEach(state.data.checkIns) { c in
                            LineMark(x: .value("Date", c.date),
                                     y: .value("Level", c.intrusiveness),
                                     series: .value("Metric", "Awareness"))
                                .foregroundStyle(by: .value("Metric", "Awareness"))
                                .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartYScale(domain: 0...10)
                    .chartForegroundStyleScale([
                        "Distress": Theme.warmth, "Awareness": Theme.accent
                    ])
                    .chartLegend(position: .bottom)
                    .frame(height: 180)
                }
            }
        }
    }

    private var toleranceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Tolerance level").font(.headline).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("L\(state.toleranceLevel) / 8")
                        .font(.subheadline.weight(.bold)).foregroundStyle(Theme.lilac)
                }
                ProgressView(value: Double(state.sessionsIntoCurrentLevel), total: 5)
                    .tint(Theme.lilac)
                Text("Each level extends your silence-tolerance window and lowers the sound you rely on. \(5 - state.sessionsIntoCurrentLevel) more session\(5 - state.sessionsIntoCurrentLevel == 1 ? "" : "s") to level \(min(8, state.toleranceLevel + 1)).")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var practiceBreakdown: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Practice mix").font(.headline).foregroundStyle(Theme.textPrimary)
                breakdownRow("Sound enrichment", .soundTherapy, Theme.accent)
                breakdownRow("Attention", .attention, Theme.lilac)
                breakdownRow("Relaxation", .relaxation, Theme.mint)
                breakdownRow("Silence exposure", .silenceExposure, Theme.warmth)
            }
        }
    }

    private func breakdownRow(_ label: String, _ kind: SessionRecord.Kind, _ tint: Color) -> some View {
        let count = state.data.sessions.filter { $0.kind == kind }.count
        let maxCount = max(1, SessionRecord.Kind.allCounts(in: state.data.sessions))
        return HStack(spacing: 12) {
            Text(label).font(.subheadline).foregroundStyle(Theme.textSecondary)
                .frame(width: 130, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceRaised)
                    Capsule().fill(tint)
                        .frame(width: max(6, geo.size.width * CGFloat(count) / CGFloat(maxCount)))
                }
            }
            .frame(height: 10)
            Text("\(count)").font(.caption.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private var emptyHint: some View {
        Text("Keep showing up. The most reliable sign of habituation is realising, weeks from now, that you went hours without thinking about it.")
            .font(.footnote)
            .foregroundStyle(Theme.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    // MARK: - Trend helpers

    private var trendColor: Color {
        guard let t = state.distressTrend else { return Theme.accent }
        return t < -0.5 ? Theme.mint : (t > 0.5 ? Theme.warmth : Theme.accent)
    }
    private var trendSymbol: String {
        guard let t = state.distressTrend else { return "sparkles" }
        return t < -0.5 ? "arrow.down.right" : (t > 0.5 ? "arrow.up.right" : "arrow.right")
    }
    private var trendHeadline: String {
        guard let t = state.distressTrend else { return "Getting started" }
        if t < -0.5 { return "Distress is easing" }
        if t > 0.5 { return "A harder stretch" }
        return "Holding steady"
    }
    private var trendDetail: String {
        guard let t = state.distressTrend, let recent = state.recentAverageDistress else {
            return "Check in daily to see how your reaction to tinnitus changes."
        }
        let baseline = state.data.profile.baselineDistress
        let recentStr = String(format: "%.1f", recent)
        if t < -0.5 { return "Recent distress \(recentStr)/10 vs \(baseline)/10 at baseline. The retraining is working." }
        if t > 0.5 { return "Recent distress \(recentStr)/10 vs \(baseline)/10. Flare-ups are normal. Keep practising gently." }
        return "Recent distress \(recentStr)/10. Habituation isn't linear; consistency matters more than any single day."
    }
}

private extension SessionRecord.Kind {
    /// The largest per-kind session count, for scaling the breakdown bars.
    static func allCounts(in sessions: [SessionRecord]) -> Int {
        let kinds: [SessionRecord.Kind] = [.soundTherapy, .attention, .relaxation, .silenceExposure]
        return kinds.map { k in sessions.filter { $0.kind == k }.count }.max() ?? 0
    }
}
