const express = require('express');
const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);
const { Client } = require('node-osc');

// --- CONFIGURAZIONE OSC ---
const IP = '127.0.0.1'; // L'IP del computer dove gira TouchDesigner
const PORT_TD = 1000;      // La porta OSC In di TouchDesigner
const PORT_SC = 57120;     // La porta OSC In di SuperCollider
const clientTD = new Client(IP, PORT_TD);
const clientSC = new Client(IP, PORT_SC);

// Diciamo al server di rendere pubblica la cartella 'public'
app.use(express.static('public'));

io.on('connection', (socket) => {
    console.log('Tablet connesso alla Web App!');

    // Ascolta le scelte inviate dall'interfaccia utente
    socket.on('scelta_utente', (data) => {
        
        // --- BIVIO 1: COMANDI DI SISTEMA (PLAY/STOP) ---
        if (data.step === 'command') {
            if (data.value === 'play') {
                console.log("Comando a SC: PLAY");
                clientSC.send('/sc/play', 1);
            } 
            else if (data.value === 'stop') {
                console.log("Comando a SC: STOP");
                clientSC.send('/sc/stop', 1);
            }
        } 
        // --- BIVIO 2: SCELTE AUDIO/VIDEO NORMALI ---
        else {
            // 1. Invia a TouchDesigner (per i visual testuali)
            const oscAddress = '/kiosk/' + data.step;
            console.log(`Invio OSC a TD: ${oscAddress} -> ${data.value}`);
            clientTD.send(oscAddress, data.value);

            // 2. Invia a SuperCollider (mettendo la scelta nella "sala d'attesa")
            console.log(`Invio OSC a SC (In attesa): /sc/choice -> ${data.value}`);
            clientSC.send('/sc/choice', data.value);
        }
    });
});

// Avvio del server sulla porta 3000 (0.0.0.0 permette l'accesso dalla rete locale)
http.listen(3000, '0.0.0.0', () => {
    console.log('SERVER KIOSK ATTIVO!');
    console.log('Apri il browser su PC a: http://localhost:3000');
    console.log('Apri da Tablet digitando l\'IP del PC, es: http://192.168.1.X:3000');
});