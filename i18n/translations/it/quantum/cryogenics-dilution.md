# Criogenia e refrigerazione a diluizione

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Un refrigeratore a diluizione raffredda un campione a pochi millikelvin
mescolando elio superfluido ed elio normale, e mantiene quella temperatura
solo se l'intero bilancio termico è rispettato. Il principio chiave è che
ogni cavo, ogni filo e ogni superficie sono una perdita nell'isolamento,
quindi il progetto è soprattutto una questione di contare il calore in
microwatt e poi di eliminarlo. Il campione è la parte più piccola del
sistema; le tubazioni, il filtraggio e la schermatura decidono se la
misura sia possibile.

## Prerequisiti

- Nozioni di base di ingegneria criogenica e diagramma di fase dell'elio
- Superfluidità e diluizione dell'elio-3 nell'elio-4
- Ingegneria delle microonde e progetto di catene di attenuatori e filtri
- Pratica del vuoto, ricerca di perdite e manipolazione sicura dei cryogen

## Materiali e strumenti

- Un refrigeratore a diluizione con camera di miscelazione e separatore
- Una linea di trasferimento criogenica e un gruppo di pompe per il vuoto con
  trappola fredda
- Cavo coassiale per il vuoto, connettori SMA e SMP e dissipatori
- Una catena di attenuatori a microonde e un filtro passa-basso per ogni
  linea di segnale
- Un magnete superconduttore, un set di termometri e una stanza schermata

## Procedura

### Pianifica il carico termico

1. Elenca ogni linea che scende dalla temperatura ambiente alla camera di
   miscelazione e conta quante sono.
2. Calcola la perdita per conduzione attraverso ogni cavo dalla conduttività
   termica del materiale, con Q = k A dT su L, e nota che una singola linea
   coassiale non attenuata può portare più di un milliwatt alla fase a 4 K.
3. Calcola il carico radiativo attraverso ciascuno schermo con
   Q = sigma A (T_caldo alla quarta meno T_freddo alla quarta), dove sigma è
   5.67e-8 W per metro quadro per kelvin alla quarta.
4. Aggiungi il raffreddamento di pilotaggio degli amplificatori, confronta il
   totale con la potenza di raffreddamento alla camera di miscelazione,
   tipicamente da 10 a 100 microwatt a 10 mK, e lascia un margine di almeno
   il 30 percento.

### Prepara il cablaggio

1. Termina ogni linea coassiale con un attenuatore allo stadio a 50 K, allo
   stadio a 4 K, al separatore e alla camera di miscelazione, circa 10 dB per
   stadio.
2. Aggiungi un filtro passa-basso allo stadio a 4 K per ogni linea di
   segnale, con taglio vicino ai 5 GHz, e un taglio molto più basso, 700 MHz o
   meno, su ogni linea di polarizzazione continua.
3. Fissa ogni linea agli stadi con treccia di rame o alluminio, così il
   calore si ferma lì.
4. Sottoponi a prova di vuoto l'intera linea e il passante, e non chiudere mai
   lo spazio di vuoto su una linea fredda che non sia stata sottoposta a
   ricerca di perdite.

### Raffredda e verifica

1. Aziona l'elio e le pompe per il vuoto nell'ordine prescritto e non
   interrompere mai un riscaldamento che abbia già prodotto il vuoto.
2. Controlla le temperature degli stadi e il livello dell'elio, e annota il
   tempo di assestamento e la temperatura di base finale.
3. Chiudi gli schermi termici solo dopo che la temperatura di base è stabile,
   poi trasferisci il campione e verifica che la temperatura al supporto
   corrisponda a quella del termometro.
4. Registra insieme la temperatura di base, le temperature degli stadi e il
   fondo di rumore a microonde a ogni raffreddamento.

## Note di sicurezza

- L'elio liquido si espande enormemente riscaldandosi e può far scoppiare un
  volume sigillato, quindi ogni volume freddo ha bisogno di una via di
  scarico e i dispositivi di sicurezza non devono mai essere ostruiti o
  tappati.
- L'elio liquido e l'azoto liquido causano ustioni da freddo e possono
  sostituire l'ossigeno in una stanza; lavora in un locale ben ventilato con
  un monitor di ambiente e non lavorare mai solo con un cryogen.
- Una linea di trasferimento criogenica aperta può iniettare elio liquido in
  una linea in vuoto e provocare un'implosione; non sfogare mai una linea
  fredda all'atmosfera senza seguire la procedura prevista.
- L'ossigeno che condensa su una superficie fredda la rende fragile e ogni
  raccordo criogenico un pericolo di frammenti; usa le guarnizioni
  metalliche corrette e non serrare mai un giunto freddo.
- Un magnete superconduttore immagazzina energia e può andare in quench
  senza preavviso, rilasciando un campo elevato e facendo bollire il
  cryogen; imposta i limiti di rampa e non lasciarlo mai alimentato senza
  sorveglianza.
- Un guasto del vuoto o il ritorno dell'olio delle pompe può contaminare uno
  stadio freddo e distruggere l'esperimento senza alcun avviso visibile.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- NIST Cryogenics Guidance (pubblico dominio)
