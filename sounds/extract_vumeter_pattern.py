from pydub import AudioSegment
import numpy as np

# === CONFIGURATION ===
AUDIO_PATH = "son.ogg"
SAMPLE_INTERVAL_MS = 100  # 100ms = 10x par seconde
VUMETER_LEVELS = 10        # nombre de niveaux dans le vu-mètre
LUA_FILE_PATH = "pattern.lua"

# === LECTURE DU FICHIER ===
sound = AudioSegment.from_file(AUDIO_PATH)
rms_values = []

for i in range(0, len(sound), SAMPLE_INTERVAL_MS):
    slice = sound[i:i+SAMPLE_INTERVAL_MS]
    rms = slice.rms
    rms_values.append(rms)

# === NORMALISATION ===
max_rms = max(rms_values)
levels = [round((val / max_rms) * (VUMETER_LEVELS - 1)) for val in rms_values]

# === EXPORT LUA ===
with open(LUA_FILE_PATH, "w") as f:
    f.write("local pattern = {\n")
    for i, val in enumerate(levels):
        f.write(f"  {val},\n")
    f.write("}\n\nreturn pattern\n")

print(f"Pattern écrit dans {LUA_FILE_PATH} (total: {len(levels)} valeurs)")

