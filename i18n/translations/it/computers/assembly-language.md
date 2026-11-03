# Linguaggio assembly e modello della macchina

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

L'assembly è la forma testuale di ciò che il processore esegue davvero.
Mostra come la macchina sposta i dati fra registri e memoria, come salta e
come usa lo stack, il che lo rende lo strumento giusto per le parti di un
sistema in cui tempo o memoria non possono essere sprecati. Il principio
chiave è che l'architettura è un contratto: la codifica delle istruzioni, il
set di registri e la convenzione di chiamata sono fissati, quindi il codice
che li rispetta resta corretto fra compilatori, librerie e revisioni
future.

## Prerequisiti

- Programmazione C per sistemi embedded
- Sistemi numerici binario ed esadecimale
- Logica booleana e rappresentazione in complemento a due
- Lettura di una mappa di memoria e di un foglio dati del processore

## Materiali e strumenti

- Scheda Cortex-M con sonda di debug, oppure una macchina ospite con un
  disassemblatore
- Catena di strumenti ARM GCC, comprese le utility objdump e nm
- Manuale di riferimento per il set di istruzioni e la mappa di memoria
- Editor di testo con visualizzazione esadecimale
- Analizzatore logico per osservare la temporizzazione dei pin e dei bus
- Uno script di prova o un programma da terminale che piloti un ingresso noto

## Procedura

### Imparare il set di istruzioni

1. Elenca il set di registri dell'architettura: 13 registri generali da R0 a
   R12, più il puntatore allo stack, il registro di link e il contatore di
   programma, e i flag che segnano negativo, zero, riporto e overflow.
2. Scrivi i modi di indirizzamento, dal registro e dall'immediato, passando per
   registro con offset e registro indiretto, fino a push e pop sullo stack,
   con un esempio su una riga per ciascuno.
3. Annota le codifiche: istruzioni a 16 bit nella codifica base, istruzioni a
   32 bit nella codifica estesa, e il fatto che un'istruzione a 32 bit deve
   trovarsi su un allineamento di 4 byte.

### Leggere un disassembly

1. Compila una piccola funzione C con le informazioni di debug e
   disassemblala con l'utility objdump, poi abbina ogni riga di C con le sue
   istruzioni.
2. Individua il prologo che salva i registri, il corpo e l'epilogo che li
   ripristina e ritorna attraverso il registro di link.
3. Cerca nel listing la dimensione dello stack frame e verifica che coincida
   con quanto riportato dal compilatore per la stessa funzione.

### Scrivere una routine

1. Scrivi in assembly una funzione che riceve due argomenti nei primi due
   registri e restituisce il risultato nel primo, seguendo lo standard per le
   chiamate di procedura.
2. Mantieni il puntatore allo stack allineato a 8 byte a ogni confine di
   chiamata e controlla l'allineamento prima di ritornare.
3. Prova la routine contro un'implementazione in C su molti ingressi e
   confronta i risultati valore per valore.

### Mescolare con il C e profilare

1. Marca una routine come naked solo dove serve e lascia che il compilatore
   gestisca i registri attorno alla chiamata ovunque altrove.
2. Misura il numero di cicli con il contatore di cicli del core e confrontalo
   con lo stesso lavoro scritto in C a ogni livello di ottimizzazione.
3. Leggi il file di mappa del linker per vedere quanto flash e RAM ha
   risparmiato l'assembly, e conservalo solo dove il risparmio giustifica la
   manutenzione.

## Note di sicurezza

- Una routine in assembly può portare un pin di uscita a qualsiasi stato
  nell'istante in cui viene eseguita, e un ciclo infinito dentro un gestore
  di interrupt farà scattare il watchdog o bloccherà la macchina. Verifica il
  nuovo codice con gli attuatori scollegati.
- Scrivere all'indirizzo sbagliato in assembly corrompe memoria e registri
  periferiche senza avvisi. Controlla ogni indirizzo sulla mappa di memoria
  prima di scriverci e verifica che la regione sia eseguibile e non protetta.
- Rispetta le regole di allineamento del core; un accesso a 32 bit non
  allineato causa fault su alcuni dispositivi e costa cicli in silenzio su
  altri.
- L'esecuzione passo-passo modifica la temporizzazione del programma, quindi
  non fare il debug di un anello di regolazione passo-passo. Usa un buffer
  di traccia o un analizzatore logico.
- Tieni a portata di mano un reset hardware, un bootloader o un'immagine di
  ripristino, e prova il percorso di recupero prima di farvi affidamento.
- Tratta l'assembly come non manutenibile per impostazione predefinita:
  tienilo piccolo, commentato con l'uso dei registri e coperto dal test di
  riferimento in C.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- Arm Cortex-M Documentation (pubblico dominio)
