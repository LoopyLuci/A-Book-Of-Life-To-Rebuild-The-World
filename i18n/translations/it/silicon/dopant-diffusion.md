# Diffusione dei dopanti e impianto ionico

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Il drogaggio crea le regioni di tipo n e di tipo p che formano ogni giunzione
in un chip. La diffusione introduce i dopanti con il calore, mentre
l'impianto li introduce con un fascio di ioni. Il principio chiave: è la
profondità della giunzione, e non la sola dose, a stabilire quanto veloce
funziona il dispositivo finito.

## Prerequisiti

- Ossidazione termica, perché ossidi e maschere controllano la diffusione
- Accesso a un forno di diffusione e, per l'impianto, a un impiantatore
- Analisi dei circuiti al livello di saper leggere una curva
  corrente-tensione di un diodo

## Materiali e strumenti

- Un forno di diffusione con tubo di quarzo e controllo a zone
- Sorgenti dopanti solide: wafer di nitruro di boro, oppure wafer epitassiali
  drogati
- Preformati di vetro borosilicato per la diffusione da sorgente solida
- Un impiantatore di ioni, da 20 a 200 keV, o accesso a uno
- Un processore termico rapido per l'attivazione dopo l'impianto
- Una sonda a quattro punti per la resistenza di foglio e un misuratore di
  resistività
- Uno strumento ad angolo di canale o un SIMS per la profondità della
  giunzione
- Wafer ossidati, fotoresist, una maschera e un allineatore
- Pinzette per wafer, un cassetto e un monitor di temperatura

## Procedura

### Pianifica il drogaggio

1. Fissa dal progetto la resistenza di foglio obiettivo e la profondità della
   giunzione obiettivo.
2. Scegli fra diffusione di predeposizione, diffusione di infiltrazione e
   impianto, poi calcola la dose per la profondità scelta.
3. Prepara l'ossido o il nitruro di mascheratura e controlla lo spessore della
   maschera, perché una maschera sottile lascia passare i dopanti di lato.

### Diffondi il dopante

1. Porta la sorgente solida alla sua temperatura di controllo e stabilizzala
   per 30 minuti, poi inserisci il wafer nella zona della sorgente per il
   tempo di predeposizione.
2. Per l'infiltrazione, passa all'atmosfera inerte e alza la temperatura a
   1,000–1,100 gradi C per 30–60 minuti, poi raffredda il wafer nella stessa
   atmosfera.
3. Misura la resistenza di foglio su un wafer di monitoraggio della stessa
   corsa, e prova l'intera ricetta su un wafer di prova prima di toccare i
   wafer di produzione.

### Impianta il dopante

1. Scegli la specie ionica, l'energia, la dose e un'inclinazione del fascio
   di circa 7 gradi per evitare il channeling.
2. Scansiona il fascio sul wafer per mantenere bassa la corrente e il wafer
   sotto i 100 gradi C, e imposta la dose per l'energia e la specie scelte.
3. Conferma l'allineamento del fascio con le verifiche di interbloccamento,
   poi attiva il dopante con una ricottura termica rapida a 900–1,050 gradi C
   per 10–30 secondi.

### Verifica la giunzione

1. Misura la resistenza di foglio con la sonda a quattro punti.
2. Misura la profondità della giunzione con l'analisi ad angolo di canale o
   con il SIMS, e verifica che il profilo corrisponda alla forma attesa a
   scatola o gaussiana.
3. Misura la corrente di perdita inversa di un diodo di prova, e annota per
   ogni lotto energia, dose, inclinazione e ricottura dell'impianto.

## Note di sicurezza

- Gli impiantatori e i forni di ricottura lavorano a tensioni letali e con
  energie di fascio elevate; lavoraci solo con formazione, supervisione e
  attrezzature adeguate.
- Alcuni impianti lasciano i wafer radioattivi, quindi segui le norme locali
  di monitoraggio e manipolazione.
- Le sorgenti di fosforo e di boro sono tossiche e vanno manipolate sotto
  cappa.
- I tubi dei forni lavorano sopra i 1,000 gradi C, quindi usa le pinze e uno
  schermo per il viso.
- I precursori dopanti volatili e i gas tossici richiedono un'aria di
  scarico trattata.
- Un errore di allineamento del fascio può irradiare qualcuno fuori dalla
  camera, quindi considera ogni interbloccamento reale e non bypassarlo mai.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- NIST Semiconductor Reference (pubblico dominio)
