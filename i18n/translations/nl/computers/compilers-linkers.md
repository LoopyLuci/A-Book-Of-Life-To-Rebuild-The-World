# Compilers, linkers en buildsystemen

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Een build zet broncode om in een binair via fasen die meestal verborgen blijven:
preprocessen, compileren naar assembler, assembler naar een objectbestand, en het
linken van objecten tot een uitvoerbaar bestand. Elke fase kennen maakt van een
toolchain een gereedschap in plaats van een mysterie, want de meeste vervelende
fouten, een ontbrekend symbool, een plotselinge sprong in de omvang, een binair
dat tussen machines verschilt, horen bij één fase en hebben één oplossing. Het
kernprincipe is dat elke fase een artefact oplevert dat u kunt lezen, zodat een
build altijd inspecteerbaar moet zijn en geen zwarte doos.

## Vereisten

- C-programmering en de preprocessor
- Ingebed C-programmering
- Gebruik van de opdrachtregel en een tekstverwerker
- Basiskennis van bestanden en mappen

## Materialen en gereedschap

- GNU-toolchain: compiler, assembler, linker, archiver, objdump, nm, size
- GNU Make, of een andere builddriver
- Een klein project met een header, twee bronbestanden en een testprogramma
- Viewers voor object- en hexbestanden, plus een versiebeheersysteem
- Een buildmap die gescheiden blijft van de bronboom
- Een manifest dat de versie van de compiler en de flags vastlegt

## Werkwijze

### De fasen volgen

1. Voer de preprocessor alleen uit en lees de uitvoer, compileer daarna naar
   assembler en lees die, zodat u weet uit welke fase een fout komt.
2. Maak objectbestanden en bekijk de sectiekoppen: de text-, data-, alleen-lezen-
   data- en bss-secties, samen met de symbooltabel.
3. Link de objecten tot een uitvoerbaar bestand en inspecteer het beginpunt en de
   plattegrond van wat de linker waar heeft geplaatst.

### De build beheersen

1. Schrijf een makefile met expliciete regels, phony-doelen en één
   afhankelijkheidsbestand per bronbestand, zodat een wijziging in een header elk
   bestand opnieuw bouwt dat hem bevat.
2. Houd één doel per uitvoer en de compileropdracht in één variabele, zodat geen
   twee regels het oneens kunnen zijn over de flags.
3. Schakel secties per functie in en de linkeroptie die ongebruikte secties
   verwijdert, en meet dan de verandering in het map-bestand.

### Bewust linken

1. Kies per component statisch of dynamisch linken, en bedenk dat een gedeelde
   bibliotheek een versieafhankelijkheid toevoegt aan elke machine die hem
   draait.
2. Maak het beginpunt, de opstartbestanden, de stack en de heap expliciet in het
   linkerscript in plaats van de standaardwaarden te accepteren.
3. Lijst de symbolen op die in het binaire bestand achterblijven en strip die welke
   alleen nodig waren voor debugging, voordat u het vrijgeeft.

### De build reproduceerbaar maken

1. Vast de versie van de toolchain, de flags en de omgeving in een
   manifestbestand dat de build inleest, zodat elke machine op dezelfde manier
   compileert.
2. Strip absolute paden uit de objectbestanden met de vlag voor het hernoemen van
   bronpaden, en zet de variabele voor de epoch van de brondatum op een vaste
   waarde.
3. Bouw dezelfde commit tweemaal op twee verschillende machines en vergelijk de
   controlesommen van de uitvoer; die moeten identiek zijn.

## Veiligheidsnotities

- Een buildscript voert willekeurige code uit met uw rechten. Bouw alleen uit
  bronnen die u hebt gelezen en vertrouwt, en bekijk elk nieuw buildbestand
  voordat u het uitvoert.
- Een make-regel die bestanden verwijdert kan door een typefout in een
  doelnaam worden geactiveerd. Houd destructieve commando's buiten de regels, of
  beveilig ze met een vraag, en voer nooit een onbetrouwde makefile uit als
  beheerder.
- Schakel de stackbescherming, de fortify-broncontroles of de waarschuwingen niet
  uit om een build te laten slagen; elk daarvan vangt een echte fout.
- Debuginformatie en symbooltabellen in een vrijgegeven binair bestand onthullen
  bestandspaden, gebruikersnamen en interne structuur. Strip ze voor de
  publicatie.
- Leg de versie van de toolchain vast en leg die vast bij de build, want een
  compilerupgrade kan drijvende-kommagetallen, structuurlay-out en
  optimalisatieresultaten veranderen zonder enige bronwijziging.
- Let op schijfruimte en bouwtijd; een onbeperkte include of een
  afhankelijkheidslus zonder einde kan een volume vullen en de pipeline
  lamleggen.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- GNU Toolchain Manual (publiek domein)
