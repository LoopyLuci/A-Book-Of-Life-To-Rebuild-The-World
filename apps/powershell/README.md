# A Book Of Life — PowerShell console

An interactive, visual terminal reader for the *A Book Of Life To Rebuild
The World* knowledge base, for Windows and for PowerShell 7 on Linux and
macOS.

It works entirely offline. The corpus is read from the repository; nothing
is ever fetched.

## Install

The console needs only PowerShell 5.1 or newer. No module to install.

```powershell
git clone https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World.git
cd A-Book-Of-Life-To-Rebuild-The-World
```

Optionally, install the whole project so the search index, the SDKs and the
tests are available too:

```powershell
.\install.ps1
```

## Run

```powershell
pwsh -NoProfile -File apps/powershell/abook.ps1
```

or, from PowerShell 7, dot-source the launcher:

```powershell
.\apps\powershell\abook.ps1
```

## Keys

| Key | Action |
|-----|--------|
| `Ctrl+F` | Search. The results filter as you type. |
| `Ctrl+K` | Quick jump to an entry by name. |
| `F1` | Help. |
| `Ctrl+T` | Switch between the light and the dark theme. |
| `Ctrl+L` | Switch to the next interface language. |
| `Ctrl+Q` | Quit. |
| Up, Down | Move the selection. |
| PageUp, PageDown | Scroll the entry. |
| Tab | Move to the top of the list. |
| Escape | Leave the search. |
| Enter | Open the command prompt. |

## Commands

Type these at the `>` prompt.

| Command | Action |
|---------|--------|
| `<any text>` | Search for the text. |
| `domain <name>` | Filter by domain. `domains` clears every filter. |
| `safety <level>` | Filter by safety level: green, yellow or red. |
| `level <level>` | Filter by difficulty: novice, apprentice, journeyman or master. |
| `recent` | Show the entries you read recently. |
| `lang` | Switch to the next language. `langs` lists them. |
| `theme` | Switch the theme. |
| `about` | Show the version and the disclaimer. |
| `clear` | Clear the search. |
| `q` | Quit. |

## Languages

The interface follows the `i18n/strings/` catalogues: English, Spanish,
French, German, Portuguese, Hindi, Arabic, Swahili and Simplified Chinese.
An unknown language falls back to English.

## Use it as a module

The logic lives in `BookOfLife.psm1` and has no user interface, so it can be
used from a script.

```powershell
Import-Module ./apps/powershell/BookOfLife.psm1

$corpus = Get-AbookCorpus
Search-Abook -Query 'solar' -Domain 'energy' -Limit 10
Get-AbookString -Key 'safety_notes' -Language 'fr'
Get-AbookDisclaimer
```

## Test

```powershell
pwsh -NoProfile -File apps/powershell/tests/run-tests.ps1
pwsh -NoProfile -File apps/powershell/abook.ps1 --selftest
```

## License

Code: MIT. Content: CC BY-SA 4.0. See the repository root for the
disclaimer that applies to everything the console shows.
