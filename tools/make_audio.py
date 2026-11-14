# Generates synth kirtan backing loops (drone, khole, kartal). Run: python3 tools/make_audio.py
import numpy as np, wave
SR = 32000
BPM = 104
BEAT = 60.0 / BPM
STEPS = 16                      # 16th notes per bar (4 beats)
BARS = 4
STEP = BEAT / 4
N = int(round(STEP * STEPS * BARS * SR))
rng = np.random.default_rng(7)

def add(buf, start, snd):       # circular add so loops are seamless
    idx = (start + np.arange(len(snd))) % len(buf)
    np.add.at(buf, idx, snd)

def env(n, decay): return np.exp(-np.arange(n) / (decay * SR))

def khole_low(vel):
    n = int(0.55 * SR); t = np.arange(n) / SR
    f = 60 + 55 * np.exp(-t * 14)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.16)
    s += rng.normal(0, 1, n) * env(n, 0.008) * 0.25
    return s * vel

def khole_slap(vel):
    n = int(0.25 * SR); t = np.arange(n) / SR
    s = np.sin(2 * np.pi * 330 * t) * env(n, 0.05) * 0.6
    s += np.sin(2 * np.pi * 520 * t) * env(n, 0.03) * 0.3
    s += rng.normal(0, 1, n) * env(n, 0.012) * 0.45
    return s * vel

def kartal(vel, decay):
    n = int(0.6 * SR); t = np.arange(n) / SR
    s = np.zeros(n)
    for f, a in [(4300, 1), (5600, .8), (7100, .7), (9300, .5), (11800, .35)]:
        s += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28))
    s += rng.normal(0, 1, n) * 1.2
    s = np.diff(s, prepend=0)   # crude high-pass
    return s * env(n, decay) * vel * 0.12

khole = np.zeros(N); kar = np.zeros(N)
# khole pattern per bar (16 steps): L=low, S=slap, .=rest
pat = "L..SL.S.L..SS.L."
for b in range(BARS):
    for i, c in enumerate(pat):
        st = int(round((b * STEPS + i) * STEP * SR))
        if c == "L": add(khole, st, khole_low(1.0 if i % 8 == 0 else .75))
        if c == "S": add(khole, st, khole_slap(.7))
    for i in range(STEPS):      # kartal on every 8th-note, accent on beats
        st = int(round((b * STEPS + i) * STEP * SR))
        if i % 2 == 0: add(kar, st, kartal(1.0 if i % 4 == 0 else .6, .10 if i % 8 == 0 else .05))

# drone: harmonium-like chord with seamless loop (integer cycles per loop)
L = N / SR; t = np.arange(N) / SR; drone = np.zeros(N)
for f, a in [(130.81, 1.0), (196.0, .8), (261.63, .6), (392.0, .3)]:
    f = round(f * L) / L
    for h in range(1, 7):
        drone += a * np.sin(2 * np.pi * f * h * t) / h ** 1.2
drone *= 1 + .06 * np.sin(2 * np.pi * round(5.2 * L) / L * t)

def save(name, x, peak):
    x = x / (np.abs(x).max() + 1e-9) * peak
    with wave.open(f"assets/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())

save("khole", khole, .9); save("kartal", kar, .8); save("drone", drone, .5)
print("done", N / SR, "sec per loop")
