# Principi di progettazione dello scafo

> **Domain:** ship | **Difficulty:** apprentice | **Safety:** green

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Uno scafo è un compromesso fra il volume che deve trasportare, la resistenza
che oppone nell'acqua e il modo in cui si comporta in mare mosso. Il principio
chiave è che il progetto parte dal peso, non dalla lunghezza: lo spostamento
è quanto pesa la nave, e la forma del corpo immerso decide poi quanto costa
muovere quel peso. Pienezza e larghezza comprano stabilità e volume di carico
e le pagano in resistenza, quindi ogni scelta è un compromesso che va
messo in conto.

## Prerequisiti

- Archimede e il significato di spostamento
- Trigonometria di base per i coefficienti di forma e gli offset
- Lettura di un disegno in scala e uso di compasso da divisione e spline
- Il lessico del mare: pescaggio, freeboard, larghezza e assetto

## Materiali e strumenti

- Carta da disegno, tavola da disegno, compasso da divisione e spline
- Planimetro, oppure metodo a griglia per misurare le aree sul disegno
- Dati idrostatici per acqua di mare a 1025 kg/m3 e per acqua dolce a
  1000 kg/m3
- Tabelle di riferimento per i coefficienti di blocco, prismatico e di
  superficie al galleggiamento
- Dati di resistenza e un stimatore del numero di giri dell'elica
- Tabella dei pesi e dei momenti e un traguardo per i segni di pescaggio

## Procedura

### Definisci i requisiti

1. Elenca il carico utile, l'equipaggio, il carburante e la riserva; la
   somma di questi è il deadweight.
2. Aggiungi il peso a vuoto per struttura, apparati e allestimento, poi
   dividi il totale per la densità dell'acqua per ottenere il volume che lo
   scafo deve spostare sotto la linea di galleggiamento.
3. Scegli la lunghezza overall e lo spostamento in base al carico, e mantieni
   il rapporto fra lunghezza e larghezza fra 4:1 e 6:1 per mezzi d'uso
   generale.

### Scegli la forma

1. Calcola il coefficiente di blocco come volume displato diviso per L x B x
   T, dove T è il pescaggio, e punta a 0.4–0.6 per uno scafo a displacimento.
2. Punta a un coefficiente prismatico di 0.55–0.75 e a un coefficiente di
   superficie al galleggiamento di 0.6–0.8, e ricorda che una forma più
   piena, fino a circa 0.8, trasporta di più ma oppone più resistenza.
3. Fai il bilancio del compromesso: più larghezza e più pienezza aumentano il
   momento di raddrizzamento iniziale e il volume di carico, e costano
   resistenza e moto in mare mosso.

### Traccia le linee

1. Disegna le buttocks, cioè le sezioni trasversali, a circa quattro stazioni
   per ogni lunghezza di scafo, e traccia le linee d'acqua al pescaggio di
   progetto, al pescaggio a pieno carico e altre due sopra.
2. Traccia la linea di base, la chiglia, l'asse di prua e di poppa, il bordo
   di coperta e la curva di centro, usando la regola 10-90-10 per le estremità,
   con il 10% della lunghezza avanti e indietro rispetto ai perpendicolari e
   il 90% fra essi.
3. Inquadra le sezioni con la spline e verifica che la curvatura di ogni
   linea sia continua e che le sezioni si raccordino bene fra loro.

### Stima la potenza

1. Stima la resistenza d'attrito come 0.5 x rho x V^2 x S x C_f, con C_f
   pari a 0.075 diviso per il quadrato di (log10(L) - 2) per uno scafo liscio
   a un numero di Reynolds superiore a 1e7.
2. Aggiungi la resistenza residua, prevedendo dal 15% al 40% del totale per
   uno scafo a displacimento a velocità moderata.
3. Stima la potenza all'asse come resistenza per velocità divisa per
   l'efficienza globale, da 0.35 a 0.50 per un piccolo diesel con elica, e
   convertila in giri al minuto dell'elica.

## Note di sicurezza

- È un esercizio da tavolo, ma i numeri che produce decidono il galleggiamento:
  verifica la stabilità e il freeboard con il carico a bordo, non nella
  condizione a vuoto.
- Non lavorare mai da solo su uno scafo in acqua; usa una scala e
  un'imbracatura, e tieni un giubbotto di salvataggio a portata di mano.
- L'acqua fredda e l'annegamento sono i veri pericoli a bordo, e un
  capovolgimento in uno spazio ristretto finisce in fretta.
- Mantieni il freeboard abbastanza alto da lasciare asciutto il bordo di
  coperta con mare da poppa.
- Ricalcola la stabilità dopo ogni variazione di peso, compresi un cambio di
  equipaggio o di provviste.
- Non approvare uno spostamento o un pescaggio senza margine; la densità
  dell'acqua di mare cambia con temperatura e salinità.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- US Navy Hull Design Principles (pubblico dominio)
