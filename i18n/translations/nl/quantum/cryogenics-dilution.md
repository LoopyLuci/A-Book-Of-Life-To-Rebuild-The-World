# Kryogenie en verdunningskoeling

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Een verdunningsrefrigerator koelt een monster af tot enkele millikelvin door
supervloeibaar en normaal helium te mengen, en hij houdt die temperatuur alleen
vast als de volledige warmtebelasting wordt gehaald. Het kernprincipe is dat
elke kabel, elke draad en elk oppervlak een lek in de isolatie is, zodat het
ontwerp in feite neerkomt op het tellen van warmte in microwatten en die
vervolgens afvoeren. Het monster is het kleinste deel van het systeem; de
leidingen, de filtering en de afscherming bepalen of de meting mogelijk is.

## Vereisten

- Basiskennis van kryogene techniek en het fasediagram van helium
- Suprvloeibaarheid en de verdunning van helium-3 in helium-4
- Microgolftechniek en het ontwerp van verzwakkings- en filterketens
- Vacuümpraxis, lektesten en veilig omgaan met kryogene stoffen

## Materialen en gereedschap

- Een verdunningsrefrigerator met mengkamer en destilleerruimte
- Een kryogene overvoerleiding en een vacuümpompset met een koude vangst
- Vacuümbestendige coaxkabel, SMA- en SMP-connectors en koelvinnen
- Een keten van microgolfverzwakkers en een laagdoorlaatfilter per signaallijn
- Een supergeleidende magneet, een set thermometers en een afgeschermde ruimte

## Werkwijze

### De warmtebelasting plannen

1. Noteer elke lijn die van kamertemperatuur naar de mengkamer loopt en tel ze.
2. Bereken de geleidingslekkage door elke kabel uit de warmtegeleidbaarheid van
   het materiaal, met Q = k A dT gedeeld door L, en merk op dat één
   niet-verzwakte coaxlijn meer dan een milliwatt naar de 4 K-trap kan voeren.
3. Bereken de stralingsbelasting door elke afscherming met
   Q = sigma A (T_hot tot de vierde min T_cold tot de vierde), waarbij sigma
   5.67e-8 W per vierkante meter per kelvin tot de vierde is.
4. Tel de koelvraag van de versterkers erbij, vergelijk het totaal met het
   koelvermogen in de mengkamer, doorgaans 10 tot 100 microwatten bij 10 mK, en
   houd minstens 30 procent marge.

### De bekabeling voorbereiden

1. Sluit elke coaxlijn af met een verzwakker bij de 50 K-trap, de 4 K-trap, de
   destilleerruimte en de mengkamer, ongeveer 10 dB per trap.
2. Plaats bij de 4 K-trap een laagdoorlaatfilter voor elke signaallijn, met een
   afsnijfrequentie rond 5 GHz, en een veel lagere afsnijfrequentie van 700 MHz
   of lager op elke DC-biaslijn.
3. Anker elke lijn aan de trappen met koperen of aluminiumen vlecht, zodat de
   warmte daar stopt.
4. Vakuümtest de hele lijn en de doorvoer en sluit de vacuümruimte nooit af op
   een koude lijn die niet op lekkage is gecontroleerd.

### Koelen en controleren

1. Pomp helium en vacuümpompen in de voorgeschreven volgorde en onderbreek een
   opwarmcyclus die al vacuüm heeft bereikt nooit.
2. Volg de temperaturen van de trappen en het heliumniveau, en leg de
   stabilisatietijd en de eindtemperatuur vast.
3. Sluit de stralingsafscherming pas nadat de basistemperatuur stabiel is,
   breng dan het monster over en bevestig dat de temperatuur bij de monsterhouder
   overeenkomt met de thermometer.
4. Leg de basistemperatuur, de temperaturen van de trappen en de ruisvloer van
   de microgolf voor elke afkoeling samen vast.

## Veiligheidsnotities

- Vloeibaar helium zet bij opwarmen enorm uit en kan een afgesloten volume doen
  barsten, dus elk koud volume heeft een ontlastingspad nodig en
  ontlastingsmiddelen mogen nooit worden geblokkeerd of afgesloten.
- Vloeibaar helium en vloeibare stikstof veroorzaken koudebrandwonden en kunnen
  de zuurstof uit een ruimte verdringen; werk in een goed geventileerde ruimte
  met een ruimtemonitor en werk nooit alleen met een kryogene stof.
- Een kryogene overvoerleiding die is geopend kan vloeibaar helium in een
  vacuümlijn injecteren en een implosie veroorzaken; ontlast een koude lijn
  nooit naar de atmosfeer zonder de bijbehorende procedure te volgen.
- Zuurstof die op een koud oppervlak condenseert maakt dat oppervlak broos en
  elke kryogene koppeling een fragmentrisico; gebruik de juiste metalen
  afdichtingen en draai een koude verbinding nooit vast.
- Een supergeleidende magneet slaat energie op en kan zonder waarschuwing
  uitschakelen, waarbij een groot veld vrijkomt en het kryogeen verdampt; stel
  de rampsnelheidsgrenzen in en laat hem nooit onbeheerd ingeschakeld.
- Een vacuümstoring of terugstromende pompolie kan een koude trap
  verontreinigen en de proef zonder zichtbare waarschuwing vernietigen.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- NIST Cryogenics Guidance (publiek domein)
