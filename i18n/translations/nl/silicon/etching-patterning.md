# Natte en droge etsing

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Etsen verwijdert materiaal selectief, zodat het resistpatroon in de film eronder
wordt overgenomen. Twee getallen bepalen of een structuur overblijft: de
selectiviteit, de etssnelheid van de laag gedeeld door die van het masker, en de
anisotropie, de verhouding van verticale naar laterale verwijdering. Nat etsen is
goedkoop en isotroop, terwijl droog plasma-etsen gericht en nauwkeurig is, dus de
keuze volgt de geometrie en niet het gemak.

## Vereisten

- Fotolithografie en masker maken (resistpatronen en maskers maken)
- Dunne-filmdepositie voor harde maskers en antireflectiecoatings
- Waferreiniging en betrouwbare hechting van het masker aan het oppervlak
- De etssnelheden- en selectiviteitstabellen van het apparaat zelf raadplegen

## Materialen en gereedschap

- Natte bank: verwarmde baden, temperatuurregeling en een centrifuge-spoeldroger
- Etsmiddelen: fluorwaterstofzuur, salpeterzuur, azijnzuur, kaliumhydroxide,
  tetramethylammoniumhydroxide en gebufferd oxide-etsmiddel
- RIE- of ICP-etser met een RF-generator op 13.56 MHz, een matchbox en een pomp
- Procesgassen: CF4, CHF3, SF6, Cl2 en O2, met een gereinigde afvoer
- Ellipsometer, profielmeter en optische microscoop voor metingen
- PTFE- en polyetheencontainers, wafertangen en een gelaatsscherm

## Werkwijze

### De selectiviteit plannen

1. Stel de beoogde diepte en de kritieke afmeting voor de laag vast.
2. Zoek de etssnelheid van de film en van het masker op in uw eigen apparaat en
   chemie; gepubliceerde snelheden gaan niet zonder meer over tussen machines.
3. Vereis een selectiviteit van minstens 10:1 voor een film van 100 nm onder een
   resist van 1 um, en voeg een hard masker toe wanneer de resist het etsen
   niet overleeft.
4. Plan op het laadeffect: verwacht dat de etssnelheid daalt naarmate het open
   oppervlak groter wordt, dus snijd een proefwafer met zowel een klein als een
   groot patroon.

### Natte etsing

1. Reinig de wafer, droog die af en breng de resist of het harde masker aan.
2. Ets silicium in fluorwaterstof-, salpeter- en azijnzuur bij 60-80 °C gedurende
   20-60 s, of ets in kaliumhydroxide bij 80 °C voor anisotrope verwijdering met
   een selectiviteit van meer dan 100:1 tegen siliciumdioxide.
3. Spoel na in gedemineraliseerd water en droog met stikstof.
4. Compenseer de ondersnijding door het masker aan elke kant met de etsdiepte te
   vergroten, en behoud het (111)-vlak door de hoeken af te dekken met een
   uitstapje van minstens 1.41 keer de bedoelde afmeting.

### Droge etsing

1. Laad de wafer in de etser, trek vacuüm en conditioneer de kamer met een
   reiniging op zuurstof en fluorocarbon.
2. Stel de gasstroom, de druk (ongeveer 10-50 mTorr voor RIE en 1-10 mTorr voor
   ICP), het bronvermogen (300-600 W voor silicium) en het biasvermogen voor de
   doelfilm in.
3. Ets tot de beoogde diepte en stop op een eindpuntignaal: een optisch
   interferentie-eindpunt, of de daling van de siliciumemissielijn.
4. Meet de diepte en het zijwandprofiel op een controlewafer, controleer op
   inkeping aan de voet van een brede structuur, en leg de snelheid en de
   selectiviteit vast voor de volgende run.

## Veiligheidsnotities

- **Rood gevaar:** fluorwaterstofzuur is dodelijk bij huidcontact en bij
  inademing, en het aantast bot. Hanteer het alleen met de juiste opleiding,
  begeleiding en uitrusting, met calciumgluconaatgel aan de werkbank en een
  buddy-systeem.
- **Rood gevaar:** bewaar of vervoer fluorwaterstofzuur nooit in glas; het
  aantast het glas en lekt erdoorheen.
- Het mengsel van fluorwaterstof-, salpeter- en azijnzuur vormt stikstofdioxide;
  werk in een zuurkast en inhaleer de damp nooit.
- Plasma-etsgassen zijn giftig en verstikkend: de chloorchemie vormt
  waterstofchloride en de fluorchemie vormt waterstoffluoride.
- De radiofrequente bron en het plasma zijn dodelijk bij aanraking; houd de
  vergrendelingen en de gaswisser aan zolang er gas stroomt.
- Etsbaden moeten zijn gelabeld met de samenstelling en de datum, en een bad dat
  met silicium in aanraking is gekomen mag nooit worden teruggezet in een
  glasreiniging.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- NIST Semiconductor Reference (publiek domein)
