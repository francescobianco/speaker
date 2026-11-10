#!/usr/bin/env bash
# Disattiva "voce": toglie comandi, hook e regola del sunto. Con --piper rimuove anche Piper.
set -euo pipefail

BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/voce"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/voce"
CLAUDE_DIR="$HOME/.claude"

for f in "$BIN/voce" "$BIN/voce-stop" "$SHARE/pronuncia.tsv" "$SHARE/attacco.wav"; do
  [ -L "$f" ] && rm -f "$f"
done
rm -f "$CONF_DIR/voce.conf"
rmdir "$SHARE" "$CONF_DIR" 2>/dev/null || true

S="$CLAUDE_DIR/settings.json"
if [ -s "$S" ]; then
  tmp="$(mktemp)"
  jq '
    def clean: map(.hooks |= map(select((.command // "") | test("/voce(-stop)?( |$)") | not)))
             | map(select(.hooks | length > 0));
    if .hooks then
      .hooks |= (with_entries(.value |= clean) | with_entries(select(.value | length > 0)))
      | if (.hooks | length) == 0 then del(.hooks) else . end
    else . end
  ' "$S" > "$tmp"
  cat "$tmp" > "$S"
  rm -f "$tmp"
fi

C="$CLAUDE_DIR/CLAUDE.md"
if [ -f "$C" ]; then
  perl -0pi -e 's/\n*<!-- voce:start -->.*?<!-- voce:end -->\n*/\n/s' "$C"
  [ -n "$(tr -d '[:space:]' < "$C")" ] || rm -f "$C"
fi

if [ "${1:-}" = "--piper" ]; then
  rm -rf "$HOME/.local/share/piper"
fi
echo "Voce disattivata."
