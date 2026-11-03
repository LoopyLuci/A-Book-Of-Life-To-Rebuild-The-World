# Microgolfbesturing

> **Domain:** quantum | **Difficulty:** master | **Safety:** yellow

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Alles wat een qubit gevraagd wordt komt binnen als een gevormde microgolfpuls.
Het kernprincipe is dat een puls wordt bepaald door zijn omhullende, zijn fase
en zijn timing tot op de nanoseconde, dus de besturingselektronica moet fase en
frequentie stabiel houden terwijl de amplitude honderdvoudig wordt doorlopen. Alles
wat in de elektronica jittert, komt rechtstreeks terug als een fout in de qubit.

## Vereisten

- Microgolftechniek: voortplanting, mixing en impedantie
- Digitale signaalverwerking en IQ-modulatie
- Klokken, jitter en fasevergrendelde loops
- RF-aarding, afscherming en veiligheidspraktijk

## Materialen en gereedschap

- Een willekeurige golfvormgenerator met minstens twee kanalen
- IQ-mengers en een laagdoorlaatfilterset per kanaal
- Een lokale oscillator met fasevergrendelde loop en een ruisarme referentie
- Coaxkabel, verzwakkers en DC-blokken
- Een vermogensmeter en een spectrumanalysator voor het instellen van de niveaus

## Werkwijze

### De pulsetoestand plannen

1. Noteer elke bewerking die het apparaat nodig heeft: een pi-puls, een
   uitleespuls, een Ramsey-echo, een virtuele Z-rotatie en de resettoon.
2. Bereken de amplitude van elke puls uit de Rabi-oscillatiefrequentie en de
   pulslengte, met de regel dat een pulsoppervlak van pi radialen volledige
   inversie geeft.
3. Kies een pulslengte die een geheel aantal aandrijfcycli is, zodat de omhullende
   aan het einde geen rest-detuning laat, en schrijf de kalibratiegetallen van elke
   puls op en bewaar die bij de proef.

### Het signaalpad opbouwen

1. Genereer de basisbandomhullende met een samplingsfrequentie van minstens
   tweemaal de hoogste frequentiecomponent in die omhullende.
2. Meng die met een lokale oscillator op de qubitfrequentie om het
   enkelzijbandige signaal te vormen.
3. Filter elk kanaal om de ongewenste zijband en de carrierlekkage te verwijderen,
   en meet de onderdrukking op de analysator.
4. Stel het niveau bij de qubit in met een gekalibreerde verzwakker, doorgaans
   tussen 10 microwatt en 1 milliwatt, en meet het bij de qubit en niet bij de
   generator.
5. Houd de kabels kort, gebruik fasegematchte kabel waar de timing van belang
   is, en bevestig elke kabel zodat die niet tussen metingen kan bewegen.

### Synchroniseren en controleren

1. Leid elk kanaal af van één masterreferentieklok en leg die referentie bij elke
   meting in de data vast.
2. Meet de jitter van het triggergedrag en houd die onder 1 procent van de
   kortste puls.
3. Bepaal de faseruis van de lokale oscillator en correleer die met de
   decoherensie die op de qubit wordt gezien.
4. Voer aan het begin van elke sessie een Rabi-sweep en een Ramsey-sequentie uit
   en controleer de frequentie en de amplitude tegen het logboek, en sla de ruwe
   omhullende-samples naast de resultaten op.

## Veiligheidsnotities

- Een microgolfversterker kan tientallen milliwatt in een apparaat sturen dat bij
  een microwatt al sterft, dus begin altijd op het laagste uitgangsvermogen en
  stap op terwijl u het reflectievermogen volgt.
- Uitgestraald vermogen op 5 GHz veroorzaakt brandwonden en verhit het weefsel
  van binnen; richt nooit een antenne op een persoon en behandel de
  uitgangsaansluiting als onder spanning.
- Een losse connector of een beschadigde kabel boogt over en kan brand
  veroorzaken, dus gebruik connectors met een aandraaikrachtbegrenzing en
  controleer elke kabel onder belasting.
- Een aardfout zet RF op de kabelafscherming, die dan een weg door de rack zoekt
  en het instrument kan beschadigen.
- DC-blokken en bias-T-stukken moeten voor de frequentie geschikt zijn; een
  gewoon DC-blok slaat bij microgolfvermogen over.
- Verwissel nooit een kabel op een ingeschakelde versterker; sommige versterkers
  hebben een specifieke afsluiting nodig voordat ze starten.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- NIST Quantum Initiative Reference (publiek domein)
