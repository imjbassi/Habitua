import Foundation

// MARK: - Tinnitus profile

/// The perceptual character of the user's tinnitus, captured during onboarding.
/// Used to tailor notched sound therapy and to frame educational content.
struct TinnitusProfile: Codable, Equatable {
    /// Matched pitch of the tinnitus in Hz (best estimate from the matching tool).
    var frequencyHz: Double = 6000
    /// Perceived character of the sound.
    var quality: Quality = .ringing
    /// Which ear(s) the sound is perceived in.
    var laterality: Laterality = .both
    /// Self-reported loudness on a 0–10 scale at onboarding (baseline).
    var baselineLoudness: Int = 5
    /// How distressing the tinnitus felt at onboarding (0–10).
    var baselineDistress: Int = 5

    enum Quality: String, Codable, CaseIterable, Identifiable {
        case ringing, hissing, buzzing, whistling, cricket, roaring
        var id: String { rawValue }
        var label: String {
            switch self {
            case .ringing: return "Ringing"
            case .hissing: return "Hissing"
            case .buzzing: return "Buzzing"
            case .whistling: return "Whistling"
            case .cricket: return "Crickets"
            case .roaring: return "Roaring"
            }
        }
    }

    enum Laterality: String, Codable, CaseIterable, Identifiable {
        case left, right, both, head
        var id: String { rawValue }
        var label: String {
            switch self {
            case .left: return "Left ear"
            case .right: return "Right ear"
            case .both: return "Both ears"
            case .head: return "Inside my head"
            }
        }
    }
}

// MARK: - Daily check-in

/// A lightweight daily reflection. The emphasis is on *reaction* to tinnitus,
/// not the sound itself - distress and intrusiveness are the metrics that
/// habituation actually moves.
struct CheckIn: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date = .now
    /// How much the tinnitus bothered you today (0 = not at all, 10 = unbearable).
    var distress: Int
    /// How often you noticed it (0 = rarely, 10 = constantly).
    var intrusiveness: Int
    /// Optional free-text note.
    var note: String = ""

    var dayKey: String { CheckIn.dayFormatter.string(from: date) }

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

// MARK: - Therapy / exercise session record

/// A completed listening or exercise session, used to compute streaks and
/// total practice time.
struct SessionRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date = .now
    var kind: Kind
    /// Duration actually completed, in seconds.
    var seconds: Int

    enum Kind: String, Codable {
        case soundTherapy
        case attention
        case relaxation
        case silenceExposure
    }

    var dayKey: String { CheckIn.dayFormatter.string(from: date) }
}

// MARK: - Sound presets

/// The sound-enrichment options. None of these are "maskers" in the cover-it-up
/// sense - they are designed to be played at or below the tinnitus level (the
/// "mixing point") so the brain learns to file the sound as unimportant.
enum SoundPreset: String, Codable, CaseIterable, Identifiable {
    case pinkNoise
    case notchedNoise
    case brownNoise
    case oceanish
    case rain
    case airy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pinkNoise: return "Pink Noise"
        case .notchedNoise: return "Notched Therapy"
        case .brownNoise: return "Brown Noise"
        case .oceanish: return "Ocean Swell"
        case .rain: return "Soft Rain"
        case .airy: return "Airy Drift"
        }
    }

    var subtitle: String {
        switch self {
        case .pinkNoise: return "Balanced, natural broadband sound"
        case .notchedNoise: return "Filtered around your tinnitus pitch"
        case .brownNoise: return "Deep, low, rumbling warmth"
        case .oceanish: return "Slow rolling swells"
        case .rain: return "Gentle steady rainfall"
        case .airy: return "High, breathy, weightless"
        }
    }

    var symbol: String {
        switch self {
        case .pinkNoise: return "waveform"
        case .notchedNoise: return "waveform.path.ecg"
        case .brownNoise: return "speaker.wave.3.fill"
        case .oceanish: return "water.waves"
        case .rain: return "cloud.rain.fill"
        case .airy: return "wind"
        }
    }

    /// Notched therapy is the clinically-distinctive one and deserves a flag in UI.
    var isNotched: Bool { self == .notchedNoise }
}

// MARK: - Persistable app data

/// The full serialisable state of the app. Persisted as JSON in UserDefaults
/// by `AppState`.
struct AppData: Codable {
    var hasOnboarded: Bool = false
    var profile: TinnitusProfile = TinnitusProfile()
    var checkIns: [CheckIn] = []
    var sessions: [SessionRecord] = []
    /// Last selected sound preset, restored on launch.
    var lastPreset: SoundPreset = .pinkNoise
    /// User's default session length in minutes.
    var defaultSessionMinutes: Int = 20
    /// Master toggle for haptics.
    var hapticsEnabled: Bool = true
}
