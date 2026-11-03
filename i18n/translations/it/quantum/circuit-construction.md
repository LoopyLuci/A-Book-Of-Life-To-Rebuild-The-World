# Costruzione di circuiti quantistici

> **Domain:** quantum | **Difficulty:** apprentice | **Safety:** green

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Un circuito quantistico è una ricetta scritta: un elenco di porte su un elenco
di qubit, seguito dalle misurazioni. Il principio chiave è che il circuito
che scrivi non è il circuito che gira, perché prima il compilatore deve
tradurlo sulle porte e sulle connessioni che l'hardware ha davvero. Imparare
a leggere questa traduzione e a tenere i due circuiti vicini è la competenza
pratica.

## Prerequisiti

- Vettori complessi e prodotto matriciale
- La sfera di Bloch e le porte a un solo qubit
- Nozioni di base di Python o di un altro linguaggio di scripting
- Le regole di un circuito quantistico: non si clona e la misurazione
  distrugge

## Materiali e strumenti

- Un SDK quantistico come Qiskit, Cirq o Braket
- Un simulatore a vettore di stato per circuiti piccoli, fino a circa 20 qubit
- Un backend hardware e i suoi dati di calibrazione pubblicati
- Un notebook o un file con il circuito e l'output atteso
- Una copia locale del modello di rumore del dispositivo di riferimento

## Procedura

### Scrivi il circuito

1. Formula la domanda a cui il circuito risponde prima di scrivere una sola
   porta.
2. Costruisci il circuito a strati, una porta alla volta, e disegnalo per
   verificare che i fili siano i qubit che intendevi.
3. Tieni basso il numero di porte e preferisci una coppia di entanglement a
   diverse coppie sovrapposte.
4. Aggiungi le misurazioni per ultime e ricorda che misurare prima distrugge
   lo stato per il resto del circuito.

### Compilalo

1. Passa il circuito dal transpiler per il backend di riferimento e lascia che
   scelga la base nativa e la mappatura.
2. Guarda la disposizione scelta dal compilatore: su una griglia o su
   connettività heavy-hex i qubit lontani sono collegati da porte swap, che
   aggiungono errore.
3. Scegli tu la disposizione iniziale quando il circuito ha una geometria
   naturale e confronta il numero di porte delle due scelte.
4. Imposta il livello di ottimizzazione a 1 o 2, annota quale livello ha
   prodotto l'esecuzione che conservi e controlla i tempi di impulso
   schedulati, perché il compilatore può inserire tempi morti durante i
   quali il qubit deriva.

### Esegui e leggi il risultato

1. Esegui il circuito molte volte e conta gli esiti; una sola esecuzione non
   dice quasi nulla.
2. Confronta l'istogramma con la simulazione ideale e indica la differenza
   come numero, non come impressione.
3. Controlla nei metadati del job la data di calibrazione del dispositivo e
   rifiuta di riportare un numero proveniente da un dispositivo non
   calibrato.
4. Salva insieme il circuito, la versione compilata, il seme e i conteggi,
   riesegui con un seme diverso e verifica che le statistiche concordino
   prima di trarre conclusioni.

## Note di sicurezza

- Un simulatore può esaurire la memoria della macchina: un vettore di stato
  richiede 16 byte per qubit, quindi 30 qubit richiedono 16 terabyte; si
  devono usare invece i metodi dello stabilizzatore o della matrice di
  densità.
- Non inviare mai a un dispositivo condiviso un circuito che contiene una
  chiave segreta nelle sue porte senza averlo esaminato, perché un circuito
  rivela moltissimo sui dati da cui è stato costruito.
- Eseguire sull'hardware costa tempo di coda e raffredda la macchina, quindi
  raggruppa i circuiti e lascia il dispositivo libero per gli altri.
- La misurazione è distruttiva, e un circuito che misura presto e poi riutilizza
  il qubit dà una risposta sbagliata invece di un messaggio d'errore.
- Non riportare un risultato hardware senza il nome del dispositivo, la data
  di calibrazione e il numero di esecuzioni, perché nessuno di questi si può
  recuperare in seguito.
- Un simulatore senza rumore mostra volentieri un risultato perfetto per un
  circuito che non può girare, quindi indica sempre quale dei due ha prodotto
  i numeri.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- NIST Quantum Initiative Reference (pubblico dominio)
