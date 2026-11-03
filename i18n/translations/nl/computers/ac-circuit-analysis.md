# Analyse van wisselstroomcircuits en impedantie

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Bij wisselstroom lopen spanning en stroom niet meer gelijk op en neer, waardoor
de eenvoudige verhouding van spanning over stroom geen bruikbaar getal meer is.
Het kernprincipe is dat elk element wordt vervangen door zijn impedantie, een
complex getal met een deel in weerstand en een deel in reactantie, en dat daarna
precies dezelfde stroomkringsvergelijkingen worden opgelost als bij gelijkstroom.
De reactantie wordt bepaald door de frequentie, en daarom kan een schakeling die
in stationaire toestand zich op een bepaalde manier gedraagt bij 50 Hz volstrekt
anders zijn.

## Vereisten

- Analyse van gelijkstroomcircuits voor de wetten van Kirchhoff en de regels
  voor serie en parallel
- Complexe getallen in rechthoekige en polaire vorm
- De sinus- en cosinusfunctie, fase en faseverschil
- Basiskennis van differentiëren en integreren, voor de reactieve elementen
- Het verband tussen de RMS-waarde, de piekwaarde en de piek-tot-piekwaarde

## Materialen en gereedschap

- Een functiegenerator en een oscilloscoop
- Een benchvoeding en een digitale multimeter met een condensatorbereik
- Weerstanden, condensatoren en spoelen uit de E12- en E24-reeks
- Een decadeweerstandsdoos, of een set waarden voor de resonantie- en
  filterproeven
- Koperdraad en een spoelvorm voor het maken van een proefspoel
- Een scheidingstransformator voor elk werk aan het lichtnet

## Werkwijze

### Het circuit omzetten naar fasoren

1. Vervang elke weerstand door R en elke condensator en spoel door zijn
   reactantie: X_L = 2 x pi x f x L en X_C = 1 / (2 x pi x f x C).
2. Schrijf de impedantie van elk element in rechthoekige vorm: Z_R = R,
   Z_L = j X_L en Z_C = -j X_C.
3. Tel de impedanties in serie op en combineer de takken in parallel met
   dezelfde regels als bij gelijkstroom, houd de j-termen gescheiden en zet
   daarna het resultaat om in polaire vorm: de grootte is de wortel van R^2
   plus X^2 en de hoek is de boogtangens van X over R.

### Het wisselstroomnetwerk oplossen

1. Pas de wetten van Kirchhoff toe op het impedantienetwerk en los de fasoren
   voor stroom en spanning op.
2. Zet de fasorantwoorden terug naar het tijdgebied en onthoud dat de
   RMS-waarde van een sinus gelijk is aan de piekwaarde gedeeld door 1.414.
3. Controleer het resultaat aan het vermogen: het werkelijk vermogen is
   P = V x I x cos(phi), het blinde vermogen is Q = V x I x sin(phi) en het
   schijnbaar vermogen is S = V x I in voltampère.

### De resonantie bepalen

1. Stel de reactantenies gelijk en los de resonantiefrequentie op:
   f0 = 1 / (2 x pi x sqrt(L x C)).
2. Meet de frequenties bij halve vermogen en bereken de kwaliteitsfactor
   Q = f0 / (f2 - f1), en controleer die met de uitdrukking voor
   sqrt(L / C) gedeeld door de seriële weerstand.
3. Merk op dat de stroom bij resonantie maximaal is en dat de spanning over de
   condensator Q keer de voedingsspanning kan zijn.

### Een filter ontwerpen

1. Stel de afsniffrequentie in uit de specificatie, bereken de weerstand voor
   een eenvoudig RC-laagdoorlaatfilter, R = 1 / (2 x pi x f x C), en bouw het.
2. Meet de respons bij 0.1, 1 en 10 keer de afsniffrequentie en controleer dat
   de uitgang per decade met 20 dB is teruggevallen.
3. Bevestig de faseverschuiving bij de afsniffrequentie, die 45 graden is bij
   een filter van de eerste orde, en voeg een tweede trap toe als de demping
   niet steil genoeg is.

## Veiligheidsnotities

- Netspanning is dodelijk. Behandel elke schakeling die op de voeding is
  aangesloten als levensgevaarlijk en werk er alleen aan met de juiste opleiding,
  begeleiding en uitrusting, met een scheidingstransformator.
- De stroom die een hart stopt is klein: ongeveer 0.5 mA is de
  waarnemingsdrempel, 10 mA is de loslaatdrempel, 30 mA kan de ademhaling
  stopzetten en 50 mA kan ventrikelfibrilleren veroorzaken.
- Een geladen condensator houdt zijn energie vast nadat de voeding is
  uitgeschakeld, omdat de impedantie van de meter veel te hoog is om hem te
  ontladen; gebruik een ontlaadweerstand en meet de spanning voordat u een
  knoop aanraakt.
- Een resonantieschakeling kan een hoge spanning over de condensator opbouwen,
  en een terugkoppeling of een boostconverter kan honderden volt op een knoop
  zetten die er laagspannings uitziet.
- Houd de uitgang van de functiegenerator en de uitgangen van de benchvoeding
  van elkaar gescheiden en verbind nooit een signaalbron over een
  voedingsuitgang.
- Controleer de spannings- en rimpelstroomwaarden van de condensatoren en
  onthoud dat de spanning over een condensator in een resonantieschakeling veel
  hoger kan zijn dan de voedingsspanning.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- OpenStax University Physics (CC BY)
