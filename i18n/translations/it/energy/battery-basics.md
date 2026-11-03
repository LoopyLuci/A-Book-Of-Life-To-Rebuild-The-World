# Le basi delle batterie

> **Domain:** energy | **Difficulty:** journeyman | **Safety:** red

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

Le batterie immagazzinano energia elettrica in forma chimica. Il piombo-acido
è la chimica più ricostruibile; lo ione-litio è più denso ma più difficile da
realizzare da zero.

## Prerequisiti

- [Fusione dei metalli](../../../../domains/materials/metal-smelting.md)
- [Chimica](../../../../domains/materials/chemistry.md)

## Materiali e strumenti

- Piastre di piombo (griglia + materiale attivo)
- Acido solforico (30% H₂SO₄)
- Contenitore (plastica o gomma dura)
- Separatori (gomma porosa, stuoio di vetro)
- Terminali

## Procedura

### Elemento al piombo-acido (2 V per elemento)

1. Getta le griglie di piombo; pastella con ossido di piombo (positivo) e
   piombo spugnoso (negativo).
2. Impila le piastre alternandole con i separatori.
3. Salda le linguette ai terminali.
4. Riempì con acido solforico al 30%.
5. **Carica di formazione:** carica lenta per 24 ore per convertire le
   paste.

### 6 elementi = batteria da 12 V

- 6 elementi in serie → 12 V nominali.
- Capacità: Ah = area della piastra × numero di piastre.

### Carica

1. **Carica bulk:** a corrente costante fino a 14.4 V.
2. **Assorbimento:** a tensione costante di 14.4 V finché la corrente scende
   al 3% della capacità.
3. **Mantenimento:** 13.6 V per conservare la carica.

### Manutenzione

- Riempi con acqua distillata ogni mese.
- Esegui l'equalizzazione ogni 1–3 mesi (15.5 V per 2 ore).
- Non scaricare mai sotto il 50% (12.1 V).
- Mantieni i terminali puliti e ingrassali.

### Altre chimiche

- **NiFe (Edison):** 1.2 V/elemento; quasi indistruttibile; bassa
  efficienza.
- **NiCd:** 1.2 V/elemento; cadmio tossico.
- **LiFePO₄:** 3.2 V/elemento; sicura; richiede un BMS.

## Note di sicurezza

- **Pericolo rosso:** L'acido solforico ustiona. Il piombo è neurotossico.
  Indossa guanti, occhiali, grembiule. Lavora all'aperto.
- **Idrogeno esplosivo** durante la carica — ventila.
- Non cortocircuitare mai i terminali; non invertire mai la polarità.
- Smaltisci correttamente piombo e acido.

## Verifica

- **Stato:** peer-reviewed
- **Data:** 2026-05-01

## Fonti

- US DOE Battery Handbook (pubblico dominio)
- US Army Battery Manual (pubblico dominio)
