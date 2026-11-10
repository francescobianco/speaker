#!/usr/bin/env bash
# Attiva "voce" su tutto il PC: Piper, comandi, suoni, dizionario e integrazione con Claude Code.
# Uso: ./install.sh [NOME_SPEAKER]   (default: Q3, deve essere gia' associato via Bluetooth)
# Si puo' rilanciare: l'operazione e' idempotente.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPEAKER="${1:-Q3}"
ATTACCO="${VOCE_ATTACCO:-kalimba}"

BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/voce"
PIPER_DIR="$HOME/.local/share/piper"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/voce"
CLAUDE_DIR="$HOME/.claude"

PIPER_URL="https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz"
VOICE_URL="https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/it/it_IT/paola/medium"
VOICE="it_IT-paola-medium"

die() { echo "ERRORE: $*" >&2; exit 1; }

link() { # sorgente destinazione: conserva un eventuale file vero come .bak
  if [ -e "$2" ] && [ ! -L "$2" ]; then mv "$2" "$2.bak"; fi
  ln -sfn "$1" "$2"
}

for cmd in pactl paplay ffmpeg jq curl perl flock bluetoothctl tar; do
  command -v "$cmd" >/dev/null || die "manca il comando: $cmd"
done
[ "$(uname -m)" = "x86_64" ] || die "il pacchetto Piper usato qui e' solo per x86_64"

# Speaker: l'indirizzo resta solo sul PC, in voce.conf, mai nella repo.
sink="${VOCE_SINK:-}"
if [ -z "$sink" ]; then
  mac="$(bluetoothctl devices | awk -v n="$SPEAKER" '{m=$2; $1=$2=""; sub(/^ +/,""); if ($0==n) {print m; exit}}')"
  [ -n "$mac" ] || die "speaker '$SPEAKER' non trovato: associalo prima via Bluetooth"
  sink="bluez_output.${mac//:/_}.1"
fi
mkdir -p "$CONF_DIR"
printf ': "${VOCE_SINK:=%s}"\n' "$sink" > "$CONF_DIR/voce.conf"
echo "Speaker: $SPEAKER -> $sink"

# Piper e voce italiana.
mkdir -p "$PIPER_DIR/voices"
if [ ! -x "$PIPER_DIR/piper/piper" ]; then
  echo "Scarico Piper..."
  curl -fsSL "$PIPER_URL" | tar xz -C "$PIPER_DIR"
fi
for ext in onnx onnx.json; do
  f="$PIPER_DIR/voices/$VOICE.$ext"
  if [ ! -s "$f" ]; then
    echo "Scarico la voce $VOICE.$ext..."
    curl -fsSL -o "$f" "$VOICE_URL/$VOICE.$ext"
  fi
done

# Comandi e dati: collegamenti alla repo, che resta l'unica fonte.
mkdir -p "$BIN" "$SHARE"
chmod +x "$REPO/bin/voce" "$REPO/bin/voce-stop"
link "$REPO/bin/voce" "$BIN/voce"
link "$REPO/bin/voce-stop" "$BIN/voce-stop"
link "$REPO/config/pronuncia.tsv" "$SHARE/pronuncia.tsv"
[ -r "$REPO/assets/$ATTACCO.wav" ] || die "attacco inesistente: $ATTACCO"
link "$REPO/assets/$ATTACCO.wav" "$SHARE/attacco.wav"

# Hook di Claude Code, senza toccare il resto delle impostazioni.
mkdir -p "$CLAUDE_DIR"
S="$CLAUDE_DIR/settings.json"
[ -s "$S" ] || echo '{}' > "$S"
[ -e "$S.voce.bak" ] || cp "$S" "$S.voce.bak"
tmp="$(mktemp)"
jq --arg stop "$BIN/voce-stop" --arg note "$BIN/voce 'Mi serve una conferma.'" '
  def clean: map(.hooks |= map(select((.command // "") | test("/voce(-stop)?( |$)") | not)))
           | map(select(.hooks | length > 0));
  .hooks = (.hooks // {})
  | .hooks.Stop = (((.hooks.Stop // []) | clean)
      + [{hooks: [{type: "command", command: $stop, async: true}]}])
  | .hooks.Notification = (((.hooks.Notification // []) | clean)
      + [{matcher: "permission_prompt|elicitation_dialog",
          hooks: [{type: "command", command: $note, async: true}]}])
' "$S" > "$tmp"
cat "$tmp" > "$S"
rm -f "$tmp"

# Regola del sunto parlato nel CLAUDE.md globale.
C="$CLAUDE_DIR/CLAUDE.md"
touch "$C"
perl -0pi -e 's/\n*<!-- voce:start -->.*?<!-- voce:end -->\n*/\n/s' "$C"
[ -s "$C" ] && [ "$(tr -d '[:space:]' < "$C")" != "" ] && echo >> "$C" || : > "$C"
cat "$REPO/claude/CLAUDE-voce.md" >> "$C"

echo "Fatto. Prova con: voce \"ciao\""
case ":$PATH:" in *":$BIN:"*) ;; *) echo "Attenzione: $BIN non e' nel PATH." ;; esac
