(
var myPath, rootPath;
if(s.serverRunning.not) { s.boot };

s.freeAll;
Buffer.freeAll;


// --- 1. LIBRERIA AUDIO ---
~buffers = Dictionary.new;

if(thisProcess.nowExecutingPath.notNil) {
    myPath = thisProcess.nowExecutingPath.dirname;

    // Tutti i tuoi file audio mappati con il percorso corretto (senza backtracking)
    ~buffers.put('relax', Buffer.read(s, myPath +/+ "Sounds/Relax/relax.wav"));
    // ~buffers.put('mountain', Buffer.read(s, myPath +/+ "Sounds/Relax/mountain.wav"));
    ~buffers.put('sea', Buffer.read(s, myPath +/+ "Sounds/Relax/sea.wav"));
    ~buffers.put('forest', Buffer.read(s, myPath +/+ "Sounds/Relax/forest.wav"));
    // ~buffers.put('stars', Buffer.read(s, myPath +/+ "Sounds/Relax/stars.wav"));
    ~buffers.put('cloud', Buffer.read(s, myPath +/+ "Sounds/Relax/cloud.wav"));
    ~buffers.put('wave', Buffer.read(s, myPath +/+ "Sounds/Relax/wave.wav"));
    ~buffers.put('lavender', Buffer.read(s, myPath +/+ "Sounds/Relax/lavender.wav"));
    ~buffers.put('rain', Buffer.read(s, myPath +/+ "Sounds/Relax/rain.wav"));

    ~buffers.put('cerchio', Buffer.read(s, myPath +/+ "Sounds/Inspirational/cerchio.wav"));
    ~buffers.put('fluido', Buffer.read(s, myPath +/+ "Sounds/Inspirational/fluido.wav"));
    ~buffers.put('alto', Buffer.read(s, myPath +/+ "Sounds/Inspirational/alto.wav"));
    ~buffers.put('rigido', Buffer.read(s, myPath +/+ "Sounds/Inspirational/rigido.wav"));
    ~buffers.put('caldo', Buffer.read(s, myPath +/+ "Sounds/Inspirational/caldo.wav"));
    ~buffers.put('basso', Buffer.read(s, myPath +/+ "Sounds/Inspirational/basso.wav"));
    ~buffers.put('freddo', Buffer.read(s, myPath +/+ "Sounds/Inspirational/freddo.wav"));
    ~buffers.put('linee', Buffer.read(s, myPath +/+ "Sounds/Inspirational/linee.wav"));
} {
    "ATTENZIONE: Salva il file per i percorsi!".postln;
};

~activeLayers = Dictionary.new; // I synth che stanno suonando in questo momento
~pendingChoices = Set.new;     // La "sala d'attesa" per le scelte della sessione attuale

// --- 2. MOTORINO AUDIO SEMPLIFICATO (Solo player puro + dissolvenze) ---
SynthDef(\pureLayerPlayer, {
    arg out=0, bufnum, gate=1, fadeTime=4, amp=0.5;
    var sig, env;

    // Inviluppo ASR: gestisce il Fade-In (quando nasce) e il Fade-Out (quando gate diventa 0)
    env = EnvGen.kr(Env.asr(fadeTime, 1, fadeTime), gate, doneAction: 2);

    // Lettura stereo standard alla velocità nativa del file, in loop continuo
    sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 1);

    // Applichiamo l'inviluppo e il volume
    sig = sig * env * amp;

    Out.ar(out, sig);
}).add;

// --- 3. GESTIONE MESSAGGI OSC ---

// 1. RICEVE LE SCELTE (Le mette in coda man mano che l'utente clicca sul tablet)
OSCdef(\kioskChoiceListener, { |msg|
    var choice = msg[1].asSymbol;
    ("SC memorizza la scelta: " ++ choice).postln;
    ~pendingChoices.add(choice); // Il Set evita automaticamente i duplicati
}, '/sc/choice');

// 2. COMANDO PLAY (Scatta alla fine del Kiosk e avvia tutti i layer salvati insieme)
OSCdef(\kioskPlayListener, { |msg|
    "▶ COMANDO PLAY RICEVUTO! Avvio la scena sonora...".postln;

    ~pendingChoices.do({ |choice|
        if(~buffers.includesKey(choice)) {
            // Se la traccia non è già attiva, la facciamo partire
            if(~activeLayers[choice].isNil) {
                ~activeLayers.put(choice,
                    Synth(\pureLayerPlayer, [
                        \bufnum, ~buffers[choice],
                        \fadeTime, 4, // 4 secondi di dissolvenza incrociata in entrata
                        \amp, 0.5     // Impostato a 0.5 per evitare che 4-5 tracce insieme vadano in distorsione (clipping)
                    ])
                );
            }
        };
    });
}, '/sc/play');

// 3. COMANDO STOP (Scatta quando si preme Home: fa il fade-out di tutto e resetta)
OSCdef(\kioskStopListener, { |msg|
    "⏹ COMANDO STOP RICEVUTO! Fade-out in corso...".postln;

    // Invia il comando di chiusura (gate=0) a tutte le tracce attive
    ~activeLayers.keysValuesDo({ |key, synth|
        synth.set(\gate, 0);
    });

    // Pulisce i registri per prepararsi alla sessione dell'utente successivo
    ~activeLayers.clear;
    ~pendingChoices.clear;
}, '/sc/stop');

"--- MOTORE MULTI-TRACK AUDIO PURO ATTIVO (IN ATTESA DI PLAY) ---".postln;
)