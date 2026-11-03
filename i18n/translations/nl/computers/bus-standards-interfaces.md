# Busstandaarden en signaalinterfaces

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Een bus is een afspraak over draden: wat een logisch niveau betekent, wie de lijn
mag aansturen en hoe een ontvanger weet dat een bit geldig is. Het kernprincipe is
dat elke busstandaard dezelfde drie problemen oplost, uitgangssterkte, klokken en
arbitrage, en dat een apparaat dat er een van drie negeert niet netjes maar met
tussenpozen uitvalt. De drie interfaces hieronder dekken het meeste af van wat een
werkplaats moet verbinden.

## Vereisten

- Digitale logica: push-pull, open-drain, pull-ups en logische niveaus
- Een datasheet met pintabel en een timingdiagram kunnen lezen
- Seriële framing: baudrate, databits, pariteit en stopbits
- Basisvaardigheden in solderen en het gebruik van een multimeter of logische
  analyser

## Materialen en gereedschap

- Een logische analyser die UART, I2C en SPI kan decoderen
- Een microcontroller-ontwikkelbord en een paar breakoutborden
- Pull-up-weerstandpakketten, 2 kOhm tot 10 kOhm voor I2C bij 400 kHz
- Serieweerstanden van 22 tot 33 Ohm en 120 Ohm-afsluitingen voor lange lijnen
- Een benchvoeding, een multimeter en een oscilloscoop

## Werkwijze

### UART

1. Spreek eerst het frame af: 8 databits, geen pariteit en 1 stopbit, wat 10 bits
   op de lijn per byte geeft.
2. Stel beide kanten op dezelfde baudrate in en onthoud dat een fout van 2 procent
   meestal tolerabel is terwijl 5 procent dat niet is.
3. Verbind zenden met ontvangen en ontvangen met zenden, en verbind de massa's met
   elkaar; een gemeenschappelijke massa is het deel dat het vaakst wordt
   weggelaten.
4. Bevestig dat de rusttoestand logisch 1 is en dat een logisch 0 het startbit
   markeert, controleer daarna de logische niveaus aan beide kanten voordat u de
   data vertrouwt en plaats een niveauverschuiver voor een verbinding van 5 V
   naar 3.3 V.

### I2C

1. Trek SDA en SCL via 2 kOhm tot 10 kOhm omhoog naar de voedingsspanning, en
   controleer de stijgtijd tegen de buscapaciteit voordat u de klok verhoogt.
2. Adresseer de apparaten met een 7-bits adres, en onthoud dat veel onderdelen
   twee aparte adressen gebruiken voor hun twee voedingsspanningen.
3. Lees de adres- en registervolgorde uit het datasheet, bevestig beide op de
   analyser en vertrouw pas daarna de reeks.
4. Controleer de setup- en holdtijden in het timingdiagram, houd de klok bij een
   eerste test onder 100 kHz, en reset een vastgelopen bus met een puls van
   negen klokken in plaats van SDA laag te houden.

### SPI

1. Sluit de klok, de master-ingang, de master-uitgang en de chipselectie aan, en
   geef elk apparaat zijn eigen selectielijn.
2. Begin in modus 0, met de klok in rust laag en data bemonsterd op de stijgende
   flank, en controleer vervolgens de modus tegen het datasheet.
3. Houd de klok bij een eerste test onder 1 MHz, verkort de draden als de flanken
   op de analyser afgerond ogen, en plaats 22 tot 33 Ohm in serie met de klok-
   en datalijnen om de rilling te dempen.
4. Lees de full-duplex-timing in het datasheet, inclusief de vertraging tussen
   het actief worden van de chipselectie en de eerste klokflank.

## Veiligheidsnotities

- Logische analysers en veel ontwikkelborden koppelen hun massa aan de aarde van
  de host, dus meten aan een hoogspannings- of netschakeling kan de analyser
  vernielen en brand veroorzaken.
- Controleer de voedingsspanningen van beide kanten voordat u een bus
  aansluit; een 5 V-randapparaat dat een 3.3 V-ingang aanstuurt kan de
  controller vernielen.
- Meet nooit een werkende motor- of verwarmingsschakeling zonder differentiële
  meetprobe die op de spanning is gedimensioneerd.
- Houd een gemeenschappelijke massa tussen de twee apparaten; een zwevende massa
  geeft onjuiste data en kan de poorten beschadigen.
- Houd de I2C-pull-ups zo kort als de bedrouting toelaat, want een lange
  onafgesloten lijn straalt en veroorzaakt storingen met tussenpozen.
- Eén kortsluiting legt alle apparaten op de bus stil, dus schakel het gedeelte
  spanningsvrij voordat u het opnieuw bedraadt.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- NXP and Analog Devices Interface Notes (publiek domein)
