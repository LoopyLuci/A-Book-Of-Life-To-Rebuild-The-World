# Analisi dei circuiti in corrente alternata e impedenza

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

In corrente alternata tensione e corrente non crescono e calano più
insieme, quindi il semplice rapporto fra tensione e corrente non è più un
numero utile. Il principio chiave è sostituire ogni elemento con la sua
impedenza, un numero complesso con una parte resistiva e una parte
reattiva, e poi risolvere esattamente le stesse equazioni di circuito usate
in continua. La reattività è fissata dalla frequenza, ed è per questo che un
circuito che si comporta in un certo modo a regime può essere completamente
diverso a 50 Hz.

## Prerequisiti

- Analisi dei circuiti in continua per le leggi di Kirchhoff e per le regole
  di serie e parallelo
- Numeri complessi in forma rettangolare e polare
- Le funzioni seno e coseno, la fase e il differimento di fase
- Derivazione e integrazione di base, per gli elementi reattivi
- La relazione fra il valore efficace, il valore di picco e il valore
  picco-picco

## Materiali e strumenti

- Un generatore di funzioni e un oscilloscopio
- Un alimentatore da banco e un multimetro digitale con misura di capacità
- Resistenze, condensatori e induttori delle serie E12 ed E24
- Una decade di resistenze, oppure un insieme di valori per lo studio della
  risonanza e dei filtri
- Rame e un supporto per realizzare un induttore di prova
- Un trasformatore di isolamento per qualsiasi lavoro collegato alla rete

## Procedura

### Convertire il circuito in fasori

1. Sostituisci ogni resistenza con R e ogni condensatore e induttore con la
   sua reattività: X_L = 2 x pi x f x L e X_C = 1 / (2 x pi x f x C).
2. Scrivi l'impedenza di ogni elemento in forma rettangolare: Z_R = R,
   Z_L = j X_L e Z_C = -j X_C.
3. Somma le impedenze in serie e combina i rami in parallelo con le stesse
   regole usate in continua, tenendo separati i termini in j, poi converti
   il risultato in forma polare: il modulo è la radice quadrata di R^2 più
   X^2 e l'angolo è l'arcotangente di X su R.

### Risolvere la rete in corrente alternata

1. Applica le leggi di Kirchhoff alla rete di impedenze e risolvi le correnti
   e le tensioni in termini di fasori.
2. Converti le risposte in fasori nel dominio del tempo, ricordando che il
   valore efficace di un seno è il picco diviso per 1.414.
3. Verifica il risultato con la potenza: la potenza attiva è P = V x I x
   cos(phi), la potenza reattiva è Q = V x I x sin(phi) e la potenza
   apparente è S = V x I in volt-ampere.

### Individuare la risonanza

1. Imponi uguali le reattività e risolvi la frequenza di risonanza
   f0 = 1 / (2 x pi x sqrt(L x C)).
2. Misura le frequenze a metà potenza e calcola il fattore di merito
   Q = f0 / (f2 - f1), poi confrontalo con l'espressione che dà
   sqrt(L / C) divisa per la resistenza di serie.
3. Osserva che alla risonanza la corrente di circuito è al massimo e la
   tensione sul condensatore può valere Q volte la tensione di alimentazione.

### Progettare un filtro

1. Fissa la frequenza di taglio a partire dalla specifica e calcola la
   resistenza di un semplice filtro passa-basso RC, R = 1 / (2 x pi x f x
   C), e costruiscilo.
2. Misura la risposta a 0.1, 1 e 10 volte la frequenza di taglio e verifica
   che l'uscita sia calata di 20 dB per decade.
3. Conferma lo sfasamento alla frequenza di taglio, che è di 45 gradi per un
   filtro del primo ordine, e aggiungi un secondo stadio se l'attenuazione
   non è abbastanza ripida.

## Note di sicurezza

- La tensione di rete uccide. Tratta come letale qualsiasi circuito
  collegato all'alimentatore e lavoraci solo con formazione, supervisione e
  attrezzature adeguate, usando un trasformatore di isolamento.
- La corrente che ferma un cuore è piccola: circa 0.5 mA è la soglia di
  percezione, 10 mA è la soglia di rilascio, 30 mA può fermare la
  respirazione e 50 mA può provocare fibrillazione ventricolare.
- Un condensatore carico conserva la sua energia anche dopo lo spegnimento
  dell'alimentatore, perché l'impedenza del multimetro è troppo alta per
  scaricarlo; usa una resistenza di scarica e verifica la tensione con un
  multimetro prima di toccare un nodo.
- Un circuito risonante può produrre una tensione elevata sul condensatore, e
  un convertitore flyback o boost può mettere centinaia di volt su un nodo
  che sembra a bassa tensione.
- Mantieni isolate fra loro l'uscita del generatore di funzioni e le uscite
  dell'alimentatore da banco, e non collegare mai una sorgente di segnale ai
  poli di un'uscita di alimentazione.
- Verifica i valori di tensione e di corrente di ripple dei condensatori, e
  ricorda che la tensione su un condensatore in un circuito risonante può
  essere molto più alta della tensione di alimentazione.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- OpenStax University Physics (CC BY)
