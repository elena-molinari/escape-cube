(
var myPath, rootPath;
if(s.serverRunning.not) { s.boot };

s.freeAll;
Buffer.freeAll;


// --- 1. AUDIO LIBRARY ---
~buffers = Dictionary.new;

if(thisProcess.nowExecutingPath.notNil) {
    myPath = thisProcess.nowExecutingPath.dirname;

    ~buffers.put('relax', Buffer.read(s, myPath +/+ "Sounds/Relax/relax.wav"));
    ~buffers.put('sea', Buffer.read(s, myPath +/+ "Sounds/Relax/sea.wav"));
    ~buffers.put('forest', Buffer.read(s, myPath +/+ "Sounds/Relax/forest.wav"));
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

~activeLayers = Dictionary.new; 
~pendingChoices = Set.new;     // "waiting room" for the selected audio

// --- 2. AUDIO ENGINE
SynthDef(\pureLayerPlayer, {
    arg out=0, bufnum, gate=1, fadeTime=4, amp=0.5;
    var sig, env;

    // ASR Envelope: controls the fade-in (when it starts) and the fade-out (when the gate goes to 0)
    env = EnvGen.kr(Env.asr(fadeTime, 1, fadeTime), gate, doneAction: 2);

    // Standard stereo playback at the file's native speed, in a continuous loop
    sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 1);

    // Let's apply the envelope and the volume
    sig = sig * env * amp;

    Out.ar(out, sig);
}).add;

// --- 3. OSC MANAGEMENT ---

OSCdef(\kioskChoiceListener, { |msg|
    var choice = msg[1].asSymbol;
    ("SC storing choice: " ++ choice).postln;
    ~pendingChoices.add(choice);
}, '/sc/choice');

OSCdef(\kioskPlayListener, { |msg|
    "Start Sound Scene...".postln;

    ~pendingChoices.do({ |choice|
        if(~buffers.includesKey(choice)) {
            if(~activeLayers[choice].isNil) {
                ~activeLayers.put(choice,
                    Synth(\pureLayerPlayer, [
                        \bufnum, ~buffers[choice],
                        \fadeTime, 4, 
                        \amp, 0.5  
                    ])
                );
            }
        };
    });
}, '/sc/play');

OSCdef(\kioskStopListener, { |msg|
    "Fade-out in progress...".postln;

    ~activeLayers.keysValuesDo({ |key, synth|
        synth.set(\gate, 0);
    });

    ~activeLayers.clear;
    ~pendingChoices.clear;
}, '/sc/stop');

"--- MULTI-TRACK AUDIO ACTIVE (WAITING FOR PLAY) ---".postln;
)
