#!/usr/bin/env python3
"""Synthesise the film's ambient bed from scratch (no samples, no third-party audio).

    python3 synth_audio.py cues.json out.wav

cues.json = {"duration": s, "cues": [{"t": s, "kind": "strike|ignite|ignite_small|chime|star|page", "note": n}]}
(written by render.mjs from window.CUES in src/comp.js, so sound stays locked to picture).

Everything is additive sine synthesis + FFT-shaped noise, seeded, so it is deterministic:
  * room tone   - brown-ish noise, low-passed at 400 Hz, barely audible
  * drone pad   - open D (D2 A2 D3 A3 E4) of slightly detuned sines, slow swell, 0.07 Hz breathing
  * match strike- 90 ms of band-passed noise (2-7 kHz) with crackle, then a soft low "whoomph"
  * chimes      - bell partials (1, 2.0, 3.01, 4.17) with long exponential decay
  * stars       - seven tiny glints on a D major pentatonic, rising
  * page        - a slow, airy band-passed noise swell for each engraving
Mastered quietly (about -26 LUFS integrated, peaks around -11 dBFS); it should sit under platform UI and never announce itself.
"""
import json
import sys
import wave

import numpy as np

SR = 48000
rng = np.random.default_rng(1000)


def shaped_noise(n, lo, hi, tilt=0.0):
    """white noise band-limited to [lo, hi] Hz via FFT, with optional spectral tilt (dB/oct)"""
    x = rng.standard_normal(n)
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    g = np.zeros_like(f)
    band = (f >= lo) & (f <= hi)
    g[band] = 1.0
    # soft edges (half-octave)
    edge_lo = (f > lo / 1.41) & (f < lo)
    g[edge_lo] = np.sin(np.pi / 2 * np.log2(f[edge_lo] / (lo / 1.41)) / 0.5) ** 2
    edge_hi = (f > hi) & (f < hi * 1.41)
    g[edge_hi] = np.cos(np.pi / 2 * np.log2(f[edge_hi] / hi) / 0.5) ** 2
    if tilt:
        g *= (np.maximum(f, 1.0) / 1000.0) ** (tilt / 6.02)
    y = np.fft.irfft(X * g, n)
    return y / (np.abs(y).max() + 1e-9)


def env(n, a, d, sustain=1.0, release=None):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-np.maximum(0, t - a) / d) if d else np.minimum(1.0, t / max(a, 1e-4)) * sustain
    if release:
        e *= np.clip((n / SR - t) / release, 0, 1)
    return e


def add(buf, start, sig, gain_l, gain_r=None):
    i = int(start * SR)
    if i >= buf.shape[1]:
        return
    j = min(buf.shape[1], i + len(sig))
    buf[0, i:j] += sig[: j - i] * gain_l
    buf[1, i:j] += sig[: j - i] * (gain_r if gain_r is not None else gain_l)


def bell(freq, dur=3.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for ratio, amp, dec in ((1.0, 1.0, 1.6), (2.0, 0.35, 0.9), (3.01, 0.18, 0.55), (4.17, 0.08, 0.35)):
        s += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t / dec)
    return s * np.minimum(1, t / 0.006)


def main(cues_path, out):
    spec = json.load(open(cues_path))
    dur = spec["duration"]
    n = int(dur * SR)
    t = np.arange(n) / SR
    buf = np.zeros((2, n))

    # room tone
    room = shaped_noise(n, 40, 400, tilt=-3) * 0.010
    buf += room

    # drone pad: open D, fades in after the flame catches, breathes, fades with the final dissolve
    pad_env = np.clip((t - 1.4) / 3.0, 0, 1) ** 1.6
    pad_env *= 1 + 0.18 * np.clip((t - 20.3) / 2.0, 0, 1) - 0.18 * np.clip((t - 34.0) / 2.0, 0, 1)
    pad_env *= np.clip((dur - t) / 1.6, 0, 1)
    breathe = 0.85 + 0.15 * np.sin(2 * np.pi * 0.07 * t)
    pad = np.zeros((2, n))
    for f0, a in ((73.42, 0.55), (110.0, 0.45), (146.83, 0.38), (220.0, 0.22), (329.63, 0.10)):
        for ch, det in ((0, -0.6), (1, 0.6)):
            pad[ch] += a * np.sin(2 * np.pi * (f0 + det * f0 / 440) * t + ch * 0.7)
    buf += pad * pad_env * breathe * 0.020

    star_notes = [587.33, 659.25, 739.99, 880.0, 987.77, 1174.66, 1318.51]
    chime_notes = [587.33, 880.0, 440.0]
    for c in spec["cues"]:
        k, at = c["kind"], c["t"]
        if k == "strike":
            m = int(0.16 * SR)
            s = shaped_noise(m, 2000, 7000) * env(m, 0.004, 0.05)
            crackle = (rng.random(m) > 0.995) * rng.standard_normal(m) * env(m, 0.001, 0.08)
            add(buf, at - 0.03, s * 0.05 + crackle * 0.03, 0.9, 1.0)
        elif k in ("ignite", "ignite_small"):
            m = int(1.4 * SR)
            s = shaped_noise(m, 90, 900, tilt=-4) * env(m, 0.12, 0.45)
            g = 0.07 if k == "ignite" else 0.035
            add(buf, at, s * g, 1.0, 0.95)
        elif k == "chime":
            s = bell(chime_notes[c.get("note", 0) % 3], 4.0)
            add(buf, at, s * 0.022, 0.9, 1.0)
        elif k == "star":
            i = c.get("note", 0)
            s = bell(star_notes[i % 7], 1.6)
            pan = 0.3 + 0.07 * i
            add(buf, at, s * 0.012, 1.0 - pan * 0.5, 0.5 + pan * 0.5)
        elif k == "page":
            m = int(1.2 * SR)
            s = shaped_noise(m, 500, 4000, tilt=-3) * np.sin(np.pi * np.arange(m) / m) ** 2
            add(buf, at, s * 0.012, 1.0, 0.9)

    # global fades and a gentle safety limiter
    buf *= np.clip(t / 0.3, 0, 1) * np.clip((dur - t) / 0.4, 0, 1)
    peak = np.abs(buf).max()
    if peak > 0.5:
        buf *= 0.5 / peak
    buf *= 3.6  # make-up gain: lands around -26 LUFS integrated, peaks near -11 dBFS
    pcm = (np.clip(buf.T, -1, 1) * 32767).astype("<i2")
    with wave.open(out, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
