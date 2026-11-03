# Correzione degli errori quantistici

> **Domain:** quantum | **Difficulty:** master | **Safety:** green

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

La correzione degli errori quantistici è l'unica strada verso una macchina che
calcola abbastanza a lungo da contare, perché nessun qubit fisico è abbastanza
buono da eseguire da solo un algoritmo utile. Il principio chiave è che la
ridondanza deve essere adattata al tipo di errore: un bit di sindrome classico
rileva un errore di bit, un altro bit di sindrome rileva un errore di fase e
un ancilla che misura la parità congiunta li rileva entrambi. Un codice di
distanza d corregge floor((d-1)/2) errori e ne rileva d-1 e, al di sotto di
una soglia di errore, i qubit aggiuntivi fanno scendere il tasso di errore
logico sotto quello fisico.

## Prerequisiti

- Porte quantistiche, gruppo di Pauli e formalismo degli stabilizzatori
- Matrici di densità, sfera di Bloch e canali rumorosi
- Teoria elementare dei codici per i codici classici usati dentro quelli
  quantistici
- Un simulatore classico funzionante e uno strumento di disegno dei circuiti

## Materiali e strumenti

- Un simulatore a vettore di stato e un simulatore degli stabilizzatori per
  codici piccoli
- Un risolutore a matrice di densità per il modello di rumore di un singolo
  round
- Dati di benchmarking randomizzato per la piattaforma in studio
- Un'implementazione di riferimento di un decoder a accoppiamento perfetto di
  peso minimo
- Tabelle del tasso di errore logico in funzione della distanza del codice e
  dell'errore fisico
- Un foglio di calcolo o uno script per i bilanci di errore fisico e logico

## Procedura

### Classifica l'errore

1. Separa gli errori di bit (X), di fase (Z) e combinati (Y), e ricorda che
   un canale di depolarizzazione produce tutti e tre insieme.
2. Associa un modello di rumore a ogni porta, partendo da un tasso di
   depolarizzazione a un qubit di 1e-3 e a due qubit di 1e-2, realistico per
   qubit superconduttori.
3. Includi nel modello l'errore di misura, perché una lettura difettosa della
   sindrome può creare un errore sui dati che non esisteva.

### Scegli il codice

1. Fissa il tasso di errore logico obiettivo e il numero di cicli di circuito:
   il prodotto è il numero di occasioni indipendenti di fallire.
2. Confronta le famiglie di codici: il codice Shor a nove qubit corregge un
   errore con nove qubit, il codice Steane ne corregge uno con sette e il
   codice superficiale spende molti più qubit per correggere molti più
   errori.
3. Verifica il limite di Singleton, n - k >= 2(d-1), e ricorda che un codice
   a sottosistemi richiede almeno due copie per una porta logica a due
   qubit.

### Modella il decoder e individua la soglia

1. Calcola la sindrome per ogni round di stabilizzatori e individua l'errore
   di peso minimo che la spiega, usando un decoder a accoppiamento perfetto di
   peso minimo per il codice superficiale.
2. Tieni la latenza del decoder sotto il tempo di round della sindrome, circa
   1 microsecondo su hardware superconduttore, o la correzione arriva troppo
   tardi per prevenire l'errore successivo.
3. Percorri una scala di distanze, d = 5, 9, 13 e 17, e individua il punto
   di incrocio in cui il tasso di errore logico smette di scendere; prevedi
   circa l'1% per rumore di depolarizzazione e circa il 10% per rumore di
   cancellazione.

### Bilancia l'overhead

1. Stima i qubit fisici necessari; con un tasso di errore fisico di 1e-3 e un
   tasso di errore logico obiettivo di 1e-12, prevedi circa 1e4 qubit
   fisici per ogni qubit logico.
2. Aggiungi le ancille di sindrome, una per stabilizzatore, così un codice
   superficiale di distanza d richiede circa d al quadrato qubit dati e d al
   quadrato meno uno ancille.
3. Conta i qubit che restano inattivi mentre gli altri calcolano, e annota
   la distanza, l'overhead e il tasso di errore fisico ipotizzato insieme al
   risultato.

## Note di sicurezza

- È un compito di analisi, ma i numeri decidono se una macchina vale la pena
  costruirla: non accettare mai un tasso di errore logico dichiarato che non
  sia stato misurato sul modello di rumore dell'hardware reale.
- Un decoder più lento del round di sindrome degrada silenziosamente il tasso
  di errore logico, quindi misura la latenza del decoder sulla macchina di
  riferimento.
- Non riutilizzare mai un decoder o una configurazione hardware provenienti da
  una simulazione senza rumore: il bilancio degli errori vale solo sul
  modello di rumore reale.
- Tieni il decoder classico lontano dallo stadio criogenico e isola
  l'hardware di controllo, così un guasto nel decoder non può agire sullo
  stato del qubit.
- Registra il bilancio degli errori e la distanza del codice insieme ai dati
  di calibrazione, perché un dispositivo ricalibrato senza riverificare il
  bilancio potrebbe non essere più sotto soglia.
- Considera non dimostrata qualsiasi affermazione di tolleranza ai guasti
  senza una soglia misurata, e ditelo nella relazione.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- NIST Quantum Initiative Reference (pubblico dominio)
