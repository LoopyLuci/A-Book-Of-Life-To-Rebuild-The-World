# Incisione a umido e a secco

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

L'incisione rimuove il materiale in modo selettivo, così che il disegno del
resist venga trasferito nello strato sottostante. Due numeri decidono se la
struttura sopravvive: la selettività, cioè la velocità di incisione dello
strato divisa per quella della maschera, e l'anisotropia, il rapporto fra
rimozione verticale e laterale. L'incisione a umido è economica e isotropica,
mentre l'incisione a plasma secco è direzionale e precisa, quindi la scelta
segue la geometria e non la comodità.

## Prerequisiti

- Fotolitografia e produzione di maschere (disegni del resist e fabbricazione
  delle maschere)
- Deposizione di film sottili per maschere dure e rivestimenti
  antiriflesso
- Pulizia dei wafer e adesione affidabile della maschera alla superficie
- Lettura delle tabelle di velocità di incisione e selettività dello
  strumento

## Materiali e strumenti

- Banco umido: vasche riscaldate, controllo della temperatura e asciugatore a
  centrifuga
- Incisori: acido fluoridrico, acido nitrico, acido acetico, idrossido di
  potassio, idrossido di tetrametilammonio e incisore dell'ossido tamponato
- Incisore RIE o ICP con generatore RF a 13.56 MHz, adattatore di
  impedenza e pompa
- Gas di processo: CF4, CHF3, SF6, Cl2 e O2, con aria di scarico trattata
- Ellipsometro, profilometro e microscopio ottico per le misure
- Contenitori in PTFE e polietilene, pinzette per wafer e schermo per il viso

## Procedura

### Pianifica la selettività

1. Fissa la profondità obiettivo e la dimensione critica dello strato.
2. Consulta la velocità di incisione del film e della maschera nel tuo
   strumento e nella tua chimica; le velocità pubblicate non si trasferiscono
   da una macchina all'altra.
3. Richiedi una selettività di almeno 10:1 per un film da 100 nm sotto un
   resist da 1 um, e aggiungi una maschera dura quando il resist non
   sopravviverà all'incisione.
4. Prevedi l'effetto di carico: aspettati che la velocità di incisione cali
   all'aumentare dell'area aperta, quindi taglia un wafer di prova che
   porti sia un disegno piccolo sia uno grande.

### Incisione a umido

1. Pulisci il wafer, asciugalo e applica il resist o la maschera dura.
2. Incidi il silicio con acido fluoridrico, nitrico e acetico a 60-80 °C per
   20-60 s, oppure incidi in idrossido di potassio a 80 °C per una rimozione
   anisotropica con selettività superiore a 100:1 rispetto all'ossido di
   silicio.
3. Risciacqua in acqua deionizzata e asciuga con azoto.
4. Compensa il sottotaglio sovradimensionando la maschera della profondità di
   incisione per lato, e preserva il piano (111) mascherando gli angoli con
   una linguetta di almeno 1.41 volte la dimensione prevista.

### Incisione a secco

1. Carica il wafer nell'incisore, fai il vuoto e condiziona la camera con
   una pulizia a ossigeno e fluorocarburi.
2. Imposta il flusso di gas, la pressione (circa 10-50 mTorr per RIE e 1-10
   mTorr per ICP), la potenza del generatore (300-600 W per il silicio) e la
   potenza di bias per il film di riferimento.
3. Incidi fino alla profondità prevista e fermati a un segnale di fine
   incisione: un interference ottico di fine processo o il calo della linea
   di emissione del silicio.
4. Misura la profondità e il profilo della parete laterale su un wafer di
   prova, controlla la presenza di intaglio alla base di una struttura larga
   e annota la velocità e la selettività per la corsa successiva.

## Note di sicurezza

- **Pericolo rosso:** L'acido fluoridrico è letale per contatto con la pelle e
  per inalazione, e attacca le ossa. Manipolalo solo con formazione,
  supervisione e attrezzature adeguate, con gel di gluconato di calcio al
  banco e un sistema a coppie.
- **Pericolo rosso:** Non conservare mai né trasportare l'acido fluoridrico in
  vetro; attacca il vetro e lo attraversa.
- La miscela di acido fluoridrico, nitrico e acetico libera biossido di
  azoto; lavora sotto cappa e non inalare mai il vapore.
- I gas dell'incisione al plasma sono tossici e asfissianti: la chimica del
  cloro produce cloruro di idrogeno e quella del fluoro produce fluoruro di
  idrogeno.
- Il generatore a radiofrequenza e il plasma sono letali al contatto; tieni
  gli interbloccamenti e l'abbattitore di scarico in funzione ogni volta che
  scorre gas.
- Le vasche di incisore devono essere etichettate con composizione e data, e
  una vasca che ha visto silicio non deve mai essere riportata a una
  pulizia del vetro.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- NIST Semiconductor Reference (pubblico dominio)
