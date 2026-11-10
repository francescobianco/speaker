#!/usr/bin/env bash
# Rigenera i suoni di attacco. Sono sintesi con una parte casuale: il risultato e' simile, non identico.
# Uso: tools/genera-attacchi.sh [CARTELLA]   (default: assets/ della repo)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$REPO/assets}"
mkdir -p "$OUT"

TAP="(1-exp(-t*900))*(0.6*exp(-t*38)*sin(2*PI*310*t)+0.35*exp(-t*55)*sin(2*PI*745*t+0.6)+0.15*exp(-t*90)*sin(2*PI*1430*t+1.1)+0.3*exp(-t*400)*(2*random(0)-1))"
KAL="(1-exp(-t*1500))*(0.55*exp(-t*7)*sin(2*PI*587*t)+0.18*exp(-t*13)*sin(2*PI*1174*t+0.4)+0.07*exp(-t*28)*sin(2*PI*3180*t+0.9)+0.1*exp(-t*300)*(2*random(0)-1))"
ROOM="lowpass=f=3200,aecho=0.85:0.5:23|41:0.16|0.09"
FMT="aformat=sample_rates=48000:channel_layouts=stereo"

ffmpeg -y -loglevel error -f lavfi -i "aevalsrc='$TAP':s=48000:d=0.4" -af "$ROOM,$FMT" "$OUT/raw_legno.wav"
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc='$TAP':s=48000:d=0.4" -f lavfi -i "aevalsrc='$TAP':s=48000:d=0.4" \
  -filter_complex "[1]volume=0.62,adelay=210:all=1[b];[0][b]amix=inputs=2:duration=longest:normalize=0,$ROOM,$FMT" "$OUT/raw_doppio.wav"
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc='$KAL':s=48000:d=1.0" \
  -af "highpass=f=120,lowpass=f=4500,aecho=0.85:0.45:31:0.12,$FMT" "$OUT/raw_kalimba.wav"

for n in legno doppio kalimba; do
  raw="$OUT/raw_$n.wav"
  peak="$(ffmpeg -hide_banner -i "$raw" -af volumedetect -f null - 2>&1 | grep -oP 'max_volume: \K[-0-9.]+')"
  gain="$(LC_ALL=C awk -v p="$peak" 'BEGIN{printf "%.2f", -10 - p}')"
  dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$raw")"
  fade="$(LC_ALL=C awk -v d="$dur" 'BEGIN{printf "%.3f", d - 0.06}')"
  ffmpeg -y -loglevel error -i "$raw" -af "volume=${gain}dB,afade=t=out:st=$fade:d=0.06,apad=pad_dur=0.3" "$OUT/$n.wav"
  rm -f "$raw"
done
ls -l "$OUT"
