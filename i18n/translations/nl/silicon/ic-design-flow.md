# Ontwerproces voor geïntegreerde schakelingen

> **Domain:** silicon | **Difficulty:** master | **Safety:** yellow

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Een geïntegreerde schakeling legt de reis af van een geschreven specificatie naar
een GDSII-layout die een fabrikant kan belichten. Het kernprincipe is dat elke
fase een verificatiepoort is: niets gaat verder voordat de vorige fase is
bewezen, omdat de kosten van een defect bij elke stap sterk oplopen, van een
hercompileer tot een volledige herontwerping van de chip. Het ontwerp is dus
vooral een betoog op basis van bewijs, en het artefact dat overblijft is het
archief van wat is gecontroleerd, wanneer, en met welke toolversie.

## Vereisten

- Digitaal ontwerp en Boolealgebra
- Timinganalyse: setup, hold, klokskew en het kritieke pad
- Verilog of VHDL, en de hieronder genoemde simulator- en synthesistools
- Een technology design kit: standaardcellen, LEF en GDEF, GDSII-lagen en
  Liberty-timing
- Versiebeheer met takken en collegiale beoordeling

## Materialen en gereedschap

- Specificatie- en verificatieplannen
- RTL-bronnen, een testbench en een simulator met een golfvormviewer
- Syntheseprogramma met een standaardcelbibliotheek en een Liberty-tijdbestand
- Place-and-route-programma met de design kit, plus statische timinganalyse
- Signoff-tools: lint, CDC, DRC, LVS, en IR-drop- en elektromigratiecontroles
- Git-repository, een issue tracker en een kostenmodel met waferkosten,
  chipoppervlak, chips per wafer en de eenmalige masken- en ontwerpkosten

## Werkwijze

### Specificeren en RTL schrijven

1. Schrijf de specificatie: de interface, de klok, de doorvoer, het
   latencybudget, het vermogensplafond, het chipoppervlakplafond en het
   kostplafond.
2. Schrijf het verificatieplan vóór de RTL, met de assertions, de randgevallen en
   de dekkingsdoelen.
3. Vries de specificatie vast en leg die vast, zodat een latere wijziging
   zichtbaar wordt als een wijziging en niet als een afdrift.
4. Schrijf de RTL, simuleer de testbench tot een slagende regressie en voer lint
   uit op breedteverschillen, onvolledige toewijzingen en meerdere drivers.

### Synthesiseren en plaatsen

1. Stel de klokbeperkingen in, met de periode en de onzekerheid, en voer de
   synthese uit op de doeloppervlakte en -timing.
2. Lees het rapport van het kritieke pad en de vermogensschatting: dynamisch
   vermogen is ongeveer C x V^2 x f plus lekstroom.
3. Plan de floorplan voordat de tool dat doet, met de geheugens, de analoge
   blokken en de I/O-ring, en laat ruimte voor het stroomnet.
4. Voer de place uit, daarna de klokboom, daarna de routering, en controleer na
   elke fase de skew en de routeringscongestie.

### Signoff en tape-out

1. Voer de statische timing uit op de langzame en snelle hoeken, voor setup en
   voor hold.
2. Voer de DRC uit op afstands-, dichtheids- en antenneregels, de LVS tegen het
   schema, en de IR-drop- en elektromigratiecontroles.
3. Sluit elke overtreding af en voer daarna een multi-corner Monte Carlo uit om
   de zeldzame timingfouten bloot te leggen.
4. Exporteer de GDSII, genereer de maskenset, archiveer die met een controlesom en
   de gebruikte toolversies, en splits de bestelling over twee fabrikanten om de
   planning af te dekken.

## Veiligheidsnotities

- De gevaren hier zijn projectgevaren: een tape-out zonder beoordeling verspilt
  de hele maskenset en het geld erachter.
- Bevereilig de broncode en elke intellectuele eigendom van derden, en bewaar de
  ontwerpbestanden in een toegangsbeheerde opslag; de regels voor exportcontrole
  gelden daarvoor.
- Gebruik reproduceerbare builds: leg de toolversies, de scripts en de
  licentiestatus vast, zodat het archief exact kan worden herbouwd.
- Controleer IP van derden voor gebruik, omdat een subtiele fout in een harde
  macro duur is en lastig te vinden.
- Laat een tweede persoon de signoff-checklist tegen de specificatie controleren
  voordat de bestelling wordt geplaatst.
- Archiveer de GDSII en de maskenset; gaat u ze verloren, dan betaalt u opnieuw
  voor de maskenset.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- NIST Semiconductor Reference (publiek domein)
