# Flusso di progettazione di circuiti integrati

> **Domain:** silicon | **Difficulty:** master | **Safety:** yellow

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Un circuito integrato parte da una specifica scritta e arriva a un layout
GDSII che una foundry può mascherare. Il principio chiave è che ogni fase è
un cancello di verifica: nulla avanza finché la fase precedente non è
dimostrata, perché il costo di un difetto cresce rapidamente a ogni passo,
da una ricompilazione a un riflusso dell'intero chip. Il progetto è quindi
soprattutto un argomento fatto di prove, e l'artefatto che sopravvive è
l'archivio di che cosa è stato controllato, quando e con quale versione degli
strumenti.

## Prerequisiti

- Progettazione digitale e logica booleana
- Analisi temporale: setup, hold, skew del clock e percorso critico
- Verilog o VHDL e il simulatore e gli strumenti di sintesi citati sotto
- Un technology design kit: celle standard, LEF e GDEF, livelli GDSII e
  temporizzazione Liberty
- Controllo versione con ramificazioni e revisione tra pari

## Materiali e strumenti

- Documenti di specifica e di piano di verifica
- Sorgenti RTL, un testbench e un simulatore con visualizzatore di forme
  d'onda
- Strumento di sintesi con libreria di celle standard e file temporizzazioni
  Liberty
- Strumento di piazzamento e instradamento con il design kit, più analisi
  temporale statica
- Strumenti di signoff: lint, CDC, DRC, LVS e controlli di caduta IR e
  migrazione elettromagnetica
- Repository Git, un gestore di issue e un modello di costo che copra il
  costo del wafer, l'area del die, i die per wafer e il costo una tantum di
  maschere e di progetto

## Procedura

### Specifica e scrivi l'RTL

1. Scrivi la specifica: l'interfaccia, il clock, la portata, il budget di
   latenza, il tetto di potenza, il tetto di area del die e il tetto di costo.
2. Scrivi il piano di verifica prima dell'RTL, coprendo le asserzioni, i casi
   limite e gli obiettivi di copertura.
3. Congela la specifica e registrala, così una modifica successiva si
   manifesta come una modifica e non come una deriva.
4. Scrivi l'RTL, simula il testbench fino a una regressione che passa e
   lancia il lint per discrepanze di ampiezza, assegnamenti incompleti e
   driver multipli.

### Sintetizza e piazza

1. Imponi i vincoli di clock, con periodo e incertezza, e lancia la sintesi
   rispetto all'area e alla temporizzazione di riferimento.
2. Leggi il report del percorso critico e la stima di potenza: la potenza
   dinamica è all'incirca C x V^2 x f più la perdita in standby.
3. Pianifica il floorplan prima che lo faccia lo strumento, collocando le
   memorie, i blocchi analogici e l'anello di I/O, e lasciando spazio per la
   rete di alimentazione.
4. Esegui il piazzamento, poi l'inserimento dell'albero del clock, poi
   l'instradamento, e controlla lo skew e la congestione dell'instradamento
   dopo ogni fase.

### Signoff e tape-out

1. Esegui l'analisi temporale statica sugli angoli lento e veloce, per il
   setup e per l'hold.
2. Esegui il DRC per regole di spaziatura, densità e antenna, l'LVS contro lo
   schema elettrico e i controlli di caduta IR e migrazione elettromagnetica.
3. Chiudi ogni violazione, poi esegui un Monte Carlo multi-angolo per far
   emergere i rari fallimenti temporali.
4. Esporta il GDSII, genera il set di maschere, archivialo con un checksum e
   le versioni degli strumenti usate, e dividi l'ordine fra due foundry per
   tutelare il calendario.

## Note di sicurezza

- I pericoli qui sono pericoli di progetto: un tape-out non revisionato
  spreca l'intero set di maschere e il denaro che c'è dietro.
- Blocca il sorgente e qualsiasi proprietà intellettuale di terzi, e conserva
  i file di progetto in un archivio ad accesso controllato; valgono per essi
  le norme sul controllo delle esportazioni.
- Usa build riproducibili: registra le versioni degli strumenti, gli script e
  lo stato delle licenze, così l'archivio può essere ricostruito esattamente.
- Verifica le IP di terzi prima dell'uso, perché un bug subdolo in una macro
  hard è costoso e difficile da trovare.
- Fai controllare la lista di signoff da una seconda persona rispetto alla
  specifica prima di emettere l'ordine.
- Archivia il GDSII e il set di maschere; perderli significa pagare di
  nuovo le maschere.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- NIST Semiconductor Reference (pubblico dominio)
