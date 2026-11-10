# speaker

Un vecchio speaker Bluetooth diventa la voce di Claude Code. A fine lavoro senti un sunto di poche parole, mentre a schermo restano i dettagli. La sintesi gira tutta in locale con [Piper](https://github.com/rhasspy/piper), consuma pochissimo e la musica resta sull'uscita normale del computer.

Il racconto dell'esperimento, con prove, misure e scelte fatte, è in [docs/DOSSIER.md](docs/DOSSIER.md).

## Come funziona

1. Claude chiude ogni risposta con una riga che inizia con `🔊`.
2. L'hook `Stop` di Claude Code lancia `voce-stop`, che estrae quella riga. Se manca, dice «Ho finito».
3. `voce` applica il dizionario, sintetizza con Piper e suona sullo speaker: nota di kalimba, poi la frase.
4. Quando Claude aspetta un permesso, l'hook `Notification` dice «Mi serve una conferma».

## Attivazione globale su tutto il PC

Serve Linux x86_64 con PipeWire o PulseAudio, e lo speaker già associato via Bluetooth. Pacchetti Ubuntu necessari:

```bash
sudo apt install pulseaudio-utils ffmpeg jq curl perl util-linux bluez
```

Poi, dalla cartella della repo:

```bash
./install.sh          # speaker chiamato Q3
./install.sh "Nome"   # oppure un altro speaker
voce "ciao"           # prova
```

L'installazione scarica Piper e la voce italiana paola (circa 90 MB), collega i comandi in `~/.local/bin` e aggiunge hook e regola del sunto alle impostazioni globali di Claude Code, senza toccare il resto. La copia di sicurezza delle impostazioni è `~/.claude/settings.json.voce.bak`.

I comandi sono collegamenti ai file della repo: ogni modifica qui vale subito. Se sposti la cartella, rilancia `./install.sh`.

Se il Q3 non parla nella sessione aperta, apri `/hooks` una volta o riavvia Claude Code.

## Disattivazione

```bash
./uninstall.sh           # toglie comandi, hook e regola del sunto
./uninstall.sh --piper   # toglie anche Piper
```

## Personalizzare

**Pronuncia.** In `config/pronuncia.tsv`, una parola per riga: `parola<TAB>grafia da leggere`. Vale solo per la parola esatta. Per controllare la sostituzione:

```bash
VOCE_DRY=1 voce "Una coppia vincente"
```

Un accento forza la vocale, per esempio `àncora`. Un trattino rinforza una doppia, per esempio `còpp-pia`.

**Suono di attacco.** Sono disponibili `kalimba`, `legno` e `doppio`:

```bash
VOCE_ATTACCO=legno ./install.sh
```

**Regolazioni.** Variabili d'ambiente, oppure righe nel file `~/.config/voce/voce.conf`, nella forma `: "${VOCE_VOLUME:=70%}"`.

| Variabile | Default | Effetto |
|---|---|---|
| `VOCE_VOLUME` | `100%` | Volume dello speaker, impostato a ogni frase |
| `VOCE_LENGTH_SCALE` | `1.25` | Lentezza del parlato |
| `VOCE_SENTENCE_SILENCE` | `0.35` | Pausa tra le frasi, in secondi |
| `VOCE_LEAD_IN` | `0.3` | Secondi per svegliare lo speaker |
| `VOCE_SPEECH_DELAY` | `150` | Millisecondi tra attacco e voce |
| `VOCE_MODEL` | paola | Percorso di un altro modello Piper |

## Struttura

```
bin/        voce e voce-stop
assets/     suoni di attacco
config/     dizionario di pronuncia
claude/     regola del sunto per il CLAUDE.md globale
tools/      rigenerazione dei suoni
docs/       dossier dell'esperimento
```
