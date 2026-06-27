import Foundation
import SwiftUI

/// Single source of truth for persisted user data and derived progress metrics.
@MainActor
final class AppState: ObservableObject {

    @Published private(set) var data: AppData {
        didSet { persist() }
    }

    private let storeKey = "habitua.appdata.v1"

    init() {
        if let raw = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            self.data = decoded
        } else {
            self.data = AppData()
        }
    }

    // MARK: - Mutations

    func completeOnboarding(profile: TinnitusProfile) {
        data.profile = profile
        data.hasOnboarded = true
        // Seed the baseline as the first check-in so progress has a starting point.
        let baseline = CheckIn(distress: profile.baselineDistress,
                               intrusiveness: profile.baselineLoudness)
        data.checkIns.append(baseline)
    }

    func addCheckIn(_ checkIn: CheckIn) {
        // One check-in per day - replace if the user logs again the same day.
        data.checkIns.removeAll { $0.dayKey == checkIn.dayKey }
        data.checkIns.append(checkIn)
        data.checkIns.sort { $0.date < $1.date }
    }

    func recordSession(kind: SessionRecord.Kind, seconds: Int) {
        guard seconds > 5 else { return }   // ignore accidental taps
        data.sessions.append(SessionRecord(kind: kind, seconds: seconds))
    }

    func setLastPreset(_ preset: SoundPreset) { data.lastPreset = preset }
    func setDefaultMinutes(_ minutes: Int) { data.defaultSessionMinutes = minutes }
    func setHaptics(_ on: Bool) { data.hapticsEnabled = on }
    func updateProfile(_ profile: TinnitusProfile) { data.profile = profile }

    func resetAll() {
        data = AppData()
    }

    private func persist() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: storeKey)
        }
    }

    // MARK: - Derived metrics

    var todayCheckIn: CheckIn? {
        let key = CheckIn.dayFormatter.string(from: .now)
        return data.checkIns.first { $0.dayKey == key }
    }

    var hasCheckedInToday: Bool { todayCheckIn != nil }

    /// Total minutes practised across all session types.
    var totalPracticeMinutes: Int {
        data.sessions.reduce(0) { $0 + $1.seconds } / 60
    }

    /// Consecutive-day streak counting any day with a session OR check-in.
    var streak: Int {
        let cal = Calendar.current
        var activeDays = Set<String>()
        for s in data.sessions { activeDays.insert(s.dayKey) }
        for c in data.checkIns { activeDays.insert(c.dayKey) }
        guard !activeDays.isEmpty else { return 0 }

        var count = 0
        var day = Date.now
        // Allow the streak to be "alive" if today isn't logged yet but yesterday was.
        if !activeDays.contains(CheckIn.dayFormatter.string(from: day)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
            if !activeDays.contains(CheckIn.dayFormatter.string(from: day)) { return 0 }
        }
        while activeDays.contains(CheckIn.dayFormatter.string(from: day)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    /// Recent (last 7 logged) average distress, lower is better.
    var recentAverageDistress: Double? {
        let recent = data.checkIns.suffix(7)
        guard !recent.isEmpty else { return nil }
        return Double(recent.reduce(0) { $0 + $1.distress }) / Double(recent.count)
    }

    /// Change in distress from baseline to recent average. Negative = improvement.
    var distressTrend: Double? {
        guard let recent = recentAverageDistress else { return nil }
        let baseline = Double(data.profile.baselineDistress)
        return recent - baseline
    }

    // MARK: - Habituation programme

    /// The user advances a "tolerance level" roughly every 5 completed sessions.
    /// This drives the progressive-exposure ladder (longer silence tolerance,
    /// lower enrichment volume targets) without ever being punitive.
    var toleranceLevel: Int {
        min(8, 1 + data.sessions.count / 5)
    }

    var sessionsIntoCurrentLevel: Int {
        data.sessions.count % 5
    }

    /// Suggested silence-exposure duration (seconds) for the current level.
    /// Starts gentle and grows - the core of "training tolerance, not dependence".
    var silenceExposureSeconds: Int {
        // L1:30s, L2:45, L3:60, L4:90, L5:120, L6:180, L7:240, L8:300
        let ladder = [30, 45, 60, 90, 120, 180, 240, 300]
        return ladder[min(ladder.count - 1, toleranceLevel - 1)]
    }

    /// Recommended enrichment level as the brain habituates: the target volume
    /// drifts downward so the user relies on the sound less over time.
    var recommendedEnrichmentVolume: Double {
        // From 0.55 at L1 down toward 0.25 at L8.
        let t = Double(toleranceLevel - 1) / 7.0
        return 0.55 - 0.30 * t
    }
}
