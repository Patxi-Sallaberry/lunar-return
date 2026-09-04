#!/usr/bin/env bash
# Assemble the portfolio reel from the individual clips.
#
# MATLAB already tries to do this from viz/build_showreel.m. This script is
# the standalone path: it is what you run if MATLAB could not reach ffmpeg,
# or if you re-cut the clips by hand.
#
#   ./tools/concat_showreel.sh
#
# Requires ffmpeg with libx264 on PATH.

set -euo pipefail

DIR="$(cd "$(dirname "$0")/../results/video/clips" && pwd)"
OUT="$(cd "$(dirname "$0")/../results/video" && pwd)"
FIG="$(cd "$(dirname "$0")/../results/figures" && pwd)"
LIST="$(mktemp)"
trap 'rm -f "$LIST"' EXIT

for f in 01_title 02_hohmann 03_proximity 04_perturbations 05_cr3bp 06_arm 07_endcard; do
  if [ -f "${DIR}/${f}.mp4" ]; then
    echo "file '${DIR}/${f}.mp4'" >> "$LIST"
  else
    echo "warning: ${f}.mp4 missing, skipping" >&2
  fi
done

ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart \
  "$OUT/showreel.mp4"

ffmpeg -y -loglevel error -i "$OUT/showreel.mp4" \
  -vf "scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart \
  "$OUT/showreel_square.mp4"

# README-sized GIFs, palette-optimised.
for f in 02_hohmann 03_proximity 06_arm; do
  [ -f "${DIR}/${f}.mp4" ] || continue
  ffmpeg -y -loglevel error -i "${DIR}/${f}.mp4" \
    -vf "fps=12,scale=800:-1:flags=lanczos,palettegen" "$OUT/frames/palette.png"
  ffmpeg -y -loglevel error -i "${DIR}/${f}.mp4" -i "$OUT/frames/palette.png" \
    -lavfi "fps=12,scale=800:-1:flags=lanczos [x]; [x][1:v] paletteuse" \
    "$FIG/${f}.gif"
done

echo "showreel.mp4 and showreel_square.mp4 written to $OUT"
