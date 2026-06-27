import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var state: AppState
    @State private var showSettings = false
    @State private var showCheckIn = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header

                    // Daily check-in prompt or summary
                    checkInCard

                    // Today's plan
                    planCard

                    // Stats row
                    HStack(spacing: 12) {
                        StatTile(value: "\(state.streak)",
                                 label: state.streak == 1 ? "day streak" : "day streak",
                                 symbol: "flame.fill", tint: Theme.warmth)
                        StatTile(value: "\(state.totalPracticeMinutes)",
                                 label: "minutes practised",
                                 symbol: "clock.fill", tint: Theme.mint)
                        StatTile(value: "L\(state.toleranceLevel)",
                                 label: "tolerance level",
                                 symbol: "chart.bar.fill", tint: Theme.lilac)
                    }

                    encouragement
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showCheckIn) { CheckInView() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(dateText)
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var checkInCard: some View {
        Card {
            if let today = state.todayCheckIn {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Checked in today", systemImage: "checkmark.circle.fill")
                        .font(.headline).foregroundStyle(Theme.mint)
                    HStack(spacing: 20) {
                        miniMetric("Distress", today.distress)
                        miniMetric("Noticed", today.intrusiveness)
                    }
                    Button("Update today's check-in") { showCheckIn = true }
                        .font(.subheadline).foregroundStyle(Theme.accent)
                        .padding(.top, 2)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily check-in")
                        .font(.headline).foregroundStyle(Theme.textPrimary)
                    Text("Thirty seconds to track how tinnitus affected you today.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    Button("Check in") {
                        Haptics.tap(); showCheckIn = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    private func miniMetric(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)/10").font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
    }

    private var planCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today's session")
                    .font(.headline).foregroundStyle(Theme.textPrimary)

                NavigationLink {
                    TherapyPlayerView()
                } label: {
                    planRow(symbol: "waveform", tint: Theme.accent,
                            title: "Sound enrichment",
                            detail: "\(state.data.defaultSessionMinutes) min · \(state.data.lastPreset.title)")
                }
                Divider().overlay(Theme.hairline)
                NavigationLink {
                    ExercisesView()
                } label: {
                    planRow(symbol: "brain.head.profile", tint: Theme.lilac,
                            title: "Attention exercise",
                            detail: "Shift focus away from the ringing")
                }
                Divider().overlay(Theme.hairline)
                NavigationLink {
                    SilenceExposureView()
                } label: {
                    planRow(symbol: "ear.fill", tint: Theme.mint,
                            title: "Silence tolerance",
                            detail: "\(timeString(state.silenceExposureSeconds)) of quiet, level \(state.toleranceLevel)")
                }
            }
        }
    }

    private func planRow(symbol: String, tint: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.18)).frame(width: 44, height: 44)
                Image(systemName: symbol).foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text(detail).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textTertiary)
        }
    }

    private var encouragement: some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "quote.opening")
                    .foregroundStyle(Theme.accent)
                Text(dailyMessage)
                    .font(.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Helpers

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    private var dateText: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: .now)
    }

    private var dailyMessage: String {
        let messages = [
            "Your tinnitus hasn't changed today. But your relationship with it can. That's the work.",
            "Notice the sound without arguing with it. Acceptance lowers the alarm.",
            "Quiet moments feel loud at first. Each one you sit with builds tolerance.",
            "You're not trying to silence it. You're teaching your brain it's safe to ignore.",
            "Habituation is invisible day to day, then suddenly you realise you forgot to listen.",
            "Lower the volume than you think you need. Less reliance, more retraining."
        ]
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return messages[day % messages.count]
    }
}
