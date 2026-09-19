"""Tanıtım videosunun müziğini ve arayüz seslerini sentezler.

Hepsi burada üretildiği için telif derdi yok. Çıktılar public/audio/ altına
WAV olarak yazılır.

    python scripts/gen_audio.py
"""
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'public', 'audio')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(11)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def t_(sec):
    return np.arange(int(sec * SR)) / SR


def write(name, x, peak=0.9):
    x = np.asarray(x, dtype=np.float64)
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    data = (x * 32767).astype('<i2')
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print('yazıldı', name, f'{len(x) / SR:.2f} sn')


def lowpass(x, fc):
    """Tek kutuplu alçak geçiren (iki kez: 12 dB/oktav)."""
    a = 1 - np.exp(-2 * np.pi * fc / SR)
    for _ in range(2):
        y = np.empty_like(x)
        acc = 0.0
        for i in range(len(x)):
            acc += a * (x[i] - acc)
            y[i] = acc
        x = y
    return x


def comb(x, d, g):
    y = x.copy()
    for i in range(d, len(y), d):
        e = min(i + d, len(y))
        y[i:e] += g * y[i - d:e - d]
    return y


def reverb(x, mix=0.25, size=1.0):
    wet = sum(comb(x, int(SR * s * size), g) for s, g in
              [(0.0297, 0.78), (0.0371, 0.76), (0.0411, 0.74), (0.0437, 0.72), (0.0533, 0.7)]) / 5
    return x * (1 - mix) + wet * mix


# ================================================================ müzik
# Sakin, sıcak bir lo-fi: FM elektrik piyano akorları, yumuşak davul,
# alt bas ve seyrek bir melodi. 90 BPM.
BPM = 90
BEAT = 60 / BPM
BAR = BEAT * 4
LENGTH = 26.7
N = int(LENGTH * SR)
L = np.zeros(N)
R = np.zeros(N)
keys_l = np.zeros(N)
keys_r = np.zeros(N)
duck = np.ones(N)

# Gmaj7 – F#m7 – Bm7 – A6/9
CHORDS = [
    ([55, 59, 62, 66], 31),
    ([54, 57, 61, 64], 30),
    ([54, 57, 59, 62], 35),
    ([54, 57, 59, 64], 33),
]


def add(buf, start, sig, gain=1.0):
    s = int(start * SR)
    if s >= N or s < 0:
        return
    e = min(N, s + len(sig))
    buf[s:e] += sig[: e - s] * gain


def epiano(freq, dur):
    """FM elektrik piyano: yumuşak gövde + kısa 'tine' parlaması."""
    t = t_(dur)
    idx = 1.3 * np.exp(-t * 2.5) + 0.25
    body = np.sin(2 * np.pi * freq * t + idx * np.sin(2 * np.pi * freq * t))
    tine = 0.12 * np.sin(2 * np.pi * freq * 14 * t) * np.exp(-t * 40)
    env = np.minimum(1, t / 0.004) * np.exp(-t * 0.9) * np.minimum(1, (dur - t) / 0.15)
    return (body + tine) * env


def kick():
    t = t_(0.4)
    f = 48 + 70 * np.exp(-t * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 8) * np.minimum(1, t / 0.002)


def snare():
    t = t_(0.3)
    n = rng.standard_normal(len(t))
    n = lowpass(n, 5000) - lowpass(n, 900)
    body = np.sin(2 * np.pi * 185 * t) * np.exp(-t * 25)
    return (n * np.exp(-t * 16) * 1.6 + body * 0.6)


def shaker():
    t = t_(0.08)
    n = rng.standard_normal(len(t))
    n = n - lowpass(n, 6000)
    return n * np.sin(np.pi * t / 0.08) ** 2


def sub(freq, dur):
    t = t_(dur)
    s = np.tanh(1.3 * np.sin(2 * np.pi * freq * t))
    return s * np.minimum(1, t / 0.02) * np.minimum(1, (dur - t) / 0.08)


def bellnote(freq, dur=1.4):
    t = t_(dur)
    return (np.sin(2 * np.pi * freq * t) + 0.2 * np.sin(2 * np.pi * freq * 3 * t) * np.exp(-t * 6)) \
        * np.exp(-t * 2.8) * np.minimum(1, t / 0.005)


bars = int(np.ceil(LENGTH / BAR))
# Seyrek melodi (D majör pentatonik), çubuk içi vuruş ve nota.
MELODY = {2: [(0, 78), (1.5, 81), (3, 83)], 3: [(0.5, 81), (2, 78)],
          4: [(0, 76), (1.5, 78), (3, 81)], 5: [(0.5, 83), (2, 81), (3, 78)],
          6: [(0, 78), (1.5, 81), (3, 86)], 7: [(0.5, 83), (2, 81)],
          8: [(0, 76), (1.5, 78), (3, 81)], 9: [(0.5, 78), (2, 76)]}

for b in range(bars):
    notes, root = CHORDS[b % 4]
    t0 = b * BAR
    last = b == bars - 1
    # Akor: ilk vuruşta tam, üçüncü vuruş "ve"sinde hafif tekrar.
    for j, n in enumerate(notes):
        strum = j * 0.012
        e = epiano(midi(n), BAR + 0.4 if not last else 3.0)
        add(keys_l, t0 + strum, e, 0.22 * (1.1 - j * 0.1))
        add(keys_r, t0 + strum + 0.004, e, 0.22 * (0.8 + j * 0.1))
        if not last:
            e2 = epiano(midi(n), BEAT * 1.4)
            add(keys_l, t0 + BEAT * 2.5 + strum, e2, 0.09)
            add(keys_r, t0 + BEAT * 2.5 + strum, e2, 0.11)
    if not last:
        add(L, t0, sub(midi(root + 12), BEAT * 2.4), 0.2)
        add(R, t0, sub(midi(root + 12), BEAT * 2.4), 0.2)
        add(L, t0 + BEAT * 2.5, sub(midi(root + 12), BEAT * 1.4), 0.16)
        add(R, t0 + BEAT * 2.5, sub(midi(root + 12), BEAT * 1.4), 0.16)
    drums = 1 <= b < bars - 1
    if drums:
        for q in (0, 2.5):
            add(L, t0 + q * BEAT, kick(), 0.5)
            add(R, t0 + q * BEAT, kick(), 0.5)
            s = int((t0 + q * BEAT) * SR)
            d = np.linspace(0.55, 1, int(0.3 * SR))
            duck[s:s + len(d)] = np.minimum(duck[s:s + len(d)], d[: max(0, min(len(d), N - s))])
        for q in (1, 3):
            add(L, t0 + q * BEAT, snare(), 0.13)
            add(R, t0 + q * BEAT, snare(), 0.13)
        for e8 in range(8):
            swing = 0.06 * BEAT if e8 % 2 else 0
            g = 0.05 if e8 % 2 else 0.03
            add(L, t0 + e8 * BEAT / 2 + swing, shaker(), g * 0.8)
            add(R, t0 + e8 * BEAT / 2 + swing, shaker(), g * 1.2)
    for beat, n in MELODY.get(b, []):
        bn = bellnote(midi(n))
        add(L, t0 + beat * BEAT, bn, 0.06)
        add(R, t0 + beat * BEAT, bn, 0.08)

keys_l = lowpass(keys_l * duck, 3200)
keys_r = lowpass(keys_r * duck, 3200)
mix_l = reverb(L + keys_l, 0.28, 1.3)
mix_r = reverb(R + keys_r, 0.28, 1.35)
music = np.stack([mix_l, mix_r], axis=1)
# Hafif plak cızırtısı.
crackle = np.zeros(N)
pos = rng.integers(0, N, 900)
crackle[pos] = rng.standard_normal(900) * 0.4
crackle = lowpass(crackle, 4000)
music += np.stack([crackle, np.roll(crackle, 300)], axis=1) * 0.08
tt = np.arange(N) / SR
fade = np.minimum(1, tt / 0.3) * np.clip((LENGTH - tt) / 2.0, 0, 1)
music *= fade[:, None]
write('music.wav', music, 0.85)

# ================================================================ efektler


def marimba(freq, dur=0.9):
    t = t_(dur)
    s = np.sin(2 * np.pi * freq * t) * np.exp(-t * 5) + 0.35 * np.sin(2 * np.pi * freq * 3.93 * t) * np.exp(-t * 22)
    return s * np.minimum(1, t / 0.002)


# Geçiş notaları: her özellik bir üst nota (D majör pentatonik).
for i, n in enumerate([74, 76, 78, 81, 83, 86, 88]):
    s = marimba(midi(n)) + 0.5 * marimba(midi(n - 12))
    write(f'note{i + 1}.wav', reverb(s, 0.25), 0.5)

# Kart kaydırma: yumuşak, perdeli bir "süzülme" (gürültü yok).
t = t_(0.28)
f = 520 + 380 * (t / 0.28) ** 0.7
sw = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / 0.28) ** 2
write('slide.wav', reverb(lowpass(sw, 2500), 0.3), 0.35)

# Dokunma: yumuşak "tok".
t = t_(0.08)
tap = np.sin(2 * np.pi * 820 * t) * np.exp(-t * 70) + 0.5 * np.sin(2 * np.pi * 1640 * t) * np.exp(-t * 120)
write('tap.wav', tap * np.minimum(1, t / 0.001), 0.5)

t = t_(0.06)
key = np.sin(2 * np.pi * 1100 * t) * np.exp(-t * 110) + 0.3 * lowpass(rng.standard_normal(len(t)), 3000) * np.exp(-t * 300)
write('key.wav', key, 0.45)

t = t_(0.05)
write('tick.wav', np.sin(2 * np.pi * 2400 * t) * np.exp(-t * 150), 0.3)

t = t_(0.2)
f = 420 + 500 * (1 - np.exp(-t * 30))
write('pop.wav', np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 26) * np.minimum(1, t / 0.004), 0.5)


def bell(freq, dur):
    t = t_(dur)
    return (np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t * 8)) * np.exp(-t * 4.5)


ding = np.zeros(int(1.2 * SR))
b1 = bell(midi(86), 1.2)
b2 = bell(midi(93), 1.1)
ding[: len(b1)] += b1
o = int(0.09 * SR)
ding[o: o + len(b2)] += b2[: len(ding) - o]
write('ding.wav', reverb(ding, 0.2), 0.55)

t = t_(1.6)
sh = np.zeros_like(t)
for i, n in enumerate([74, 78, 81, 86, 90]):
    s0 = int(i * 0.07 * SR)
    b = bell(midi(n), 1.6 - i * 0.07)
    sh[s0: s0 + len(b)] += b[: len(sh) - s0] * 0.6
write('sparkle.wav', reverb(sh, 0.3), 0.5)
