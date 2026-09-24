#!/usr/bin/env python3
"""Synthesise the two short samples used by the optional IBM style audio.

Everything the application plays is generated here so the repository never
has to carry a binary blob of unknown provenance:

  app/qml/sounds/keyclick.wav  a dry, single-shot key click in the spirit of
                               the buckling-spring keyboards IBM shipped with
                               the 3270/PC era terminals
  app/qml/sounds/bell.wav      the classic terminal attention beep

Usage:  python3 scripts/gen-sounds.py
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(os.path.dirname(HERE), "app", "qml", "sounds")


def write_wav(path, samples, sample_rate=SAMPLE_RATE):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(sample_rate)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(value * 32767))))
            for value in samples
        )
        handle.writeframes(frames)
    print("wrote %s (%.1f ms)" % (path, 1000.0 * len(samples) / sample_rate))


def key_click(duration=0.030, decay=190.0):
    """A short broadband tick: the hammer hitting the keycap.

    Three incommensurate partials give it a metallic edge, while an envelope
    with a very fast attack keeps it crisp rather than musical.
    """
    samples = []
    partials = ((1550.0, 1.0), (2870.0, 0.55), (4310.0, 0.30))
    for index in range(int(SAMPLE_RATE * duration)):
        t = index / SAMPLE_RATE
        envelope = math.exp(-decay * t)
        # A touch of deterministic noise keeps each click from sounding
        # perfectly periodic without needing a random source.
        noise = math.sin(2.0 * math.pi * 9973.0 * t) * 0.12
        value = sum(
            amplitude * math.sin(2.0 * math.pi * freq * t)
            for freq, amplitude in partials
        )
        samples.append(0.35 * envelope * (value * 0.6 + noise))
    return samples


def bell(duration=0.18, decay=13.0, frequencies=(1046.5, 2093.0)):
    """The attention beep: a bright partial with a second harmonic on top."""
    samples = []
    for index in range(int(SAMPLE_RATE * duration)):
        t = index / SAMPLE_RATE
        # Gentle attack so the beep does not click at the start.
        attack = min(1.0, t / 0.004)
        envelope = attack * math.exp(-decay * t)
        value = (
            0.72 * math.sin(2.0 * math.pi * frequencies[0] * t)
            + 0.28 * math.sin(2.0 * math.pi * frequencies[1] * t)
        )
        samples.append(0.30 * envelope * value)
    return samples


def main():
    write_wav(os.path.join(OUT_DIR, "keyclick.wav"), key_click())
    write_wav(os.path.join(OUT_DIR, "bell.wav"), bell())


if __name__ == "__main__":
    main()
