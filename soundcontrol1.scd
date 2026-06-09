(
var myPath, rootPath;
if(s.serverRunning.not) { s.boot };

s.freeAll;
Buffer.freeAll;

// 1. I TUOI BUS PER I SENSORI (Rimangono invariati)
~bpmBus = Bus.control(s, 1);
~gsrBus = Bus.control(s, 1);

// 2. DIZIONARIO DEI BUFFER (La tua libreria audio)
~buffers = Dictionary.new;

if(thisProcess.nowExecutingPath.notNil) {
    myPath = thisProcess.nowExecutingPath.dirname;
    rootPath = myPath.dirname;

    // Carica QUI tutti i tuoi file audio e assegnali alla stringa esatta
    // che Node.js invia dal Kiosk (es. 'sea', 'mountain', 'choice_A')
    ~buffers.put('relax', Buffer.read(s, rootPath +/+ "Sounds/base_relax.wav"));
    ~buffers.put('sea', Buffer.read(s, rootPath +/+ "Sounds/onde_mare.wav"));
    ~buffers.put('choice_A', Buffer.read(s, rootPath +/+ "Sounds/gabbiani.wav"));
} {
    "ATTENZIONE: Salva il file per i percorsi!".postln;
};

~activeLayers = Dictionary.new; // I synth che stanno suonando
~pendingChoices = Set.new;     // La "sala d'attesa" per le scelte della sessione attuale

// SYNTHDEF (Rimane identico a prima, con gate e fadeTime)
SynthDef(\layerPlayer, {
    arg out=0, bufnum, inBpm, inGsr, gate=1, fadeTime=4, amp=1;
    var sig, env, rateVal, filterVal;

    env = EnvGen.kr(Env.asr(fadeTime, 1, fadeTime), gate, doneAction: 2);
    rateVal = In.kr(inBpm, 1).lag(0.5);
    filterVal = In.kr(inGsr, 1).lag(0.5);

    sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * rateVal, loop: 1);
    sig = RLPF.ar(sig, filterVal, 0.5);

    sig = sig * env * amp;
    Out.ar(out, sig);
}).add;

// 1. RICEVE LE SCELTE (Ma non le suona, le mette in attesa)
OSCdef(\kioskChoiceListener, { |msg|
    var choice = msg[1].asSymbol;
    ("SC memorizza la scelta: " ++ choice).postln;
    ~pendingChoices.add(choice); // Aggiunge alla lista d'attesa (Set evita i doppioni)
}, '/sc/choice');

// 2. COMANDO PLAY (Fa partire tutto insieme)
OSCdef(\kioskPlayListener, { |msg|
    "▶ COMANDO PLAY RICEVUTO! Avvio tutti i layer...".postln;

    ~pendingChoices.do({ |choice|
        if(~buffers.includesKey(choice)) {
            if(~activeLayers[choice].isNil) {
                ~activeLayers.put(choice,
                    Synth(\layerPlayer, [
                        \bufnum, ~buffers[choice],
                        \inBpm, ~bpmBus,
                        \inGsr, ~gsrBus,
                        \fadeTime, 4 // 4 secondi di dissolvenza in entrata
                    ])
                );
            }
        };
    });
}, '/sc/play');

// 3. COMANDO STOP (Fade-out generale e pulizia)
OSCdef(\kioskStopListener, { |msg|
    "⏹ COMANDO STOP RICEVUTO! Fade-out in corso...".postln;

    // Dice a tutti i synth attivi di abbassare il volume e spegnersi (gate = 0)
    ~activeLayers.keysValuesDo({ |key, synth|
        synth.set(\gate, 0);
    });

    // Svuota i dizionari per prepararsi al prossimo utente
    ~activeLayers.clear;
    ~pendingChoices.clear;
}, '/sc/stop');

"--- MOTORE MULTI-LAYER AVVIATO (IN ATTESA DI PLAY) ---".postln;