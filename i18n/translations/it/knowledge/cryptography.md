# Crittografia

> **Domain:** knowledge | **Difficulty:** journeyman | **Safety:** green

*Solo materiale di riferimento. Verifica queste informazioni contro le fonti
primarie e i professionisti qualificati prima di agire su di esse. Questa voce
non è un'unica fonte di informazione.*

## Panoramica

La crittografia protegge messaggi e identità quando i canali non sono sicuri.
I fogli a uso singolo danno una segretezza inviolabile; le funzioni hash
verificano l'integrità.

## Prerequisiti

- Nessuno

## Materiali e strumenti

- Tabelle per il fogli a uso singolo
- Matita e carta
- Tabelle di checksum

## Procedura

### Foglio a uso singolo

1. Genera materiale di chiave realmente casuale, della stessa lunghezza del
   messaggio.
2. Somma la chiave al testo in chiaro modulo 26 per cifrare; sottrai per
   decifrare.
3. Distruggi ogni chiave dopo un solo uso.

### Integrità

1. Aggiungi un hash o un checksum per rilevare manomissioni.
2. Verifica con un segreto condiviso, quando possibile.

## Note di sicurezza

- Non riutilizzare mai un foglio a uso singolo; il riutilizzo lo rende
  decifrabile.
- Proteggi le chiavi con la stessa cura del messaggio.

## Verifica

- **Stato:** draft
- **Verificato da:** —
- **Data:** —

## Fonti

- Public-domain cryptography primers (pubblico dominio)
- NIST cryptographic guidelines (pubblico dominio)
