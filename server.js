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

// ... (tutto l'inizio del tuo codice va benissimo) ...

io.on('connection', (socket) => {
    console.log('Tablet connesso alla Web App!');

    // Ascolta le scelte inviate dall'interfaccia utente
    socket.on('scelta_utente', (data) => {
        // Formatta l'indirizzo OSC, es: /kiosk/mood -> relax
        const oscAddress = '/kiosk/' + data.step;
        
        console.log(`Invio OSC a TD: ${oscAddress} -> ${data.value}`);
        // Invia il messaggio testuale a TouchDesigner
        clientTD.send(oscAddress, data.value);

        // Se il dato in arrivo è la macro-scelta dell'ambiente, mandalo anche a SC!
        // (Assicurati che 'mood' sia il nome dello step che hai usato nel file HTML per Mare, Montagna ecc.)
        if (data.step === 'mood') {
            console.log(`Invio OSC a SC: /kiosk/macro -> ${data.value}`);
            clientSC.send('/kiosk/macro', data.value);
        }
    });
});

// Avvio del server sulla porta 3000
http.listen(3000, '0.0.0.0', () => {
    console.log('SERVER KIOSK ATTIVO!');
    console.log('Apri il browser su PC a: http://localhost:3000');
    console.log('Apri da Tablet digitando l\'IP del PC, es: http://192.168.1.X:3000');
});
