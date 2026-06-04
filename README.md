# ESCAPE CUBE

# Escape Kiosk - Interfaccia Utente

Questa repository contiene l'applicazione web (modalità Kiosk) per l'installazione interattiva "Escape".
L'interfaccia permette agli utenti di personalizzare la propria esperienza (o scegliere un percorso rapido) e comunica con **TouchDesigner** in tempo reale inviando pacchetti **OSC**.

---

## 1. Prerequisiti
Per far funzionare il progetto sul tuo computer, devi avere installato **Node.js** (il motore che fa girare il server locale).
* Scarica e installa Node.js (versione LTS) da: [nodejs.org](https://nodejs.org/)
* *Nota per Windows: durante l'installazione, lascia le impostazioni predefinite e riavvia il PC al termine.*

---

## 2. Installazione e Avvio
La prima volta che scarichi questo progetto da GitHub, devi installare le librerie necessarie (Express, Socket.io, Node-OSC).

1. Apri la cartella del progetto con **Visual Studio Code**.
2. Apri il terminale integrato
3. Installa le dipendenze digitando:
    npm install

4. Avvia il server centrale digitando:
    node server.js

*(Lascia il terminale aperto e in esecuzione finché usi l'installazione).*

---

## 3. Utilizzo per i Test su PC
Se vuoi testare l'interfaccia e la grafica direttamente sul computer dove sta girando il server:
* Apri il tuo browser (Chrome, Edge, Safari).
* Vai all'indirizzo: **http://localhost:3000**

---

## 4. Connessione del Tablet (Kiosk Mode)
Per usare l'applicazione sul tablet fisico dell'installazione, segui attentamente questi passaggi:

### Regola d'oro per la Rete
Il PC (che fa da server) e il Tablet (che fa da schermo) **DEVONO** essere connessi alla **stessa rete Wi-Fi**. 
*Attenzione: Le reti universitarie bloccano la comunicazione tra dispositivi. Usa l'Hotspot personale del tuo smartphone.*

### Come collegarsi:
1. Connetti sia il PC che il Tablet al tuo Hotspot.
2. Trova l'indirizzo IP del PC:
   * Su **Windows**: apri un nuovo terminale in VS Code, digita `ipconfig` e cerca la riga *Indirizzo IPv4* (es. 192.168.X.X).
   * Su **Mac**: digita `ipconfig getifaddr en0`.
3. Prendi il Tablet, apri il browser (o l'App Kiosk) e inserisci l'indirizzo IP del PC seguito dalla porta :3000.
   * **Esempio:** http://192.168.43.50:3000

---

## Struttura del Progetto
* **server.js**: Il cervello dell'app. Gestisce le connessioni in entrata e formatta i messaggi verso TouchDesigner.
* **public/index.html**: Il codice frontend (struttura, design e logica dei bottoni).
* **public/img_re/**: Cartella contenente tutte le risorse grafiche e le texture usate nell'interfaccia.
