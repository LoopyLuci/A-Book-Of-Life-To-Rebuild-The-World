# Kwantumfoutcorrectie

> **Domain:** quantum | **Difficulty:** master | **Safety:** green

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Kwantumfoutcorrectie is de enige route naar een machine die lang genoeg rekent
om ertoe te doen, want geen enkele fysieke qubit is goed genoeg om alleen een
bruikbaar algoritme te draaien. Het kernprincipe is dat de redundantie moet
worden afgestemd op het type fout: een klassiek syndromebit detecteert een
bitflip, een ander syndromebit detecteert een faseflip, en een ancilla die de
gezamenlijke pariteit meet detecteert beide. Een code met afstand d corrigeert
floor((d-1)/2) fouten en detecteert d-1, en onder een drempel-foutpercentage
leveren de extra qubits een logische foutrate op die lager is dan de fysieke.

## Vereisten

- Kwantumpoorten, de Pauli-groep en het stabilisatorformalisme
- Dichtheidsmatrices, de blochbol en ruiskanalen
- Elementaire coderingstheorie voor de klassieke codes binnen kwantumcodes
- Een werkende klassieke simulator en een programma om schakelingen te tekenen

## Materialen en gereedschap

- Een simulator voor toestandsvectoren en een stabilisatorsimulator voor kleine
  codes
- Een oplosser voor dichtheidsmatrices voor het ruismodel van één ronde
- Gegevens uit gerandomiseerde benchmarking voor het platform in onderzoek
- Een referentie-implementatie van een decoder met minimale perfecte matching
- Tabellen van de logische foutrate tegen code-afstand en fysieke fout
- Een rekenblad of script voor de fysieke en logische foutbudgetten

## Werkwijze

### De fout indelen

1. Scheid bitflip- (X), faseflip- (Z) en gecombineerde fouten (Y), en merk op dat
   een depolariserend kanaal alle drie tegelijk voortbrengt.
2. Koppel een ruismodel aan elke poort en begin met een depolariserende snelheid
   van 1e-3 voor één qubit en 1e-2 voor twee qubits, wat realistisch is voor
   supergeleidende qubits.
3. Neem de meetfout op in het model, want een foutieve syndrome-uitreading kan een
   datafout veroorzaken die er niet was.

### De code kiezen

1. Stel de beoogde logische foutrate en het aantal schakelcycli vast; het product
   is het aantal onafhankelijke kansmomenten om te falen.
2. Vergelijk codefamilies: de Shor-code met negen qubits corrigeert één fout met
   negen qubits, de Steane-code corrigeert één fout met zeven, en de
   oppervlaktecode gebruikt veel meer qubits om veel meer fouten te corrigeren.
3. Controleer de Singleton-grens, n - k >= 2(d-1), en onthoud dat een
   subsysteemcode minstens twee kopieën nodig heeft voor een logische poort op
   twee qubits.

### De decoder modelleren en de drempel bepalen

1. Bereken het syndrome voor elke stabilisatorronde en zoek de fout met de
   kleinste gewicht die het verklaart, met een decoder met minimale perfecte
   matching voor de oppervlaktecode.
2. Houd de latentie van de decoder onder de syndromerondetijd, ongeveer 1
   microsecondum op supergeleidende hardware, anders komt de correctie te laat
   om de volgende fout te voorkomen.
3. Doorloop een reeks afstanden, d = 5, 9, 13 en 17, en bepaal het omslagpunt
   waar de logische foutrate niet verder daalt; verwacht ongeveer 1% voor
   depolariserende ruis en ongeveer 10% voor wisruis.

### De overhead begroten

1. Schat het benodigde aantal fysieke qubits; bij een fysieke foutrate van 1e-3
   en een beoogde logische foutrate van 1e-12 kunt u ongeveer 1e4 fysieke qubits
   per logische qubit verwachten.
2. Tel de syndrome-ancilla's erbij, één per stabilisator, dus een oppervlaktecode
   met afstand d heeft ongeveer d in het kwadraat aan dataqubits en d in het
   kwadraat min één ancilla's.
3. Tel de qubits die wachten terwijl de rest rekent, en leg de afstand, de overhead
   en de aangenomen fysieke foutrate vast bij het resultaat.

## Veiligheidsnotities

- Dit is een analyseopgave, maar de cijfers bepalen of een machine de moeite
  waard is om te bouwen: accepteer nooit een geclaimde logische foutrate die niet
  is gemeten op het ruismodel van de echte hardware.
- Een decoder die trager is dan de syndromeronde verslechtert de logische
  foutrate stilletjes, dus meet de latentie van de decoder op de doelmachine.
- Gebruik nooit een decoder of hardwareconfiguratie uit een ruisvrije simulatie;
  het foutbudget geldt alleen op het echte ruismodel.
- Houd de klassieke decoder uit de buurt van de kryogene trap en scherm de
  besturingshardware af, zodat een fout in de decoder niet op de qubittoestand kan
  inwerken.
- Leg het foutbudget en de code-afstand vast bij de kalibratiegegevens, want een
  apparaat dat opnieuw is gekalibreerd zonder het budget te controleren, ligt
  mogelijk niet meer onder de drempel.
- Behandel elke claim van fouttolerantie zonder gemeten drempel als onbewezen, en
  zeg dat zo in de beschrijving.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- NIST Quantum Initiative Reference (publiek domein)
