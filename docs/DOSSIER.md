# Dossier: uno speaker come voce di Claude

Diario dell'esperimento del 10 novembre 2026. L'obiettivo era dare a Claude Code un canale audio dedicato, usando un vecchio speaker Bluetooth chiamato Q3 e consumando meno risorse possibile.

## Risultato

Claude scrive il dettaglio a schermo e pronuncia un sunto di poche parole. La sintesi di una frase richiede meno di un quarto di secondo di calcolo su CPU, e la riproduzione aggiunge qualche secondo di attacco. Il doppio canale si è rivelato il vero valore: la voce dice com'è andata e se serve un intervento, lo schermo conserva tutto il resto.

## Lo speaker

- Espone A2DP (ascolto di qualità) e vivavoce HFP con solo codec CVSD, 8 kHz mono. Si presenta anche come dispositivo di input.
- L'audio va inviato direttamente alla sua uscita, senza cambiare l'uscita predefinita del computer: così la musica continua altrove.
- Il primo test era inudibile perché la sorgente `sine` di ffmpeg ha un'ampiezza predefinita di 1/8. Serve un guadagno esplicito.

## Il microfono

La prova in vivavoce ha registrato quasi solo un ronzio costante a circa 54 Hz, molto forte, con il parlato non distinguibile. Compatibile con un ingresso scollegato o assente, ma non si è potuto escludere un problema del dongle Bluetooth (CSR `0a12:0001`). Il microfono del Q3 è stato scartato: per un eventuale ascolto meglio un microfono USB e una trascrizione locale, lasciando lo speaker sempre in A2DP.

## La voce

| Motore o voce | Esito |
|---|---|
| Piper, `it_IT-paola-medium` (femminile) | Scelta |
| Piper, `it_IT-riccardo-x_low` (maschile) | Timbro non gradito, 16 kHz |
| Kokoro, Chatterbox, XTTS | Non provati, scartati per evitare consumi |
| ElevenLabs, Azure, Google | Non provati, il testo uscirebbe dal PC |

Piper non ha controlli per le emozioni: solo la punteggiatura cambia l'intonazione. Una versione "urlata" si può solo simulare con velocità, tono e compressione.

## Regolazioni trovate a orecchio

- **Inizio troncato.** Molti speaker tengono l'amplificatore spento durante il silenzio digitale. Si risolve con 2,5 secondi iniziali e un fruscio rosa quasi impercettibile (ampiezza 0,003).
- **Inizio impastato.** Il fruscio ora copre tutta la frase e la voce parte 150 ms dopo l'attacco.
- **Velocità.** Con `length_scale` 1,25 e pause di 0,35 secondi tra le frasi la voce è comoda da seguire.
- **Attacco.** Serve ad avvisare che arriva un messaggio. Una nota di kalimba sintetizzata è stata preferita a un tocco sul legno e a un doppio tocco, senza alcun beep elettronico.

## Pronuncia e doppie

Il testo diventa fonemi con espeak-ng, poi il modello li trasforma in audio. Per "coppia" i fonemi sono corretti (`kˈɔpːia`), ma il modello rende la doppia troppo corta. Misure indicative della pausa della p, su una prova singola:

| Testo | Fonemi | Pausa |
|---|---|---|
| copia | `kˈɔpia` | circa 20 ms |
| coppia | `kˈɔpːia` | circa 30 ms |
| còp-pia | `kˈɔppˈia` | circa 73 ms |
| còpp-pia | `kˈɔpːpˈia` | circa 99 ms, scelta |

Le grafie senza accento, come `cop-pia`, chiudono la "o": l'accento serve a mantenerla aperta.

## Livelli di intervento su Piper

1. **Parametri di lettura:** velocità, pause, regolarità della durata. Immediato.
2. **Dizionario di pronuncia:** `config/pronuncia.tsv`. Costa zero.
3. **Regole fonetiche di espeak-ng:** correzioni sistematiche da ricompilare, più delicate.
4. **Fine-tuning da un checkpoint:** servono registrazioni trascritte e una scheda grafica. Il checkpoint deve avere stessa qualità e frequenza del modello da ottenere, anche se di altra lingua. Per l'italiano, a novembre 2026 erano pubblici solo i checkpoint di "serena", media e alta qualità, quindi non si può rifinire paola: si otterrebbe una voce nuova.
5. **Addestramento da zero:** dataset grande e molto calcolo. Non conveniente per questi difetti.

Riferimenti: [guida all'addestramento](https://github.com/rhasspy/piper/blob/master/TRAINING.md) e [checkpoint](https://huggingface.co/datasets/rhasspy/piper-checkpoints/tree/main).

## Idee aperte

- Far parlare Claude solo dopo i lavori lunghi.
- Usare un tasto dello speaker per ripetere l'ultima frase, se i tasti inviano eventi.
- Parlare a Claude tramite microfono USB e trascrizione locale.
