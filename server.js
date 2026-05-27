const express = require('express');
const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);
const { Client } = require('node-osc');

// --- CONFIGURAZIONE OSC ---
const IP_TD = '127.0.0.1'; // L'IP del computer dove gira TouchDesigner
const PORT_TD = 9999;      // La porta OSC In di TouchDesigner
const clientTD = new Client(IP_TD, PORT_TD);

// Diciamo al server di rendere pubblica la cartella 'public'
app.use(express.static('public'));

io.on('connection', (socket) => {
    console.log('Tablet connesso alla Web App!');

    // Ascolta le scelte inviate dall'interfaccia utente
    socket.on('scelta_utente', (data) => {
        // Formatta l'indirizzo OSC, es: /kiosk/mood -> relax
        const oscAddress = '/kiosk/' + data.step;
        
        console.log(`Invio OSC a TD: ${oscAddress} -> ${data.value}`);
        
        // Invia il messaggio a TouchDesigner
        clientTD.send(oscAddress, data.value);
    });
});

// Avvio del server sulla porta 3000 (0.0.0.0 permette l'accesso dalla rete locale)
http.listen(3000, '0.0.0.0', () => {
    console.log('SERVER KIOSK ATTIVO!');
    console.log('Apri il browser su PC a: http://localhost:3000');
    console.log('Apri da Tablet digitando l\'IP del PC, es: http://192.168.1.X:3000');
});