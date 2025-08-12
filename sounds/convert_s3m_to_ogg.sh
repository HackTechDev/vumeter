#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<EOF
Usage: $(basename "$0") [fichiers.s3m ...]
Si aucun fichier n'est passé, convertit tous les *.s3m du dossier courant.

Dépendances (au moins l'une des options) :
  - Option A (recommandée) : ffmpeg (avec prise en charge libopenmpt)
  - Option B : openmpt123 et oggenc (vorbis-tools)
EOF
}

# Aide
[[ ${1:-} == "-h" || ${1:-} == "--help" ]] && { show_help; exit 0; }

have_ffmpeg=false
have_pipe=false
command -v ffmpeg >/dev/null 2>&1 && have_ffmpeg=true
if command -v openmpt123 >/dev/null 2>&1 && command -v oggenc >/dev/null 2>&1; then
  have_pipe=true
fi

if ! $have_ffmpeg && ! $have_pipe; then
  echo "Erreur: ni ffmpeg ni (openmpt123+oggenc) ne sont installés." >&2
  echo "Installez par ex. : sudo apt install ffmpeg   # Debian/Ubuntu" >&2
  echo "ou : sudo dnf install ffmpeg                   # Fedora" >&2
  echo "Alternative : sudo apt install openmpt123 vorbis-tools" >&2
  exit 1
fi

convert_one() {
  local in="$1"
  [[ -f "$in" ]] || { echo "Ignore: $in n'est pas un fichier"; return; }
  local base="${in%.*}"
  local out="${base}.ogg"

  echo "→ Conversion: $in → $out"

  if $have_ffmpeg; then
    # Qualité Vorbis ~160 kbps (q=5). Ajustez -q:a de 0 à 10.
    ffmpeg -hide_banner -loglevel error -y \
      -i "$in" -vn -c:a libvorbis -q:a 5 \
      -metadata title="$(basename "$base")" \
      "$out"
  else
    # Rendu PCM via openmpt123, encodage Vorbis via oggenc (qualité q=5)
    openmpt123 -q -o - "$in" | oggenc -Q -q 5 -o "$out" -
  fi
}

shopt -s nullglob
files=("$@")
if [ ${#files[@]} -eq 0 ]; then
  files=( *.s3m *.S3M )
fi

if [ ${#files[@]} -eq 0 ]; then
  echo "Aucun fichier .s3m trouvé. Utilisez -h pour l'aide." >&2
  exit 1
fi

for f in "${files[@]}"; do
  convert_one "$f"
done

echo "Terminé."

