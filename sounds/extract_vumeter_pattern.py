from pydub import AudioSegment
import numpy as np

# === CONFIGURATION ===
AUDIO_PATH = "son.ogg"             # Ton fichier audio source
SAMPLE_INTERVAL_MS = 100                 # Fenêtre de mesure (100ms = 10 mesures par seconde)
VUMETER_LEVELS = 10                      # Nombre de niveaux de vumètre
OUTPUT_FILE = "pattern.lua"              # Nom du fichier Lua à générer

# === CHARGEMENT DU FICHIER AUDIO ===
sound = AudioSegment.from_file(AUDIO_PATH)
rms_values = []

for i in range(0, len(sound), SAMPLE_INTERVAL_MS):
    slice = sound[i:i + SAMPLE_INTERVAL_MS]
    rms = slice.rms
    rms_values.append(rms)

# === NORMALISATION EN NIVEAUX DE 0 À 10 ===
max_rms = max(rms_values)
levels = [round((val / max_rms) * VUMETER_LEVELS) for val in rms_values]

# === CLAMP POUR ÉVITER > 10 ===
levels = [min(l, VUMETER_LEVELS) for l in levels]

# === EXPORT EN LUA ===
with open(OUTPUT_FILE, "w") as f:
    f.write("local pattern = {\n")
    for l in levels:
        f.write(f"  {l},\n")
    f.write("}\n\nreturn pattern\n")

print(f"[OK] Pattern généré ({len(levels)} valeurs) → {OUTPUT_FILE}")

