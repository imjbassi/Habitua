# Habitua — Tinnitus Habituation, Not Masking

**[Try the live demo](https://appetize.io/app/b_r6l3smpipjg43mcxzrsenrs32e)** — runs in your browser, no iPhone needed.

An iOS app that helps people with tinnitus *build tolerance* instead of
becoming dependent on masking. Where most apps cover the ringing with louder
noise, Habitua uses gentle, below-threshold sound enrichment, attention
retraining, and **progressive exposure to quiet** to retrain the brain to
treat the sound as non-threatening — so it fades into the background, even in
silence.

The approach is informed by **Tinnitus Retraining Therapy (TRT)** and
**cognitive behavioural** principles. It is an educational wellness tool, not a
medical device.

## What's inside

| Area | What it does |
|------|--------------|
| **Onboarding** | Explains habituation vs. masking, profiles the tinnitus (character, location), an interactive **pitch-matching** tool, and a baseline check-in. |
| **Sound** | Real-time generated sound enrichment — pink/brown noise, ocean/rain/airy textures, and **notched therapy** filtered around *your* tinnitus pitch. Includes a "mixing point" guide so you never mask. |
| **Train** | Guided **attention-shift** and **sound-widening** exercises, calm breathing, tension release, and the **progressive silence-exposure** ladder that grows with your tolerance level. |
| **Progress** | Tracks *distress* and *awareness* over time (the metrics habituation actually moves), streak, tolerance level, and practice mix — charted with Swift Charts. |
| **Learn** | Short articles reframing tinnitus as non-threatening, on sleep, the fear–attention loop, and when to see a professional. |

## Tech

- **SwiftUI**, iOS 17+, no third-party dependencies.
- **AVAudioEngine** with a real-time `AVAudioSourceNode` synthesising all audio
  on the fly (`Audio/DSP.swift`, `Audio/AudioEngine.swift`) — pink/brown noise,
  biquad notch/low-pass/high-pass filters, LFO modulation. No bundled audio
  files.
- Local persistence via `UserDefaults` (JSON-encoded `AppData`).
- Background audio enabled so therapy continues with the screen locked.

## Building & running

> **One-time setup:** Xcode's license must be accepted before the toolchain
> will compile anything:
>
> ```sh
> sudo xcodebuild -license accept
> ```

Then:

```sh
open SoundTherapy.xcodeproj
# Select the "Habitua" scheme + an iPhone simulator, press ⌘R
```

Or from the command line:

```sh
xcodebuild -scheme Habitua -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Project layout

```
SoundTherapy/
├── SoundTherapyApp.swift      App entry + onboarding gate
├── Theme.swift                Design tokens, buttons, cards
├── Models.swift               TinnitusProfile, CheckIn, SessionRecord, AppData
├── AppState.swift             Store + derived metrics (streak, tolerance ladder)
├── Components.swift           Shared UI (orb, sliders, chips, stat tiles)
├── Haptics.swift
├── Audio/
│   ├── DSP.swift              Noise generators, biquad filters, oscillators
│   └── AudioEngine.swift      AVAudioEngine graph + controls
├── Onboarding/                Multi-step intro + pitch matching
├── Main/                      Today dashboard, daily check-in
├── Therapy/                   Sound enrichment player
├── Exercises/                 Guided exercises + silence exposure
├── Progress/                  Charts dashboard
├── Learn/                     Education library
└── Settings/                  Profile, defaults, reset
```

## Notes & next steps

- The app icon set is intentionally empty (builds with a placeholder); drop a
  1024×1024 PNG into `Assets.xcassets/AppIcon.appiconset` to brand it.
- Possible future work: HealthKit/notification reminders, sleep-timer with
  fade-out, Apple Watch session control, iCloud sync, and a clinician-validated
  questionnaire (e.g. THI) for outcome tracking.
- **Not a medical device.** One-sided, pulsatile, or sudden tinnitus, or any
  hearing loss, warrants seeing an audiologist or ENT.
