#!/usr/bin/env python3
"""Synthesizes the game's mechanical sounds as 16-bit mono WAVs (no assets, no deps beyond numpy)."""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def save(name, x, vol=0.8):
    x = np.clip(x, -1, 1) * vol
    data = (x * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"{name}: {len(x) / SR:.2f}s")


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def attack_env(n, a=0.004):
    e = np.ones(n)
    na = max(1, int(SR * a))
    e[:na] = np.linspace(0, 1, na)
    return e


# engine: 1.0 s loopable saw at exactly 85 Hz (+ harmonic, one-pole LP, gentle AM at 8 Hz)
t = t_axis(1.0)
phase = 2 * np.pi * 85 * t
saw = 2 * ((phase / (2 * np.pi)) % 1) - 1
engine = lowpass(saw + 0.4 * np.sign(np.sin(2 * phase)), 0.12)
engine *= 1 + 0.08 * np.sin(2 * np.pi * 8 * t)
engine *= attack_env(len(t))
save("engine_loop", engine / np.max(np.abs(engine)), 0.55)

# siren: 1.2 s two-tone 660/880, continuous phase, loopable
t = t_axis(1.2)
freq = np.where(((t % 0.6) < 0.3), 660.0, 880.0)
ph = 2 * np.pi * np.cumsum(freq) / SR
siren = np.sign(np.sin(ph)) * 0.6 + 0.4 * np.sin(ph)
siren *= attack_env(len(t))
save("siren_loop", siren / np.max(np.abs(siren)), 0.5)

# crash: noise burst, fast decay
t = t_axis(0.35)
crash = lowpass(np.random.default_rng(7).standard_normal(len(t)), 0.25) * np.exp(-t / 0.07)
save("crash", crash / np.max(np.abs(crash)), 0.9)

# thud: dull body hit
t = t_axis(0.18)
thud = lowpass(np.random.default_rng(3).standard_normal(len(t)), 0.08) * np.exp(-t / 0.04) + 0.7 * np.sin(2 * np.pi * 60 * t) * np.exp(-t / 0.05)
save("thud", thud / np.max(np.abs(thud)), 0.8)

# honk: two-tone chord, short
t = t_axis(0.22)
honk = (np.sign(np.sin(2 * np.pi * 330 * t)) * 0.5 + np.sign(np.sin(2 * np.pi * 415 * t)) * 0.5) * np.exp(-t / 0.16)
honk *= attack_env(len(t))
save("honk", honk / np.max(np.abs(honk)), 0.5)

# blip: quick UI chirp up
t = t_axis(0.06)
blip = np.sin(2 * np.pi * (880 + 320 * t / 0.06) * t) * np.exp(-t / 0.03)
save("blip", blip, 0.5)

# pickup: two rising tones
t = t_axis(0.14)
pickup = np.sin(2 * np.pi * 660 * t) * (t < 0.06) + np.sin(2 * np.pi * 990 * t) * (t >= 0.06)
pickup *= np.exp(-np.maximum(t - 0.06, 0) / 0.05) * attack_env(len(t))
save("pickup", pickup, 0.6)

# win: little arpeggio
notes = [523.25, 659.25, 783.99, 1046.5]
seg = 0.16
t = t_axis(seg * 4 + 0.1)
win = np.zeros(len(t))
for i, f in enumerate(notes):
    m = (t >= i * seg) & (t < (i + 1) * seg + (0.1 if i == 3 else 0))
    tt = t[m] - i * seg
    win[m] = np.sin(2 * np.pi * f * tt) * np.exp(-tt / (0.12 if i == 3 else 0.08))
win *= attack_env(len(t))
save("win", win, 0.65)

# alert: wanted-star warning, dropping square
t = t_axis(0.13)
alert = np.sign(np.sin(2 * np.pi * (200 - 60 * t / 0.13) * t)) * np.exp(-t / 0.09)
save("alert", alert, 0.45)

# door: car door shut
t = t_axis(0.09)
door = lowpass(np.random.default_rng(11).standard_normal(len(t)), 0.35) * np.exp(-t / 0.025)
save("door", door / np.max(np.abs(door)), 0.7)
