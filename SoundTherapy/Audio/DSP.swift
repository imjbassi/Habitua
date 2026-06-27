import Foundation

/// A second-order IIR (biquad) filter. Used for the band-reject notch in
/// notched sound therapy and for shaping coloured noise.
struct Biquad {
    var b0: Float = 1, b1: Float = 0, b2: Float = 0
    var a1: Float = 0, a2: Float = 0
    private var z1: Float = 0, z2: Float = 0   // transposed direct form II state

    @inline(__always)
    mutating func process(_ x: Float) -> Float {
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }

    mutating func reset() { z1 = 0; z2 = 0 }

    /// Band-reject (notch) centred at `freq` with quality factor `q`.
    static func notch(freq: Float, q: Float, sampleRate: Float) -> Biquad {
        let w0 = 2 * Float.pi * freq / sampleRate
        let cosw = cos(w0)
        let alpha = sin(w0) / (2 * q)
        let a0 = 1 + alpha
        var f = Biquad()
        f.b0 = 1 / a0
        f.b1 = (-2 * cosw) / a0
        f.b2 = 1 / a0
        f.a1 = (-2 * cosw) / a0
        f.a2 = (1 - alpha) / a0
        return f
    }

    /// Low-pass for warming/rounding noise (e.g. ocean, brown shaping).
    static func lowpass(freq: Float, q: Float, sampleRate: Float) -> Biquad {
        let w0 = 2 * Float.pi * freq / sampleRate
        let cosw = cos(w0)
        let alpha = sin(w0) / (2 * q)
        let a0 = 1 + alpha
        var f = Biquad()
        f.b0 = ((1 - cosw) / 2) / a0
        f.b1 = (1 - cosw) / a0
        f.b2 = ((1 - cosw) / 2) / a0
        f.a1 = (-2 * cosw) / a0
        f.a2 = (1 - alpha) / a0
        return f
    }

    /// High-pass for airy/breathy textures.
    static func highpass(freq: Float, q: Float, sampleRate: Float) -> Biquad {
        let w0 = 2 * Float.pi * freq / sampleRate
        let cosw = cos(w0)
        let alpha = sin(w0) / (2 * q)
        let a0 = 1 + alpha
        var f = Biquad()
        f.b0 = ((1 + cosw) / 2) / a0
        f.b1 = -(1 + cosw) / a0
        f.b2 = ((1 + cosw) / 2) / a0
        f.a1 = (-2 * cosw) / a0
        f.a2 = (1 - alpha) / a0
        return f
    }
}

/// Pink-noise generator using Paul Kellet's economical filter on white noise.
/// Produces ~ -3 dB/octave spectrum that the ear hears as natural and balanced.
struct PinkNoise {
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0
    private var b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0

    @inline(__always)
    mutating func next(_ white: Float) -> Float {
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
        b6 = white * 0.115926
        return pink * 0.11   // scale into roughly [-1, 1]
    }
}

/// Brown (red) noise - a leaky integrator of white noise. Deep and rumbling.
struct BrownNoise {
    private var last: Float = 0

    @inline(__always)
    mutating func next(_ white: Float) -> Float {
        last = (last + 0.02 * white) / 1.02
        return last * 3.5
    }
}

/// A simple low-frequency oscillator for slow amplitude movement
/// (ocean swells, rain density, breathing envelopes).
struct LFO {
    var phase: Float = 0
    var frequency: Float = 0.1   // Hz

    @inline(__always)
    mutating func next(sampleRate: Float) -> Float {
        phase += 2 * Float.pi * frequency / sampleRate
        if phase > 2 * Float.pi { phase -= 2 * Float.pi }
        return sin(phase)
    }
}

/// Deterministic, fast xorshift white-noise source (avoids per-sample
/// allocation / locking that `arc4random` would introduce in the render thread).
struct WhiteNoise {
    private var state: UInt32

    init(seed: UInt32 = 0x1234_5678) { state = seed == 0 ? 1 : seed }

    @inline(__always)
    mutating func next() -> Float {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        // Map to [-1, 1)
        return Float(Int32(bitPattern: state)) / Float(Int32.max)
    }
}

/// Pure sine oscillator used by the tinnitus pitch-matching tool.
struct SineOsc {
    var phase: Float = 0
    var frequency: Float = 6000

    @inline(__always)
    mutating func next(sampleRate: Float) -> Float {
        phase += 2 * Float.pi * frequency / sampleRate
        if phase > 2 * Float.pi { phase -= 2 * Float.pi }
        return sin(phase)
    }
}
