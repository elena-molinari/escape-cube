const express = require('express');
const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);
const { Client } = require('node-osc');

// --- OSC CONFIG ---
const IP = '127.0.0.1';    // The IP address of the computer running TouchDesigner
const PORT_TD = 1000;      // The OSC In port in TouchDesigner
const PORT_SC = 57120;     //  The OSC In port in SuperCollider
const clientTD = new Client(IP, PORT_TD);
const clientSC = new Client(IP, PORT_SC);

app.use(express.static('public'));

io.on('connection', (socket) => {
    console.log('Tablet connesso alla Web App!');

    // Listen for selections sent from the user interface
    socket.on('scelta_utente', (data) => {
        
        //--- SYSTEM CONTROLS (PLAY/STOP) ---
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
        // --- STANDARD AUDIO/VIDEO OPTIONS ---
        else {
            // 1. Send to TouchDesigner (for text-based visuals)
            const oscAddress = '/kiosk/' + data.step;
            console.log(`Invio OSC a TD: ${oscAddress} -> ${data.value}`);
            clientTD.send(oscAddress, data.value);

            // 2. Send to SuperCollider (placing the selection in the “waiting room”)
            console.log(`Invio OSC a SC (In attesa): /sc/choice -> ${data.value}`);
            clientSC.send('/sc/choice', data.value);
        }
    });
});

// Start the server on port 3000 ( 0.0.0.0 for access the local network)
http.listen(3000, '0.0.0.0', () => {
    console.log('SERVER KIOSK ATTIVO!');
    console.log('Apri il browser su PC a: http://localhost:3000');
    console.log('Apri da Tablet digitando l\'IP del PC, es: http://192.168.1.X:3000');
});
