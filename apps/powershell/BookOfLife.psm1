<#
.SYNOPSIS
    Core logic for the Book of Life interactive console.

.DESCRIPTION
    The module loads the knowledge base, searches it, renders it and keeps
    the reader's preferences. It contains no user interface code, so it can
    be used from a script, from a pipeline or from the interactive shell.

    Every function here works without a network connection. The corpus is
    read from the repository; nothing is ever fetched.
#>

Set-StrictMode -Version Latest

$script:Corpus = $null

function Get-AbookRoot {
    <#
    .SYNOPSIS
        Finds the repository root by walking up until manifest.toml appears.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Start = $PSScriptRoot
    )

    $current = $null
    try { $current = (Resolve-Path -LiteralPath $Start -ErrorAction Stop).Path } catch { }
    if (-not $current) { $current = (Get-Location).Path }

    for ($depth = 0; $depth -lt 12; $depth++) {
        $manifest = Join-Path $current 'manifest.toml'
        if (Test-Path -LiteralPath $manifest) { return $current }
        $parent = Split-Path -Parent $current
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }

    throw "Could not find the repository root (no manifest.toml above '$Start')."
}

function Get-AbookVersion {
    <#
    .SYNOPSIS
        Reads the project version from manifest.toml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Root)

    $manifest = Join-Path $Root 'manifest.toml'
    if (-not (Test-Path -LiteralPath $manifest)) { return 'unknown' }
    foreach ($line in (Get-Content -LiteralPath $manifest)) {
        if ($line -match '^\s*version\s*=\s*"([^"]+)"') { return $Matches[1] }
    }
    return 'unknown'
}

function ConvertFrom-AbookScalar {
    <#
    .SYNOPSIS
        Converts a YAML scalar, including an inline [a, b] list, to a value.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    $text = $Value.Trim()
    if ($text -eq '[]') { return @() }
    if ($text -match '^\[(.*)\]$') {
        $inner = $Matches[1]
        if ([string]::IsNullOrWhiteSpace($inner)) { return @() }
        $items = @()
        foreach ($part in ($inner -split ',')) {
            $items += , (ConvertFrom-AbookScalar -Value $part)
        }
        return , $items
    }
    if ($text.Length -ge 2 -and $text.StartsWith('"') -and $text.EndsWith('"')) {
        return $text.Substring(1, $text.Length - 2)
    }
    if ($text.Length -ge 2 -and $text.StartsWith("'") -and $text.EndsWith("'")) {
        return $text.Substring(1, $text.Length - 2)
    }
    if ($text -eq 'true') { return $true }
    if ($text -eq 'false') { return $false }
    if ($text -eq 'null' -or $text -eq '~') { return $null }
    if ($text -match '^-?\d+$') { return [int]$text }
    if ($text -match '^-?\d+\.\d+$') { return [double]$text }
    return $text
}

function ConvertTo-AbookLine {
    <#
    .SYNOPSIS
        Turns a file into a list of indent and text pairs.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $lines = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $Path)) { return @() }

    foreach ($raw in (Get-Content -LiteralPath $Path)) {
        $line = $raw -replace "`r$", ''
        if ($line -match '^\s*#') { continue }
        if ($line -match '^\s*$') { continue }
        $indent = $line.Length - $line.TrimStart().Length
        [void]$lines.Add([pscustomobject]@{
            Indent = $indent
            Text   = $line.Trim()
        })
    }
    return @($lines)
}

function ConvertFrom-AbookBlock {
    <#
    .SYNOPSIS
        Parses one block of YAML lines at a given indent.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Lines,
        [Parameter(Mandatory)][ref]$Index,
        [Parameter(Mandatory)][int]$Indent
    )

    $map = @{}

    while ($Index.Value -lt $Lines.Count) {
        $line = $Lines[$Index.Value]
        if ($line.Indent -lt $Indent) { break }
        if ($line.Indent -gt $Indent) { $Index.Value++; continue }

        $text = $line.Text

        # A sequence at this level.
        if ($text.StartsWith('- ') -or $text -eq '-') {
            $list = New-Object System.Collections.ArrayList
            while ($Index.Value -lt $Lines.Count -and
                   $Lines[$Index.Value].Indent -eq $Indent -and
                   ($Lines[$Index.Value].Text.StartsWith('- ') -or $Lines[$Index.Value].Text -eq '-')) {
                $item = $Lines[$Index.Value].Text -replace '^-[ ]?', ''
                $Index.Value++

                if ($item -match '^([A-Za-z0-9_.\-]+):[ ]*(.*)$') {
                    $entry = @{}
                    $key = $Matches[1]
                    $value = $Matches[2]
                    if ($value -eq '') {
                        if ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -gt $Indent) {
                            $entry[$key] = ConvertFrom-AbookBlock -Lines $Lines -Index $Index -Indent $Lines[$Index.Value].Indent
                        } else {
                            $entry[$key] = @{}
                        }
                    } else {
                        $entry[$key] = ConvertFrom-AbookScalar -Value $value
                    }
                    # Any further keys of the same mapping item.
                    if ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -gt $Indent) {
                        $more = ConvertFrom-AbookBlock -Lines $Lines -Index $Index -Indent $Lines[$Index.Value].Indent
                        foreach ($name in $more.Keys) { $entry[$name] = $more[$name] }
                    }
                    [void]$list.Add($entry)
                } else {
                    [void]$list.Add((ConvertFrom-AbookScalar -Value $item))
                }
            }
            return , $list
        }

        # A mapping entry.
        if ($text -match '^([A-Za-z0-9_.\-]+):[ ]*(.*)$') {
            $key = $Matches[1]
            $value = $Matches[2]
            $Index.Value++
            if ($value -eq '') {
                if ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -gt $Indent) {
                    $map[$key] = ConvertFrom-AbookBlock -Lines $Lines -Index $Index -Indent $Lines[$Index.Value].Indent
                } elseif ($Index.Value -lt $Lines.Count -and
                          $Lines[$Index.Value].Indent -eq $Indent -and
                          $Lines[$Index.Value].Text.StartsWith('- ')) {
                    $map[$key] = ConvertFrom-AbookBlock -Lines $Lines -Index $Index -Indent $Indent
                } else {
                    $map[$key] = @{}
                }
            } else {
                $map[$key] = ConvertFrom-AbookScalar -Value $value
            }
            continue
        }

        $Index.Value++
    }

    return , $map
}

function ConvertFrom-AbookYaml {
    <#
    .SYNOPSIS
        Parses the YAML subset used by the sidecars and the UI strings.

    .DESCRIPTION
        Handles nested mappings, sequences, sequences of mappings, inline
        [a, b] lists, quoted and bare scalars, comments and blank lines. It
        is deliberately small and predictable: it never guesses, and it
        returns an empty value for anything it does not understand.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $lines = ConvertTo-AbookLine -Path $Path
    if ($lines.Count -eq 0) { return @{} }
    $index = 0
    $parsed = ConvertFrom-AbookBlock -Lines $lines -Index ([ref]$index) -Indent $lines[0].Indent
    if ($parsed -is [System.Collections.ArrayList]) { return @{} }
    return $parsed
}

function Get-AbookDomains {
    <#
    .SYNOPSIS
        Returns the domain list from manifest.toml, in order.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param([string]$Root)

    $manifest = Join-Path $Root 'manifest.toml'
    $domains = @()
    if (-not (Test-Path -LiteralPath $manifest)) { return $domains }

    $inList = $false
    foreach ($line in (Get-Content -LiteralPath $manifest)) {
        if ($line -match '^\s*list\s*=\s*\[') { $inList = $true; continue }
        if ($inList) {
            if ($line -match '^\s*\]') { break }
            if ($line -match '"([^"]+)"') { $domains += $Matches[1] }
        }
    }
    return $domains
}

function Import-AbookCorpus {
    <#
    .SYNOPSIS
        Loads every sidecar and its Markdown body into memory.
    #>
    [CmdletBinding()]
    param(
        [string]$Root
    )

    if (-not $Root) { $Root = Get-AbookRoot }

    $entries = New-Object System.Collections.ArrayList
    $counts = @{}

    $sidecarRoot = Join-Path $Root 'sidecars'
    if (-not (Test-Path -LiteralPath $sidecarRoot)) { return $entries }

    foreach ($domainDir in (Get-ChildItem -LiteralPath $sidecarRoot -Directory | Sort-Object Name)) {
        $counts[$domainDir.Name] = 0
        foreach ($file in (Get-ChildItem -LiteralPath $domainDir.FullName -Filter '*.pnk.yaml' | Sort-Object Name)) {
            $data = ConvertFrom-AbookYaml -Path $file.FullName
            if (-not $data -or -not $data.ContainsKey('title')) { continue }

            $slug = $file.Name -replace '\.pnk\.yaml$', ''
            $bodyPath = Join-Path (Join-Path (Join-Path $Root 'domains') $domainDir.Name) "$slug.md"
            $body = ''
            if (Test-Path -LiteralPath $bodyPath) {
                $body = (Get-Content -LiteralPath $bodyPath -Raw) -replace "`r`n", "`n"
            }

            [void]$entries.Add([pscustomobject]@{
                Id           = if ($data.ContainsKey('id')) { $data['id'] } else { '' }
                Slug         = $slug
                Domain       = $domainDir.Name
                Title        = [string]$data['title']
                Tags         = if ($data.ContainsKey('tags')) { @($data['tags']) } else { @() }
                Difficulty   = if ($data.ContainsKey('difficulty')) { [string]$data['difficulty'] } else { 'novice' }
                Safety       = if ($data.ContainsKey('safety')) { [string]$data['safety'] } else { 'green' }
                Time         = if ($data.ContainsKey('time_to_complete')) { [string]$data['time_to_complete'] } else { '' }
                Sources      = if ($data.ContainsKey('sources')) { @($data['sources']) } else { @() }
                Verification = if ($data.ContainsKey('verification')) { $data['verification'] } else { @{} }
                Body         = $body
            })
            $counts[$domainDir.Name]++
        }
    }

    return [pscustomobject]@{
        Entries = @($entries)
        Counts  = $counts
        Root    = $Root
    }
}

function Get-AbookCorpus {
    <#
    .SYNOPSIS
        Returns the loaded corpus, loading it on first use.
    #>
    [CmdletBinding()]
    param()
    if (-not $script:Corpus) { $script:Corpus = Import-AbookCorpus }
    return $script:Corpus
}

function Search-Abook {
    <#
    .SYNOPSIS
        Searches the corpus, ranking title matches above tag matches above
        body matches.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [string]$Domain,
        [string]$Safety,
        [string]$Difficulty,
        [int]$Limit = 50,

        [object]$Corpus
    )

    if (-not $Corpus) { $Corpus = Get-AbookCorpus }
    $needle = $Query.Trim().ToLowerInvariant()
    if ($needle.Length -eq 0) { return @() }

    $results = New-Object System.Collections.ArrayList
    foreach ($entry in $Corpus.Entries) {
        if ($Domain -and $entry.Domain -ne $Domain) { continue }
        if ($Safety -and $entry.Safety -ne $Safety) { continue }
        if ($Difficulty -and $entry.Difficulty -ne $Difficulty) { continue }

        $score = 0.0
        $title = $entry.Title.ToLowerInvariant()
        $tags = (@($entry.Tags) | ForEach-Object { [string]$_ }) -join ' '
        $tags = $tags.ToLowerInvariant()
        $body = $entry.Body.ToLowerInvariant()

        if ($title.StartsWith($needle)) { $score += 100 }
        elseif ($title.Contains($needle)) { $score += 60 }
        if ($tags.Contains($needle)) { $score += 30 }
        if ($body.Contains($needle)) { $score += 10 }

        if ($score -le 0) { continue }
        [void]$results.Add([pscustomobject]@{
            Entry = $entry
            Score = $score
        })
    }

    return @($results | Sort-Object -Property Score -Descending | Select-Object -First $Limit)
}

function Get-AbookString {
    <#
    .SYNOPSIS
        Returns a translated interface string, falling back to English.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [string]$Language = 'en',
        [string]$Root
    )

    if (-not $Root) { $Root = Get-AbookRoot }
    $stringsRoot = Join-Path (Join-Path $Root 'i18n') 'strings'

    foreach ($candidate in @($Language, 'en')) {
        if (-not $candidate) { continue }
        $path = Join-Path $stringsRoot "$candidate.yaml"
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $parsed = ConvertFrom-AbookYaml -Path $path
        if ($parsed -and $parsed.ContainsKey($Key)) { return [string]$parsed[$Key] }
    }

    return $Key
}

function Get-AbookDisclaimer {
    <#
    .SYNOPSIS
        Returns the disclaimer summary quoted from docs/DISCLAIMER.md.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Root)

    $path = Join-Path (Join-Path $Root 'docs') 'DISCLAIMER.md'
    if (-not (Test-Path -LiteralPath $path)) {
        return 'Reference material only. Verify before acting.'
    }
    $lines = Get-Content -LiteralPath $path
    $inSummary = $false
    $collected = New-Object System.Collections.ArrayList
    foreach ($line in $lines) {
        if ($line -match '^##\s+12\.\s+Summary') { $inSummary = $true; continue }
        if ($inSummary -and $line -match '^##\s') { break }
        if ($inSummary -and $line.Trim().Length -gt 0) { [void]$collected.Add($line.Trim()) }
    }
    if ($collected.Count -eq 0) { return 'Reference material only. Verify before acting.' }
    return ($collected -join ' ')
}

function Compare-AbookVersion {
    <#
    .SYNOPSIS
        Compares two version strings. Returns -1, 0 or 1.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)][string]$Left,
        [Parameter(Mandatory)][string]$Right
    )

    function Split-Version {
        param([string]$Value)
        $text = $Value.Trim()
        if ($text.StartsWith('v') -or $text.StartsWith('V')) { $text = $text.Substring(1) }
        $core = ($text -split '-')[0]
        $parts = @()
        foreach ($part in ($core -split '\.')) {
            $number = 0
            if ([int]::TryParse($part, [ref]$number)) { $parts += $number } else { $parts += 0 }
        }
        return , $parts
    }

    $a = Split-Version $Left
    $b = Split-Version $Right
    $count = [Math]::Max($a.Count, $b.Count)
    for ($i = 0; $i -lt $count; $i++) {
        $av = if ($i -lt $a.Count) { $a[$i] } else { 0 }
        $bv = if ($i -lt $b.Count) { $b[$i] } else { 0 }
        if ($av -ne $bv) { return [Math]::Sign($av - $bv) }
    }

    $aHas = ($Left -split '-', 2).Count -gt 1
    $bHas = ($Right -split '-', 2).Count -gt 1
    if ($aHas -eq $bHas) { return 0 }
    if ($aHas) { return -1 }
    return 1
}

function Get-AbookSettingsPath {
    <#
    .SYNOPSIS
        Returns the path of the reader's settings file.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    $base = if ($env:APPDATA) { $env:APPDATA } else { Join-Path $HOME '.config' }
    return (Join-Path (Join-Path $base 'abook') 'settings.json')
}

function Get-AbookSettings {
    <#
    .SYNOPSIS
        Returns the reader's settings, with the defaults filled in.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    $defaults = @{
        language = 'en'
        theme    = 'dark'
        recent   = @()
        width    = 100
        height   = 30
    }
    $path = Get-AbookSettingsPath
    if (-not (Test-Path -LiteralPath $path)) { return $defaults }
    try {
        $stored = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    } catch {
        return $defaults
    }
    foreach ($key in $stored.PSObject.Properties.Name) {
        $defaults[$key] = $stored.$key
    }
    return $defaults
}

function Save-AbookSettings {
    <#
    .SYNOPSIS
        Writes the reader's settings.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Settings)
    $path = Get-AbookSettingsPath
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $Settings | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $path -Encoding UTF8
}

function Add-AbookRecent {
    <#
    .SYNOPSIS
        Records an entry as recently read and returns the updated list.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Key,
        [int]$Limit = 20
    )
    $settings = Get-AbookSettings
    $recent = @($settings['recent'] | Where-Object { $_ -ne $Key })
    $recent = @($recent) + $Key
    if ($recent.Count -gt $Limit) {
        $recent = @($recent | Select-Object -Last $Limit)
    }
    $settings['recent'] = $recent
    Save-AbookSettings -Settings $settings
    return , $recent
}

function Get-AbookSupportedLanguages {
    <#
    .SYNOPSIS
        Returns the language codes that have a UI string catalogue.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param([string]$Root)
    if (-not $Root) { $Root = Get-AbookRoot }
    $stringsRoot = Join-Path (Join-Path $Root 'i18n') 'strings'
    if (-not (Test-Path -LiteralPath $stringsRoot)) { return @('en') }
    $languages = @()
    foreach ($file in (Get-ChildItem -LiteralPath $stringsRoot -Filter '*.yaml' | Sort-Object Name)) {
        $languages += $file.BaseName
    }
    return , $languages
}

Export-ModuleMember -Function @(
    'Get-AbookRoot',
    'Get-AbookVersion',
    'ConvertFrom-AbookYaml',
    'ConvertFrom-AbookScalar',
    'ConvertTo-AbookLine',
    'ConvertFrom-AbookBlock',
    'Get-AbookDomains',
    'Import-AbookCorpus',
    'Get-AbookCorpus',
    'Search-Abook',
    'Get-AbookString',
    'Get-AbookDisclaimer',
    'Compare-AbookVersion',
    'Get-AbookSettingsPath',
    'Get-AbookSettings',
    'Save-AbookSettings',
    'Add-AbookRecent',
    'Get-AbookSupportedLanguages'
)
