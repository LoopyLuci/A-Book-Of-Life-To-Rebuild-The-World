# Compilatori, linker e sistemi di build

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Una build trasforma il sorgente in un binario attraverso fasi che di solito
sono nascoste: il preprocessore, la compilazione in assembly, l'assembly in
file oggetto e il linking degli oggetti in un eseguibile. Conoscere ogni fase
trasforma una catena di strumenti da mistero in strumento, perché la maggior
parte dei guasti fuorvianti, un simbolo mancante, un salto improvviso di
dimensione, un binario diverso da macchina a macchina, appartiene a una sola
fase e ha una sola soluzione. Il principio chiave è che ogni fase produce un
artefatto che puoi leggere, quindi una build dovrebbe essere sempre
ispezionabile e non una scatola nera.

## Prerequisiti

- Programmazione in C e preprocessore
- Programmazione C per sistemi embedded
- Uso della riga di comando ed editor di testo
- Conoscenze di base su file e directory

## Materiali e strumenti

- Catena di strumenti GNU: compilatore, assemblatore, linker, archiviatore,
  objdump, nm, size
- GNU Make, oppure un altro motore di build
- Un piccolo progetto con un header, due file sorgente e un programma di
  prova
- Visualizzatori di file oggetto e hex, più un sistema di controllo versione
- Una directory di build tenuta separata dall'albero dei sorgenti
- Un manifest che fissa la versione del compilatore e i flag

## Procedura

### Segui le fasi

1. Esegui da solo il preprocessore e leggi il suo output, poi compila in
   assembly e leggi anche quello, così sai da quale fase viene il guasto.
2. Produci i file oggetto e ispeziona le intestazioni delle sezioni: le
   sezioni text, data, dati di sola lettura e bss, insieme alla tabella dei
   simboli.
3. Collega gli oggetti in un eseguibile e ispeziona il punto di ingresso e la
   mappa di dove il linker ha collocato le cose.

### Controlla la build

1. Scrivi un makefile con regole esplicite, target phony e un file di
   dipendenze per ogni sorgente, così una modifica a un header ricostruisce
   tutti i file che lo includono.
2. Tieni un target per ogni output e il comando di compilazione in una sola
   variabile, così nessuna regola può contraddire un'altra sulle opzioni.
3. Abilita le sezioni per funzione e l'opzione del linker che scarta le
   sezioni inutilizzate, poi misura la variazione nel file di mappa.

### Collega in modo deliberato

1. Scegli il linking statico o dinamico per ogni componente, e tieni presente
   che una libreria condivisa aggiunge una dipendenza di versione a ogni
   macchina che la esegue.
2. Rendi espliciti nello script di linking il punto di ingresso, i file di
   avvio, lo stack e l'heap invece di accettare i valori predefiniti.
3. Elenca i simboli rimasti nel binario e rimuovi quelli servivano solo per il
   debug prima di rilasciarlo.

### Rendi la build riproducibile

1. Fissa la versione della catena di strumenti, le opzioni e l'ambiente in
   un file di manifest che la build legge, così ogni macchina compila allo
   stesso modo.
2. Togli i percorsi assoluti dai file oggetto con il flag di rimappatura dei
   percorsi dei sorgenti e imposta la variabile source date epoch a un valore
   fisso.
3. Compila lo stesso commit due volte su due macchine diverse e confronta i
   checksum dei risultati; devono essere identici.

## Note di sicurezza

- Uno script di build esegue codice arbitrario con le tue autorizzazioni.
  Compila solo da sorgenti che hai letto e di cui ti fidi, e rivedi ogni
  nuovo file di build prima di eseguirlo.
- Una regola make che cancella file può essere attivata da un nome di target
  scritto male. Tieni i comandi distruttivi fuori dalle regole, oppure
  proteggili con una richiesta di conferma, e non eseguire mai un makefile
  non attendibile come amministratore.
- Non disattivare la protezione dello stack, i controlli fortify source o gli
  avvisi solo per far passare una build; ciascuno di questi intercetta un
  difetto reale.
- Le informazioni di debug e le tabelle dei simboli in un binario rilasciato
  rivelano percorsi di file, nomi utente e struttura interna. Rimuovile prima
  della distribuzione.
- Fissa la versione della catena di strumenti e registrala con la build,
  perché un aggiornamento del compilatore può cambiare i risultati in virgola
  mobile, la disposizione delle strutture e l'output dell'ottimizzatore senza
  alcuna modifica al sorgente.
- Controlla lo spazio su disco e il tempo di build; un include runaway o un
  ciclo di dipendenze senza fine può riempire un volume e bloccare la
  pipeline.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- GNU Toolchain Manual (pubblico dominio)
