# Cryptografie

> **Domain:** knowledge | **Difficulty:** journeyman | **Safety:** green

*Alleen referentiemateriaal. Controleer deze informatie aan de hand van primaire
bronnen en gekwalificeerde professionals voordat u ernaar handelt. Dit artikel
is geen zelfstandige informatiebron.*

## Overzicht

Cryptografie beschermt berichten en identiteit wanneer de kanalen onveilig zijn.
Eenmalige sleutels (one-time pads) geven onbreekbare geheimhouding; hashes
controleren de integriteit.

## Vereisten

- Geen

## Materialen en gereedschap

- Tabellen voor eenmalige sleutels
- Pen en papier
- Controlesomtabellen

## Werkwijze

### Eenmalige sleutel

1. Genereer echt willekeurig sleutelmateriaal van dezelfde lengte als het
   bericht.
2. Tel de sleutel bij de platte tekst op modulo 26 om te versleutelen; trek hem
   af om te ontsleutelen.
3. Vernietig elke sleutel na één gebruik.

### Integriteit

1. Voeg een hash of controlesom toe om knoeien op te sporen.
2. Controleer met een gedeeld geheim waar dat mogelijk is.

## Veiligheidsnotities

- Gebruik een eenmalige sleutel nooit opnieuw; hergebruik maakt hem breekbaar.
- Bescherm sleutels even zorgvuldig als het bericht.

## Verificatie

- **Status:** concept
- **Getest door:** —
- **Datum:** —

## Bronnen

- Public-domain cryptography primers (publiek domein)
- NIST cryptographic guidelines (publiek domein)
