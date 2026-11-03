# Elettronica di controllo a microonde

> **Domain:** quantum | **Difficulty:** master | **Safety:** yellow

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Tutto ciò che si chiede a un qubit arriva come un impulso a microonde
modellato. Il principio chiave è che un impulso è definito dal suo inviluppo,
dalla sua fase e dalla sua temporizzazione al nanosecondo, quindi l'elettronica
di controllo deve tenere fase e frequenza stabili mentre l'ampiezza viene
variava di un fattore cento. Qualsiasi instabilità nell'elettronica si
trasforma direttamente in errore sul qubit.

## Prerequisiti

- Ingegneria delle microonde: propagazione, miscelazione e impedenza
- Elaborazione digitale dei segnali e modulazione IQ
- Temporizzazione, jitter e anelli ad aggancio di fase
- Messa a terra RF, schermatura e pratica di sicurezza

## Materiali e strumenti

- Un generatore di forma d'onda arbitraria con almeno due canali
- Mixer IQ e un set di filtri passa-basso per ogni canale
- Un oscillatore locale con anello ad aggancio di fase e un riferimento a
  basso rumore
- Cavo coassiale, attenuatori e blocchi DC
- Un wattmetro e un analizzatore di spettro per impostare i livelli

## Procedura

### Pianifica l'insieme di impulsi

1. Elenca ogni operazione di cui il dispositivo ha bisogno: un impulso pi, un
   impulso di lettura, un'eco di Ramsey, una rotazione Z virtuale e il tono di
   reset.
2. Calcola l'ampiezza di ogni impulso dalla frequenza dell'oscillazione di
   Rabi e dalla durata dell'impulso, con la regola che un'area d'impulso di pi
   radianti dà l'inversione completa.
3. Scegli una durata d'impulso che sia un numero intero di cicli di pilotaggio,
   così l'inviluppo non lascia detuning residuo alla fine, e annota i
   numeri di calibrazione di ogni impulso, conservandoli con l'esperimento.

### Costruisci il percorso del segnale

1. Genera l'inviluppo in banda base con una frequenza di campionamento di
   almeno due volte la componente di frequenza più alta in quell'inviluppo.
2. Mischialo con un oscillatore locale alla frequenza del qubit per formare
   il segnale a banda laterale unica.
3. Filtra ogni canale per eliminare la banda laterale indesiderata e la
   perdita della portante, e misura la reiezione sull'analizzatore.
4. Imposta il livello al qubit con un attenuatore calibrato, tipicamente fra
   10 microwatt e 1 milliwatt, e misuralo al qubit e non al generatore.
5. Tieni i cavi corti, usa cavi ad adattamento di fase quando la temporizzazione
   conta e fissa ogni cavo in modo che non possa muoversi fra un'esecuzione e
   l'altra.

### Sincronizza e verifica

1. Deriva ogni canale da un unico clock di riferimento principale e annota
   quel riferimento nei dati di ogni esecuzione.
2. Misura il jitter del percorso di trigger e tienilo sotto l'1% dell'impulso
   più corto.
3. Caratterizza il rumore di fase dell'oscillatore locale e correlalo con la
   defasatura osservata sul qubit.
4. Esegui una scansione di Rabi e una sequenza di Ramsey all'inizio di ogni
   sessione e confronta frequenza e ampiezza con il registro, poi salva i
   campioni grezzi dell'inviluppo accanto ai risultati.

## Note di sicurezza

- Un amplificatore a microonde può erogare decine di milliwatt su un
  dispositivo che muore a un microwatt, quindi parti sempre dall'uscita più
  bassa e aumenta osservando la potenza riflessa.
- La potenza trasmessa a 5 GHz causa ustioni e riscalda i tessuti internamente;
  non puntare mai un'antenna verso una persona e considera il connettore di
  uscita sotto tensione.
- Un connettore allentato o un cavo danneggiato può fare arco e provocare un
  incendio, quindi usa connettori con coppia limitata e verifica ogni cavo
  sotto carico.
- Un errore di messa a terra mette RF sulla calza del cavo, che poi cerca un
  percorso attraverso il rack e può danneggiare lo strumento.
- Blocchi DC e tee di polarizzazione devono essere adatti alla frequenza; un
  normale blocco DC va in arco con potenze a microonde.
- Non cambiare mai un cavo su un amplificatore alimentato; alcuni
  amplificatori richiedono una terminazione specifica prima di partire.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- NIST Quantum Initiative Reference (pubblico dominio)
