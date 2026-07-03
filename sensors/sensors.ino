const int gsrPin = A0;    
const int pulsePin = A1;  

// --- VARIABILI FILTRO ONDA ---
float filteredPulse = 0;
float prevRawPulse = 500;
const float filterFactor = 0.95;

// --- VARIABILI CALCOLO BPM ---
unsigned long lastBeatTime = 0;  
int bpm = 0;                     
boolean isPeak = false; 
const int beatThreshold = 8;    

// --- VALORI DI DEFAULT (FALLBACK) ---
const int defaultGSR = 520;  // Valore standard di rilassamento per il GSR
const int defaultBPM = 82;   // Battito standard a riposo (BPM)

void setup() {
  Serial.begin(9600);
  // Inizializza il generatore di numeri casuali usando il rumore di un pin vuoto
  randomSeed(analogRead(A5)); 
}

void loop() {
  int gsrValue = analogRead(gsrPin);
  int rawPulse = analogRead(pulsePin);

  // 1. Filtro passa-alto per l'onda del cuore
  filteredPulse = filterFactor * (filteredPulse + rawPulse - prevRawPulse);
  prevRawPulse = rawPulse;
  int currentSignal = (int)filteredPulse;

  unsigned long currentTime = millis();
  
  // 2. Rilevamento del picco cardiaco
  if (currentSignal > beatThreshold && isPeak == false) {  
    isPeak = true; 
    unsigned long ibi = currentTime - lastBeatTime; 
    
    if (ibi >= 450 && ibi <= 1300) {
      int calculatedBpm = 60000 / ibi;
      if (calculatedBpm >= 60 && calculatedBpm <= 120) {
        bpm = calculatedBpm; // Salva il BPM reale
      }
    }
    lastBeatTime = currentTime;
  }

  if (currentSignal < (beatThreshold / 2)) {
    isPeak = false;
  }

  // Se non viene rilevato nessun battito reale per più di 2.5 secondi, azzera la variabile locale
  if (currentTime - lastBeatTime > 2500) {
    bpm = 0;
  }

  // ============================================================
  // 3. LOGICA DI FALLBACK (DATI STANDBY / ERRORI)
  // ============================================================
  int finalGSRToSend = gsrValue;
  int finalBPMToSend = bpm;

  // FALLBACK GSR: Se il sensore non è indossato (valore a vuoto molto basso)
  if (gsrValue < 50 || gsrValue > 1000) {
  finalGSRToSend = defaultGSR + random(-3, 4);
  }

  // FALLBACK BATTITO: Se il battito è a 0 (dito tolto o lettura errata)
  if (bpm == 0) {
    // Genera un battito simulato attorno a 72 con una micro-variazione (+/- 1)
    finalBPMToSend = defaultBPM + random(-1, 2);
  }

  // ============================================================
  // 4. INVIO DATI SICURI A TOUCHDESIGNER
  // ============================================================
  Serial.print(finalGSRToSend);
  Serial.print(",");
  Serial.println(finalBPMToSend);

  delay(20);
}
