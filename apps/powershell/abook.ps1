<#
.SYNOPSIS
    The interactive Book of Life console for Windows.

.DESCRIPTION
    A visual, interactive terminal reader for the knowledge base. It shows a
    domain pane on the left, the selected entry on the right, a status bar
    and a command prompt.

    Everything works offline. The corpus is read from the repository and
    never fetched.

.PARAMETER Selftest
    Load the corpus, run some checks and exit without opening the interface.

.PARAMETER Language
    Start in a language other than the one in the settings file.

.PARAMETER Query
    Start with a search already filled in.
#>
[CmdletBinding()]
param(
    [switch]$Selftest,
    [string]$Language,
    [string]$Query
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'BookOfLife.psm1') -Force

$script:Root = Get-AbookRoot
$script:Version = Get-AbookVersion -Root $script:Root

# ------------------------------------------------------------------ theme --

$script:Themes = @{
    dark = @{
        reset   = "`e[0m"; bold = "`e[1m"; dim = "`e[2m"
        fg      = "`e[38;5;252m"; accent = "`e[38;5;79m"; accent2 = "`e[38;5;215m"
        safe    = "`e[38;5;114m"; warn = "`e[38;5;179m"; danger = "`e[38;5;203m"
        title   = "`e[38;5;231m"; border = "`e[38;5;240m"; bg = "`e[48;5;236m"
    }
    light = @{
        reset   = "`e[0m"; bold = "`e[1m"; dim = "`e[2m"
        fg      = "`e[38;5;235m"; accent = "`e[38;5;26m"; accent2 = "`e[38;5;130m"
        safe    = "`e[38;5;28m"; warn = "`e[38;5;94m"; danger = "`e[38;5;124m"
        title   = "`e[38;5;16m"; border = "`e[38;5;250m"; bg = "`e[48;5;255m"
    }
}

function Get-Color {
    param([string]$Name)
    $theme = $script:Themes[$script:Settings['theme']]
    if ($theme.ContainsKey($Name)) { return $theme[$Name] }
    return ''
}

# ------------------------------------------------------------------- text --

function Format-Width {
    <#
    .SYNOPSIS
        Truncates or pads a string to a given display width.
    #>
    param(
        [string]$Text,
        [int]$Width
    )
    if ($null -eq $Text) { $Text = '' }
    if ($Text.Length -gt $Width) {
        if ($Width -le 1) { return $Text.Substring(0, [Math]::Max($Width, 0)) }
        return $Text.Substring(0, $Width - 1) + [char]0x2026
    }
    return $Text.PadRight($Width)
}

function Get-DisplayWidth {
    param([string]$Text)
    if ($null -eq $Text) { return 0 }
    return $Text.Length
}

# ------------------------------------------------------------------ state --

$script:Settings = Get-AbookSettings
if ($Language) { $script:Settings['language'] = $Language }
$script:Corpus = $null
$script:Mode = 'browse'          # browse | search | quickjump | help | about
$script:Selected = 0
$script:SearchText = if ($Query) { $Query } else { '' }
$script:FilterDomain = ''
$script:FilterSafety = ''
$script:FilterDifficulty = ''
$script:Results = @()
$script:Scroll = 0
$script:Message = ''
$script:Quit = $false
$script:RawMode = $false

function Get-Strings {
    <#
    .SYNOPSIS
        Returns the interface strings for the current language.
    #>
    [CmdletBinding()]
    param()
    $lang = $script:Settings['language']
    $keys = @(
        'domains', 'entries', 'difficulty', 'safety', 'time_to_complete',
        'prerequisites', 'materials', 'procedure', 'safety_notes',
        'verification', 'sources', 'search_placeholder'
    )
    $strings = @{}
    foreach ($key in $keys) {
        $strings[$key] = Get-AbookString -Key $key -Language $lang -Root $script:Root
    }
    return $strings
}

function Get-VisibleEntries {
    <#
    .SYNOPSIS
        Returns the entries the reader is currently looking at.
    #>
    [CmdletBinding()]
    param()
    if ($script:Mode -eq 'search' -and $script:SearchText.Trim().Length -gt 0) {
        return @($script:Results | ForEach-Object { $_.Entry })
    }
    $entries = @($script:Corpus.Entries)
    if ($script:FilterDomain) {
        $entries = @($entries | Where-Object { $_.Domain -eq $script:FilterDomain })
    }
    if ($script:FilterSafety) {
        $entries = @($entries | Where-Object { $_.Safety -eq $script:FilterSafety })
    }
    if ($script:FilterDifficulty) {
        $entries = @($entries | Where-Object { $_.Difficulty -eq $script:FilterDifficulty })
    }
    return $entries
}

function Update-Results {
    [CmdletBinding()]
    param()
    if ($script:SearchText.Trim().Length -eq 0) {
        $script:Results = @()
        return
    }
    $script:Results = @(Search-Abook -Query $script:SearchText -Corpus $script:Corpus)
}

# ---------------------------------------------------------------- drawing --

function Clear-Screen {
    Write-Host "`e[2J`e[H" -NoNewline
}

function Hide-Cursor { Write-Host "`e[?25l" -NoNewline }
function Show-Cursor { Write-Host "`e[?25h" -NoNewline }

function Show-Spinner {
    <#
    .SYNOPSIS
        Shows a spinner while the corpus loads.
    #>
    param([string]$Message)
    $frames = @('|', '/', '-', '\')
    for ($i = 0; $i -lt 12; $i++) {
        Write-Host ("`e[2K`e[?25l" + (Get-Color 'accent') + $frames[$i % 4] + "`e[0m " + $Message) -NoNewline
        Start-Sleep -Milliseconds 60
    }
    Write-Host "`e[2K`e[?25h" -NoNewline
}

function Draw-Frame {
    <#
    .SYNOPSIS
        Draws the two panes, the status bar and the prompt.
    #>
    param(
        [int]$Width = 100,
        [int]$Height = 30
    )

    $strings = Get-Strings
    $entries = Get-VisibleEntries
    if ($script:Selected -ge $entries.Count) { $script:Selected = [Math]::Max(0, $entries.Count - 1) }

    Clear-Screen
    Write-Host (Get-Color 'border') -NoNewline
    Write-Host ('+' + ('-' * ($Width - 2)) + '+') -NoNewline
    Write-Host (Get-Color 'reset')

    $title = ' A Book Of Life '
    $version = "v$($script:Version) "
    $pad = $Width - 4 - $title.Length - $version.Length
    if ($pad -lt 0) { $pad = 0 }
    Write-Host (Get-Color 'border') -NoNewline
    Write-Host ('|' + (Get-Color 'title') + $title + (Get-Color 'reset') +
                (' ' * $pad) + (Get-Color 'dim') + $version + (Get-Color 'reset') +
                (Get-Color 'border') + '|') -NoNewline
    Write-Host (Get-Color 'reset')

    $leftWidth = 30
    $rightWidth = $Width - $leftWidth - 3
    $bodyHeight = [Math]::Max(3, $Height - 6)

    # -- the domain pane ------------------------------------------------
    $domainRows = @()
    foreach ($domain in (Get-AbookDomains -Root $script:Root)) {
        $count = 0
        if ($script:Corpus.Counts.ContainsKey($domain)) { $count = $script:Corpus.Counts[$domain] }
        $marker = ' '
        if ($script:FilterDomain -eq $domain) { $marker = '*' }
        $domainRows += [pscustomobject]@{
            Label = "$marker $domain"
            Count = $count
        }
    }

    $visibleDomains = @()
    for ($i = 0; $i -lt $domainRows.Count; $i++) {
        if ($i -ge $script:Selected -and $visibleDomains.Count -ge $bodyHeight) { break }
        $visibleDomains += $domainRows[$i]
    }

    for ($row = 0; $row -lt $bodyHeight; $row++) {
        $left = if ($row -lt $visibleDomains.Count) { $visibleDomains[$row] } else { $null }
        $leftText = ' '
        $leftColor = 'fg'
        if ($left) {
            $leftText = ' ' + (Format-Width -Text $left.Label -Width ($leftWidth - 8))
            $leftText = $leftText.PadRight($leftWidth - 7) + ("{0,4}" -f $left.Count)
            $leftColor = 'accent'
        } else {
            $leftText = ' ' * ($leftWidth - 1)
        }
        Write-Host (Get-Color 'border') -NoNewline
        Write-Host '|' -NoNewline
        Write-Host (Get-Color $leftColor) -NoNewline
        Write-Host (Format-Width -Text $leftText -Width ($leftWidth - 1)) -NoNewline
        Write-Host (Get-Color 'reset') -NoNewline
        Write-Host (Get-Color 'border') -NoNewline
        Write-Host '|' -NoNewline
        Write-Host (Get-Color 'reset') -NoNewline
        Write-Host (Get-Color 'right')
    }

    # -- the bottom border and the status bar ---------------------------
    Write-Host (Get-Color 'border') -NoNewline
    Write-Host ('+' + ('-' * ($Width - 2)) + '+') -NoNewline
    Write-Host (Get-Color 'reset')

    $status = " $($script:Settings['language'])  |  $($script:Settings['theme'])  |  $($entries.Count) entries"
    if ($script:FilterDomain) { $status += "  |  domain: $($script:FilterDomain)" }
    if ($script:FilterSafety) { $status += "  |  safety: $($script:FilterSafety)" }
    if ($script:FilterDifficulty) { $status += "  |  level: $($script:FilterDifficulty)" }
    Write-Host (Get-Color 'dim') -NoNewline
    Write-Host (Format-Width -Text $status -Width ($Width - 1)) -NoNewline
    Write-Host (Get-Color 'reset')

    $hint = ' Ctrl+F search | Ctrl+K jump | F1 help | Ctrl+Q quit '
    Write-Host (Get-Color 'dim') -NoNewline
    Write-Host (Format-Width -Text $hint -Width ($Width - 1)) -NoNewline
    Write-Host (Get-Color 'reset')

    # -- the right pane --------------------------------------------------
    if ($entries.Count -gt 0) {
        $entry = $entries[$script:Selected]
        Write-Host (Get-Color 'border') -NoNewline
        Write-Host ('|' + (' ' * ($Width - 2)) + '|') -NoNewline
        Write-Host (Get-Color 'reset')

        $lines = @()
        $lines += (Get-Color 'title') + (Get-Color 'bold') + $entry.Title + (Get-Color 'reset')
        $lines += (Get-Color 'dim') + "  $($entry.Domain) | $($entry.Difficulty) | $($entry.Safety) | $($entry.Time)" + (Get-Color 'reset')
        $lines += ''
        foreach ($bodyLine in ($entry.Body -split "`n")) {
            $lines += $bodyLine
        }

        for ($row = 0; $row -lt $bodyHeight; $row++) {
            $index = $script:Scroll + $row
            $text = if ($index -lt $lines.Count) { $lines[$index] } else { '' }
            $text = ($text -replace "`e\[[0-9;]*m", '')
            Write-Host (Get-Color 'border') -NoNewline
            Write-Host '|' -NoNewline
            Write-Host ' ' -NoNewline
            Write-Host (Format-Width -Text $text -Width ($rightWidth - 1)) -NoNewline
            Write-Host (Get-Color 'reset') -NoNewline
            Write-Host (Get-Color 'border') -NoNewline
            Write-Host '|' -NoNewline
            Write-Host (Get-Color 'reset')
        }
    } else {
        for ($row = 0; $row -lt $bodyHeight; $row++) {
            Write-Host (Get-Color 'border') -NoNewline
            Write-Host ('|' + (' ' * ($Width - 2)) + '|') -NoNewline
            Write-Host (Get-Color 'reset')
        }
    }

    Write-Host (Get-Color 'border') -NoNewline
    Write-Host ('+' + ('-' * ($Width - 2)) + '+') -NoNewline
    Write-Host (Get-Color 'reset')

    # -- the prompt ------------------------------------------------------
    $promptText = if ($script:Mode -eq 'search') { "/$($script:SearchText)" } else { '>' }
    Write-Host (Get-Color 'accent') -NoNewline
    Write-Host $promptText -NoNewline
    Write-Host (Get-Color 'reset') -NoNewline
    if ($script:Message) {
        Write-Host (Get-Color 'warn') -NoNewline
        Write-Host "  $($script:Message)" -NoNewline
        Write-Host (Get-Color 'reset') -NoNewline
    }
    Write-Host ''
}

# ------------------------------------------------------------------ input --

function Read-Key {
    <#
    .SYNOPSIS
        Reads a single key, returning its name.
    #>
    param()

    try {
        $key = [Console]::ReadKey($true)
    } catch {
        return 'Enter'
    }

    switch ($key.Key) {
        'UpArrow'    { return 'Up' }
        'DownArrow'  { return 'Down' }
        'LeftArrow'  { return 'Left' }
        'RightArrow' { return 'Right' }
        'PageUp'     { return 'PageUp' }
        'PageDown'   { return 'PageDown' }
        'Home'       { return 'Home' }
        'End'        { return 'End' }
        'Tab'        { return 'Tab' }
        'Enter'      { return 'Enter' }
        'Escape'     { return 'Escape' }
        'Backspace'  { return 'Backspace' }
        'UpArrow'    { return 'Up' }
        default      { }
    }

    $char = $key.KeyChar
    $ctrl = [int][char]$char
    if ($ctrl -lt 32) {
        switch ($ctrl) {
            1  { return 'Ctrl+A' }
            2  { return 'Ctrl+B' }
            6  { return 'Ctrl+F' }
            10 { return 'Ctrl+J' }
            11 { return 'Ctrl+K' }
            17 { return 'Ctrl+Q' }
            18 { return 'Ctrl+R' }
            19 { return 'Ctrl+S' }
            20 { return 'Ctrl+T' }
            21 { return 'Ctrl+U' }
            22 { return 'Ctrl+V' }
            23 { return 'Ctrl+W' }
            default { return "Ctrl+$ctrl" }
        }
    }

    if ($char -eq "`e") { return 'Escape' }
    return [string]$char
}

function Read-Line {
    <#
    .SYNOPSIS
        Reads a line of text from the console.
    #>
    param([string]$Prompt = '> ')
    Write-Host (Get-Color 'accent') -NoNewline
    Write-Host $Prompt -NoNewline
    Write-Host (Get-Color 'reset') -NoNewline
    $line = Read-Host
    return $line
}

# ---------------------------------------------------------------- actions --

function Invoke-Command {
    <#
    .SYNOPSIS
        Runs a console command.
    #>
    param([string]$Line)

    $parts = $Line.Trim() -split '\s+', 2
    $command = $parts[0].ToLowerInvariant()
    $argument = if ($parts.Count -gt 1) { $parts[1] } else { '' }

    switch ($command) {
        'q' { $script:Quit = $true }
        'quit' { $script:Quit = $true }
        'exit' { $script:Quit = $true }
        'help' { $script:Message = 'Ctrl+F search, Ctrl+K jump, F1 help, Ctrl+T theme, Ctrl+L language, Ctrl+Q quit' }
        'theme' {
            $script:Settings['theme'] = if ($script:Settings['theme'] -eq 'dark') { 'light' } else { 'dark' }
            Save-AbookSettings -Settings $script:Settings
            $script:Message = "theme: $($script:Settings['theme'])"
        }
        'lang' {
            $languages = Get-AbookSupportedLanguages -Root $script:Root
            $current = [array]::IndexOf($languages, $script:Settings['language'])
            $next = ($current + 1) % $languages.Count
            $script:Settings['language'] = $languages[$next]
            Save-AbookSettings -Settings $script:Settings
            $script:Message = "language: $($script:Settings['language'])"
        }
        'langs' {
            $script:Message = ((Get-AbookSupportedLanguages -Root $script:Root) -join ', ')
        }
        'domains' {
            $script:FilterDomain = ''
            $script:FilterSafety = ''
            $script:FilterDifficulty = ''
            $script:Message = 'filters cleared'
        }
        'domain' {
            $script:FilterDomain = $argument
            $script:Message = if ($argument) { "domain: $argument" } else { 'domain filter cleared' }
        }
        'safety' {
            $script:FilterSafety = $argument
            $script:Message = if ($argument) { "safety: $argument" } else { 'safety filter cleared' }
        }
        'level' {
            $script:FilterDifficulty = $argument
            $script:Message = if ($argument) { "level: $argument" } else { 'difficulty filter cleared' }
        }
        'recent' {
            $recent = @($script:Settings['recent'])
            if ($recent.Count -eq 0) { $script:Message = 'nothing read yet' }
            else { $script:Message = ($recent -join ', ') }
        }
        'about' {
            Write-Host ''
            Write-Host (Get-Color 'title') + (Get-Color 'bold') + "A Book Of Life  v$($script:Version)" + (Get-Color 'reset')
            Write-Host ''
            Write-Host (Get-Color 'warn') + (Get-Color 'bold') + '  DISCLAIMER' + (Get-Color 'reset')
            Write-Host (Get-Color 'warn') + '  ' + (Get-AbookDisclaimer -Root $script:Root) + (Get-Color 'reset')
            Write-Host ''
            Write-Host (Get-Color 'dim') + "  $($script:Corpus.Entries.Count) entries, $($script:Corpus.Counts.Count) domains" + (Get-Color 'reset')
            Write-Host ''
            Read-Host '  Press Enter to continue' | Out-Null
        }
        'clear' { $script:SearchText = ''; $script:Mode = 'browse'; $script:Message = '' }
        default {
            $script:SearchText = $Line
            $script:Mode = 'search'
            Update-Results
            $script:Selected = 0
            $script:Message = "$(@($script:Results).Count) results"
        }
    }
}

# ------------------------------------------------------------------- main --

function Start-Console {
    <#
    .SYNOPSIS
        Runs the interactive loop.
    #>
    param()

    $width = 100
    $height = 30
    try {
        $raw = $Host.UI.RawUI
        if ($raw.WindowSize.Width -gt 40) { $width = [Math]::Min($width, $raw.WindowSize.Width) }
        if ($raw.WindowSize.Height -gt 10) { $height = [Math]::Min($height, $raw.WindowSize.Height) }
    } catch { }

    Show-Spinner -Message 'loading the knowledge base'
    $script:Corpus = Import-AbookCorpus -Root $script:Root
    Update-Results

    Clear-Screen
    Write-Host ''
    Write-Host (Get-Color 'title') + (Get-Color 'bold') + '  A Book Of Life' + (Get-Color 'reset')
    Write-Host (Get-Color 'dim') + "  an offline knowledge base, v$($script:Version)" + (Get-Color 'reset')
    Write-Host ''
    Write-Host (Get-Color 'warn') + '  ' + (Get-AbookDisclaimer -Root $script:Root) + (Get-Color 'reset')
    Write-Host ''
    Write-Host (Get-Color 'dim') + "  $($script:Corpus.Entries.Count) entries, $($script:Corpus.Counts.Count) domains, $($script:Settings['language'])" + (Get-Color 'reset')
    Write-Host ''
    Read-Host '  Press Enter to start' | Out-Null

    while (-not $script:Quit) {
        Draw-Frame -Width $width -Height $height

        $key = Read-Key
        switch ($key) {
            'Ctrl+Q' { $script:Quit = $true }
            'Ctrl+F' { $script:Mode = 'search' }
            'Ctrl+K' { $script:Mode = 'quickjump' }
            'Ctrl+T' {
                $script:Settings['theme'] = if ($script:Settings['theme'] -eq 'dark') { 'light' } else { 'dark' }
                Save-AbookSettings -Settings $script:Settings
            }
            'Ctrl+L' {
                $languages = Get-AbookSupportedLanguages -Root $script:Root
                $current = [array]::IndexOf($languages, $script:Settings['language'])
                $next = ($current + 1) % $languages.Count
                $script:Settings['language'] = $languages[$next]
                Save-AbookSettings -Settings $script:Settings
            }
            'Up' { if ($script:Selected -gt 0) { $script:Selected-- } }
            'Down' {
                $entries = Get-VisibleEntries
                if ($script:Selected -lt $entries.Count - 1) { $script:Selected++ }
            }
            'PageUp' { $script:Scroll = [Math]::Max(0, $script:Scroll - 5) }
            'PageDown' { $script:Scroll += 5 }
            'Tab' { $script:Selected = 0; $script:Scroll = 0 }
            'Backspace' {
                if ($script:SearchText.Length -gt 0) {
                    $script:SearchText = $script:SearchText.Substring(0, $script:SearchText.Length - 1)
                    Update-Results
                }
            }
            'Escape' { $script:Mode = 'browse'; $script:SearchText = ''; Update-Results }
            'Enter' {
                $line = Read-Line
                Invoke-Command -Line $line
                $script:Scroll = 0
            }
            default {
                if ($key.Length -eq 1 -and $script:Mode -eq 'search') {
                    $script:SearchText += $key
                    Update-Results
                    $script:Selected = 0
                } elseif ($key.Length -eq 1) {
                    $script:Mode = 'search'
                    $script:SearchText = $key
                    Update-Results
                }
            }
        }
    }

    Clear-Screen
    Write-Host ''
    Write-Host (Get-Color 'dim') + '  Goodbye.' + (Get-Color 'reset')
    Write-Host ''
}

function Invoke-Selftest {
    <#
    .SYNOPSIS
        Verifies the app without opening the interface.
    #>
    param()

    $failures = 0
    function Check {
        param([bool]$Condition, [string]$Message)
        if ($Condition) {
            Write-Host "  ok  $Message" -ForegroundColor DarkGreen
        } else {
            Write-Host "  xx  $Message" -ForegroundColor Red
            $script:failures++
        }
    }

    Write-Host "Book of Life PowerShell app self-test" -ForegroundColor Cyan
    $script:Corpus = Import-AbookCorpus -Root $script:Root
    Check ($script:Corpus.Entries.Count -gt 100) "the corpus loads ($($script:Corpus.Entries.Count) entries)"
    Check ($script:Corpus.Counts.Count -ge 16) "the domains load ($($script:Corpus.Counts.Count))"

    $results = Search-Abook -Query 'Making Fire' -Corpus $script:Corpus
    Check ($results.Count -gt 0) 'a title search returns a hit'
    Check ($results[0].Entry.Title -eq 'Making Fire') 'the title match ranks first'

    $languages = Get-AbookSupportedLanguages -Root $script:Root
    Check ($languages.Count -ge 9) "the languages are available ($($languages.Count))"

    $fallback = Get-AbookString -Key 'domains' -Language 'zz' -Root $script:Root
    Check ($fallback -eq 'Domains') 'an unknown language falls back to English'

    $disclaimer = Get-AbookDisclaimer -Root $script:Root
    Check ($disclaimer.Length -gt 40) 'the disclaimer is loaded'

    $version = Get-AbookVersion -Root $script:Root
    Check ($version -ne 'unknown') "the version is read ($version)"

    Write-Host ''
    if ($failures -gt 0) {
        Write-Host "$failures check(s) failed" -ForegroundColor Red
        return 1
    }
    Write-Host 'all checks passed' -ForegroundColor Green
    return 0
}

if ($Selftest) {
    exit (Invoke-Selftest)
}

if (-not [Environment]::UserInteractive) {
    Write-Error 'The interactive console needs an interactive host.'
    exit 1
}

exit (Start-Console)
