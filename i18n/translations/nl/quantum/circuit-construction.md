# Bouw van kwantumcircuits

> **Domain:** quantum | **Difficulty:** apprentice | **Safety:** green

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Een kwantumcircuit is een geschreven recept: een lijst van poorten op een lijst
van qubits, gevolgd door metingen. Het kernprincipe is dat het circuit dat u
schrijft niet het circuit is dat draait, omdat de compiler het eerst moet
afbeelden op de poorten en verbindingen die de hardware daadwerkelijk heeft. Die
vertaling kunnen lezen en de twee circuits dicht bij elkaar houden is de
praktische vaardigheid.

## Vereisten

- Complexe vectoren en matrixvermenigvuldiging
- De blochbol en de poorten op één qubit
- Basiskennis van Python of een andere scripttaal
- De regels van een kwantumcircuit: geen klonen, en meten vernietigt

## Materialen en gereedschap

- Een kwantum-SDK zoals Qiskit, Cirq of Braket
- Een simulator voor toestandsvectoren voor kleine circuits, tot ongeveer 20
  qubits
- Een hardwarebackend en de gepubliceerde kalibratiegegevens
- Een notitieboek of bestand met het circuit en de verwachte uitvoer
- Een lokale kopie van het ruismodel voor het doelapparaat

## Werkwijze

### Het circuit schrijven

1. Formuleer de vraag die het circuit beantwoordt voordat u één poort schrijft.
2. Bouw het circuit in lagen, steeds één poort tegelijk, en teken het om te
   controleren of de draden de qubits zijn die u bedoelde.
3. Houd het aantal poorten klein en kies liever één verstrengeld paar dan
   meerdere die elkaar overlappen.
4. Voeg de metingen als laatste toe en onthoud dat vroeg meten de toestand voor
   de rest van het circuit vernietigt.

### Het compileren

1. Stuur het circuit door de transpiler voor de doelbackend en laat die de
   native basis en de mapping kiezen.
2. Bekijk de indeling die de compiler heeft gekozen: bij een raster- of
   heavy-hex-connectiviteit worden ver uit elkaar liggende qubits verbonden met
   swap-poorten die extra fouten toevoegen.
3. Kies zelf de beginindeling wanneer het circuit een natuurlijke geometrie heeft
   en vergelijk de poortaantallen van beide keuzes.
4. Stel het optimalisatieniveau in op 1 of 2, noteer welk niveau de bewaarde run
   opleverde en controleer de geplande pulsitijden, omdat de compiler inactieve
   tijd kan invoegen waarin de qubit drift.

### Uitvoeren en het resultaat lezen

1. Voer het circuit veel keer uit en tel de uitkomsten; één meting vertelt je
   bijna niets.
2. Vergelijk het histogram met de ideale simulatie en geef het verschil als getal
   aan, niet als indruk.
3. Controleer de jobmetadata op de kalibratiedatum van het apparaat en weiger
   een getal te rapporteren van een apparaat dat niet gekalibreerd is.
4. Bewaar het circuit, de gecompileerde versie, de seed en de tellingen samen,
   voer opnieuw uit met een andere seed en bevestig dat de statistieken
   overeenkomen voordat u enige conclusie trekt.

## Veiligheidsnotities

- Een simulator kan het geheugen van de machine uitputten: een toestandsvector
  vraagt 16 bytes per qubit, dus 30 qubits vraagt 16 terabytes; gebruik in dat
  geval de stabilisator- of dichtheidsmatrijsmethode.
- Stuur nooit een circuit dat een geheime sleutel in zijn poorten bevat naar een
  gedeeld apparaat zonder het eerst te beoordelen, want een circuit onthult veel
  over de gegevens waaruit het is opgebouwd.
- Rekenen op hardware kost wachttijd en koelt de machine af; bundel de circuits
  dus en laat het apparaat vrij voor anderen.
- Meten is destructief, en een circuit dat vroeg meet en de qubit daarna
  hergebruikt geeft een verkeerd antwoord in plaats van een foutmelding.
- Rapporteer geen hardwareresultaat zonder apparaatnaam, kalibratiedatum en aantal
  metingen, want die zijn later niet meer te achterhalen.
- Een simulator zonder ruis toont zonder problemen een perfect resultaat voor een
  circuit dat niet kan draaien; geef daarom altijd aan welke van beide de
  getallen leverde.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- NIST Quantum Initiative Reference (publiek domein)
