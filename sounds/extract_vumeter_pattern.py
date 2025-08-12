from pydub import AudioSegment
import numpy as np
from scipy.signal import butter, lfilter
import os

# === CONFIGURATION ===
AUDIO_PATH = "son.ogg"
OUTPUT_LUA = "pattern.lua"
SAMPLE_INTERVAL_MS = 100
VUMETER_LEVELS = 10
NUM_BANDS = 10  # Nombre de colonnes
FREQ_RANGES = [
    (20, 60), (60, 120), (120, 250), (250, 500),
    (500, 1000), (1000, 2000), (2000, 4000),
    (4000, 6000), (6000, 10000), (10000, 16000)
]

# === FONCTIONS UTILITAIRES ===
def butter_bandpass(lowcut, highcut, fs, order=3):
    nyq = 0.5 * fs
    low = max(lowcut / nyq, 1e-5)
    high = min(highcut / nyq, 0.99999)
    b, a = butter(order, [low, high], btype='band')
    return b, a

def bandpass_filter(data, lowcut, highcut, fs):
    b, a = butter_bandpass(lowcut, highcut, fs)
    return lfilter(b, a, data)

# === CHARGEMENT ET TRAITEMENT DU SON ===
audio = AudioSegment.from_file(AUDIO_PATH).set_channels(1)
fs = audio.frame_rate
samples = np.array(audio.get_array_of_samples()).astype(np.float32)

samples_per_chunk = int(fs * SAMPLE_INTERVAL_MS / 1000)
total_chunks = len(samples) // samples_per_chunk

# === EXTRACTION DES 10 BANDES DE FREQUENCES ===
patterns = [[] for _ in range(NUM_BANDS)]
max_rms_per_band = np.zeros(NUM_BANDS)

for chunk_idx in range(total_chunks):
    chunk = samples[chunk_idx * samples_per_chunk : (chunk_idx + 1) * samples_per_chunk]
    if len(chunk) < samples_per_chunk:
        break
    for band_idx, (low, high) in enumerate(FREQ_RANGES):
        filtered = bandpass_filter(chunk, low, high, fs)
        rms = np.sqrt(np.mean(filtered ** 2))
        patterns[band_idx].append(rms)
        if rms > max_rms_per_band[band_idx]:
            max_rms_per_band[band_idx] = rms

# === NORMALISATION ET CONVERSION EN NIVEAUX DE 0 À 10 ===
normalized_patterns = []
for band_idx, band_values in enumerate(patterns):
    max_rms = max_rms_per_band[band_idx] or 1
    levels = [min(VUMETER_LEVELS, round((v / max_rms) * VUMETER_LEVELS)) for v in band_values]
    normalized_patterns.append(levels)

# === ÉCRITURE DU FICHIER pattern.lua ===
with open(OUTPUT_LUA, "w") as f:
    f.write("local patterns = {\n")
    for i, pat in enumerate(normalized_patterns, 1):
        f.write(f"  [{i}] = {{\n")
        for v in pat:
            f.write(f"    {v},\n")
        f.write("  },\n")
    f.write("}\n\nreturn patterns\n")

print(f"[OK] pattern.lua généré avec {NUM_BANDS} colonnes et {total_chunks} étapes.")

