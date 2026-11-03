# Standard dei bus e interfacce di segnale

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Un bus è un accordo sui fili: che cosa significa un livello logico, chi ha
diritto di pilotare la linea e come un ricevitore sa che un bit è valido. Il
principio chiave è che ogni standard di bus risolve gli stessi tre problemi,
la capacità di pilotaggio, la temporizzazione e l'arbitraggio, e che un
dispositivo che ne ignora uno solo fallisce in modo intermittente anziché in
modo pulito. Le tre interfacce descritte qui sotto coprono quasi tutto ciò
che un'officina deve collegare.

## Prerequisiti

- Logica digitale: push-pull, open-drain, pull-up e livelli logici
- Lettura di una tabella dei pin e di un diagramma temporale di un foglio
  dati
- Framing seriale: velocità in baud, bit di dati, parità e bit di stop
- Saldatura di base e uso di un multimetro o di un analizzatore logico

## Materiali e strumenti

- Un analizzatore logico in grado di decodificare UART, I2C e SPI
- Una scheda di sviluppo con microcontrollore e qualche scheda breakout
- Pacchetti di resistenze di pull-up, da 2 kOhm a 10 kOhm per I2C a 400 kHz
- Resistenze di serie da 22 a 33 Ohm e terminazioni da 120 Ohm per le tratte
  lunghe
- Un alimentatore da banco, un multimetro e un oscilloscopio

## Procedura

### UART

1. Accordate prima la struttura della trama: 8 bit di dati, nessuna parità e
   1 bit di stop, così sul filo viaggiano 10 bit per ogni byte.
2. Imposta la stessa velocità in baud a entrambe le estremità, e ricorda che
   un errore del 2 percento è di solito tollerabile mentre il 5 percento non
   lo è.
3. Collega la trasmissione alla ricezione e la ricezione alla trasmissione, e
   unisci le masse; la massa comune è la parte che più spesso viene
   dimenticata.
4. Verifica che lo stato di riposo sia logica 1 e che una logica 0 segnali il
   bit di start, poi controlla i livelli logici a entrambe le estremità prima
   di fidarti dei dati e usa un traslatore di livello per un collegamento da
   5 V a 3.3 V.

### I2C

1. Porta SDA e SCL a positivo tramite 2 kOhm–10 kOhm e verifica il tempo di
   salita rispetto alla capacità del bus prima di aumentare il clock.
2. Indirizza i dispositivi con un indirizzo a 7 bit, e ricorda che molti
   componenti usano due indirizzi distinti per le due alimentazioni.
3. Leggi dal foglio dati l'ordine dell'indirizzo e del registro, poi
   confermalo sull'analizzatore prima di fidarti della sequenza.
4. Controlla i tempi di setup e di hold nel diagramma temporale, mantieni il
   clock sotto 100 kHz per una prima prova e sblocca un bus bloccato con un
   impulso di nove clock anziché tenendo SDA basso.

### SPI

1. Collega clock, ingresso master, uscita master e chip select, e assegna a
   ogni dispositivo la propria linea di select.
2. Parti in modalità 0, con il clock a riposo basso e i dati campionati sul
   fronte di salita, poi conferma la modalità sul foglio dati.
3. Tieni il clock sotto 1 MHz per una prima prova, accorcia i fili se i fronti
   appaiono arrotondati sull'analizzatore e metti 22–33 Ohm in serie al clock
   e alle linee dati per smorzare l'oscillazione.
4. Leggi nel foglio dati la temporizzazione del full-duplex, compreso il
   ritardo fra il momento in cui il chip select diventa attivo e il primo
   fronte di clock.

## Note di sicurezza

- Gli analizzatori logici e molte schede di sviluppo collegano la propria
  massa alla terra dell'host, quindi sondare un circuito ad alta tensione o
  di rete può distruggere l'analizzatore e provocare un incendio.
- Verifica le alimentazioni di entrambe le estremità prima di collegare un
  bus; una periferica a 5 V che pilota un ingresso a 3.3 V può distruggere
  il controller.
- Non sondare mai un motore o un circuito di riscaldamento sotto tensione
  senza una sonda differenziale adatta alla tensione.
- Mantieni una massa comune fra i due dispositivi; una massa flottante dà
  dati falsi e può danneggiare le porte.
- Tieni i pull-up I2C più corti possibile, compatibilmente con il percorso,
  perché una tratta lunga non terminata irradia e provoca guasti
  intermittenti.
- Una sola linea in cortocircuito mette fuori uso tutti i dispositivi del
  bus, quindi togli tensione alla sezione prima di rifare i collegamenti.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- NXP and Analog Devices Interface Notes (pubblico dominio)
