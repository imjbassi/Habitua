import Foundation
import AVFoundation
import Combine

/// Holds all real-time DSP state. A reference type so the render block can
/// mutate it in place without copying. Parameters set from the main thread are
/// plain stored properties - on ARM these word-sized writes are effectively
/// atomic, and brief tearing of a filter coefficient is inaudible.
private final class Synth {
    let sampleRate: Float

    // Sources
    var white = WhiteNoise()
    var pink = PinkNoise()
    var brown = BrownNoise()

    // Filters / modulators (rebuilt when parameters change)
    var notch: Biquad
    var lowpass: Biquad
    var highpass: Biquad
    var swell = LFO()
    var shimmer = LFO()
    var rainDensity = LFO()

    // Live parameters
    var preset: SoundPreset = .pinkNoise
    var notchFreq: Float = 6000

    // Smoothed gain to avoid clicks on start/stop/volume changes.
    var currentGain: Float = 0
    var targetGain: Float = 0

    // Pitch-matching tone (used during onboarding only).
    var toneEnabled = false
    var tone = SineOsc()
    var toneGain: Float = 0
    var toneTargetGain: Float = 0

    init(sampleRate: Float) {
        self.sampleRate = sampleRate
        notch = Biquad.notch(freq: 6000, q: 2.5, sampleRate: sampleRate)
        lowpass = Biquad.lowpass(freq: 700, q: 0.7, sampleRate: sampleRate)
        highpass = Biquad.highpass(freq: 2500, q: 0.7, sampleRate: sampleRate)
        swell.frequency = 0.06
        shimmer.frequency = 0.17
        rainDensity.frequency = 7.0
    }

    func rebuildFilters() {
        notch = Biquad.notch(freq: notchFreq, q: 2.5, sampleRate: sampleRate)
    }

    @inline(__always)
    func renderSample() -> Float {
        // Ramp gains toward targets (~30 ms smoothing).
        currentGain += (targetGain - currentGain) * 0.0008
        toneGain += (toneTargetGain - toneGain) * 0.0008

        let w = white.next()
        var s: Float

        switch preset {
        case .pinkNoise:
            s = pink.next(w)
        case .notchedNoise:
            s = notch.process(pink.next(w))
        case .brownNoise:
            s = brown.next(w)
        case .oceanish:
            // Low-passed brown noise with a slow swell envelope.
            let body = lowpass.process(brown.next(w))
            let env = 0.55 + 0.45 * swell.next(sampleRate: sampleRate)
            s = body * env * 1.4
        case .rain:
            // High-passed noise with a fast density flutter for a rainfall feel.
            let body = highpass.process(pink.next(w))
            let density = 0.6 + 0.4 * abs(rainDensity.next(sampleRate: sampleRate))
            s = body * density
        case .airy:
            // Breathy high band with a gentle shimmer.
            let body = highpass.process(pink.next(w))
            let env = 0.6 + 0.4 * shimmer.next(sampleRate: sampleRate)
            s = body * env
        }

        s *= currentGain

        if toneEnabled {
            s += tone.next(sampleRate: sampleRate) * toneGain * 0.25
        }

        // Soft clip for safety.
        if s > 1 { s = 1 } else if s < -1 { s = -1 }
        return s
    }
}

/// Public audio controller. Owns the AVAudioEngine graph and exposes simple,
/// observable controls to SwiftUI.
@MainActor
final class AudioEngine: ObservableObject {

    @Published private(set) var isPlaying = false
    @Published var volume: Double = 0.45 { didSet { synth.targetGain = Float(volume) * (isPlaying ? 1 : 0) } }

    /// Pitch-matching tone state (onboarding).
    @Published var matchToneFrequency: Double = 6000 {
        didSet { synth.tone.frequency = Float(matchToneFrequency) }
    }
    @Published private(set) var isToneOn = false

    private let engine = AVAudioEngine()
    private let synth: Synth
    private var sourceNode: AVAudioSourceNode!
    private var configured = false

    init() {
        let sr: Float = 44_100
        synth = Synth(sampleRate: sr)
        buildGraph(sampleRate: Double(sr))
    }

    private func buildGraph(sampleRate: Double) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        sourceNode = AVAudioSourceNode { [synth] _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let value = synth.renderSample()
                for buffer in abl {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = value
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0
    }

    // MARK: - Audio session

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // .playback so therapy continues with the screen locked / app backgrounded.
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            // Non-fatal: audio still plays in the foreground.
            print("Audio session error: \(error)")
        }
    }

    private func startEngineIfNeeded() {
        activateSession()
        if !engine.isRunning {
            do { try engine.start() } catch { print("Engine start error: \(error)") }
        }
    }

    // MARK: - Sound enrichment controls

    func configure(preset: SoundPreset, notchFrequency: Double) {
        synth.preset = preset
        synth.notchFreq = Float(notchFrequency)
        synth.rebuildFilters()
    }

    func setPreset(_ preset: SoundPreset) {
        synth.preset = preset
    }

    func play() {
        startEngineIfNeeded()
        synth.targetGain = Float(volume)
        isPlaying = true
    }

    func pause() {
        synth.targetGain = 0
        isPlaying = false
        // Leave the engine running briefly so the gain ramp can fade out cleanly,
        // then stop to release resources.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self, !self.isPlaying, !self.isToneOn else { return }
            self.engine.pause()
        }
    }

    func toggle() { isPlaying ? pause() : play() }

    // MARK: - Pitch-matching tone

    func startTone() {
        startEngineIfNeeded()
        synth.tone.frequency = Float(matchToneFrequency)
        synth.toneEnabled = true
        synth.toneTargetGain = 1
        isToneOn = true
    }

    func stopTone() {
        synth.toneTargetGain = 0
        isToneOn = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self, !self.isToneOn else { return }
            self.synth.toneEnabled = false
            if !self.isPlaying { self.engine.pause() }
        }
    }

    func toggleTone() { isToneOn ? stopTone() : startTone() }
}
