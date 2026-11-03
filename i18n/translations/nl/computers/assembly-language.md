# Assembler en het machinemodel

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Assembler is de tekstvorm van wat de processor werkelijk uitvoert. Het laat
zien hoe de machine gegevens tussen registers en geheugen verplaatst, hoe zij
vertakt en hoe de stack wordt gebruikt, en dat maakt assembler het juiste
gereedschap voor de onderdelen van een systeem waar tijd of geheugen niet mag
worden verspild. Het kernprincipe is dat de architectuur een contract is: de
instructiecodering, de verzameling registers en de aanroepconventie liggen vast,
dus code die zich daaraan houdt blijft correct over compilers, bibliotheken en
toekomstige revisies heen.

## Vereisten

- Ingebed C-programmering
- Binaire en hexadecimale talstelsels
- Boolealgebra en twee's complement
- Een geheugenoverzicht en een processor-datasheet kunnen lezen

## Materialen en gereedschap

- Cortex-M-bord met debugprobe, of een hostmachine met een disassembler
- ARM GCC-toolchain, inclusief de programma's objdump en nm
- Referentiehandboek voor de instructieset en het geheugenoverzicht
- Tekstverwerker met hexadecimale weergave
- Logische analyser om de timing van pinnen en bussen te observeren
- Een testscript of terminalprogramma dat een bekende invoer aanstuurt

## Werkwijze

### De instructieset leren

1. Noteer de registerverzameling van de architectuur: 13 algemene registers van
   R0 tot R12, plus de stackpointer, het linkregister en de programmacounter, en
   de vlaggen voor negatief, nul, overdracht en overloop.
2. Schrijf de adresseringsmodi op, van register en directe waarde via register met
   offset en register indirect tot push en pop op de stack, met een voorbeeld van
   één regel per modus.
3. Noteer de coderingen: 16-bits instructies in de basiscodering, 32-bits
   instructies in de brede codering, en dat een 32-bits instructie op een
   4-bytegrens moet staan.

### Een disassembleringslijst lezen

1. Compileer een kleine C-functie met debuginformatie en demonteer die met het
   programma objdump, en koppel daarna elke C-regel aan de bijbehorende
   instructies.
2. Herken de prologue die de registers bewaart, de body en de epilogue die ze
   herstelt en via het linkregister terugkeert.
3. Zoek de grootte van het stackframe in de lijst en controleer of die
   overeenkomt met wat de compiler voor dezelfde functie meldt.

### Een routine schrijven

1. Schrijf een functie in assembler die twee argumenten in de eerste twee
   registers neemt en een resultaat in het eerste teruggeeft, volgens de
   aanroepstandaard voor procedures.
2. Houd de stackpointer op elke aanroepgrens 8-byte uitgelijnd en controleer de
   uitlijning vóór het terugkeren.
3. Test de routine tegen een C-implementatie over veel invoerwaarden en vergelijk
   de resultaten waarde voor waarde.

### Mixen met C en profileren

1. Markeer een routine alleen als naked waar dat nodig is, en laat de compiler de
   registers rond de aanroep overal anders beheren.
2. Meet het aantal cycli met de cyclusteller van de kern en vergelijk dat met
   hetzelfde werk in C op elk optimalisatieniveau.
3. Lees het map-bestand van de linker om te zien hoeveel flash en RAM de assembler
   bespaarde, en behoud het alleen waar de besparing de onderhoudskosten waard
   is.

## Veiligheidsnotities

- Een routine in assembler kan een uitgangspin in elke stand zetten zodra hij
  draait, en een oneindige lus in een interrupt-handler laat de watchdog
  aanslaan of de machine hangen. Bewijs de nieuwe code met de actuatoren
  losgekoppeld.
- Schrijven naar het verkeerde adres in assembler beschadigt het geheugen en de
  perifere registers zonder waarschuwing. Controleer elk adres tegen het
  geheugenoverzicht voordat u ernaar schrijft en bevestig dat het gebied
  uitvoerbaar en niet beschermd is.
- Respecteer de uitlijningsregels van de kern; een niet-uitgelijnde 32-bits
  toegang veroorzaakt op sommige apparaten een fout en kost op andere stilzwijgend
  cycli.
- Stap voor stap doorlopen verandert de timing van het programma, dus debug een
  regelkring niet per stap. Gebruik in plaats daarvan een tracebuffer of een
  logische analyser.
- Houd een hardware-reset, een bootloader of een herstelimage beschikbaar en
  test het herstelpad voordat u erop vertrouwt.
- Behandel assembler als standaard ononderhoudbaar: houd het klein, voorzie het
  van commentaar over het registergebruik en dek het af met de C-referentietest.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- Arm Cortex-M Documentation (publiek domein)
