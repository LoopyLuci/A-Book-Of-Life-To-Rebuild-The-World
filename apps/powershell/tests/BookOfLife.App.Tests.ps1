#Requires -Version 5.1

<#
    The tests of the module itself: the import, the rendering, the themes and
    the persisted state.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'BookOfLife.psd1'
    Import-Module -Name $script:ModulePath -Force
    $script:Root = Find-BookRoot -StartPath $script:ModulePath
    $script:Corpus = Get-BookCorpus -Root $script:Root
    $script:State = @{
        Corpus       = $script:Corpus
        Catalog      = (Import-BookLanguageCatalog -Path (Join-Path -Path $script:Root -ChildPath 'i18n\strings') -Language 'en')
        Theme        = (Get-BookTheme -Name 'dark')
        ThemeName    = 'dark'
        Capability   = (Get-BookConsoleCapability)
        Glyphs       = (Get-BookGlyph -Unicode $true)
        Language     = 'en'
        Focus        = 'left'
        Mode         = 'browse'
        Query        = ''
        Prompt       = ''
        Domain       = ''
        Safety       = ''
        Difficulty   = ''
        Results      = @()
        Selected     = 0
        DomainIndex  = 0
        DetailScroll = 0
        Message      = ''
        Overlay      = $null
        Recent       = @()
        Disclaimer   = (Get-BookDisclaimer -Root $script:Root)
        StringsPath  = (Join-Path -Path $script:Root -ChildPath 'i18n\strings')
        Quit         = $false
        Width        = 100
        Height       = 30
    }
    Sync-BookResult -State $script:State
}

Describe 'The module' {
    It 'imports without errors and without warnings' {
        $warnings = @()
        $errors = @()
        Import-Module -Name $script:ModulePath -Force -WarningVariable warnings -ErrorVariable errors -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        $warnings.Count | Should -Be 0
        $errors.Count | Should -Be 0
    }

    It 'exports only the documented functions' {
        $module = Get-Module -Name 'BookOfLife'
        $data = Import-PowerShellDataFile -Path $script:ModulePath
        $declared = @($data.FunctionsToExport)
        @($module.ExportedFunctions.Keys).Count | Should -Be $declared.Count
        foreach ($name in $declared) {
            $module.ExportedFunctions.Keys | Should -Contain $name
        }
        foreach ($name in $module.ExportedFunctions.Keys) {
            $name | Should -Match '^[A-Z][a-z]+-[A-Z]'
        }
    }

    It 'has a manifest that matches the module' {
        $manifest = Test-ModuleManifest -Path $script:ModulePath -ErrorAction Stop
        $manifest.Version | Should -Be '1.0.0'
        $manifest.RootModule | Should -Be 'BookOfLife.psm1'
    }

    It 'never writes to the host' {
        $source = Get-Content -LiteralPath (Join-Path -Path (Split-Path -Path $script:ModulePath -Parent) -ChildPath 'BookOfLife.psm1') -Raw
        $source | Should -Not -Match 'Write-Host'
    }
}

Describe 'Get-BookTheme' {
    It 'knows the dark and the light theme' {
        $dark = Get-BookTheme -Name 'dark'
        $light = Get-BookTheme -Name 'light'
        $dark.Name | Should -Be 'dark'
        $light.Name | Should -Be 'light'
        ($dark.Accent -ne $light.Accent) | Should -Be $true
    }

    It 'falls back to the dark theme for an unknown name' {
        (Get-BookTheme -Name 'chartreuse').Name | Should -Be 'dark'
    }
}

Describe 'Get-BookScreen' {
    It 'builds one line per row of the terminal' {
        $screen = Get-BookScreen -State $script:State -Width 99 -Height 30
        @($screen.Lines).Count | Should -Be 30
        $screen.CursorRow | Should -Be 28
        $screen.CursorColumn | Should -Be 3
    }

    It 'draws the domains, the reader, the status bar and the prompt' {
        $screen = Get-BookScreen -State $script:State -Width 99 -Height 30
        $text = (@($screen.Lines) -join "`n")
        $text | Should -Match 'Domains'
        $text | Should -Match 'Ready'
        $text | Should -Match 'survival'
    }

    It 'puts the cursor in the search box while the search has the focus' {
        $script:State['Mode'] = 'search'
        $script:State['Query'] = 'water'
        $screen = Get-BookScreen -State $script:State -Width 99 -Height 30
        $screen.CursorRow | Should -Be 1
        $script:State['Mode'] = 'browse'
        $script:State['Query'] = ''
        Sync-BookResult -State $script:State
    }

    It 'builds the overlays' {
        foreach ($kind in @('about', 'help')) {
            $script:State['Overlay'] = @{ Kind = $kind; Title = $kind; Items = @(); Selected = 0; Prompt = ''; Action = '' }
            $screen = Get-BookScreen -State $script:State -Width 99 -Height 30
            @($screen.Lines).Count | Should -Be 30
        }
        $script:State['Overlay'] = $null
    }
}

Describe 'Get-BookDisclaimer' {
    It 'quotes the disclaimer of docs/DISCLAIMER.md verbatim' {
        $disclaimer = Get-BookDisclaimer -Root $script:Root
        $file = Get-Content -LiteralPath (Join-Path -Path $script:Root -ChildPath 'docs\DISCLAIMER.md') -Raw
        ($disclaimer.Length -gt 0) | Should -Be $true
        foreach ($line in ($disclaimer -split "`r?`n")) {
            if ($line.Trim().Length -eq 0) { continue }
            $file | Should -Match ([regex]::Escape($line.Trim()))
        }
    }

    It 'has a fallback when the document is missing' {
        $disclaimer = Get-BookDisclaimer -Root (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'abook-nowhere')
        ($disclaimer.Length -gt 0) | Should -Be $true
    }
}

Describe 'The persisted state' {
    It 'writes and reads the language, the theme and the recently read list' {
        $path = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('abook-state-' + [System.Guid]::NewGuid().ToString('N') + '.json')
        try {
            $state = @{
                Language = 'fr'
                Theme    = 'light'
                Recent   = @([pscustomobject]@{ Id = 'pnk:1'; Title = 'One'; Domain = 'water'; At = 'now' })
            }
            Export-BookState -State $state -Path $path
            (Test-Path -LiteralPath $path -PathType Leaf) | Should -Be $true
            $loaded = Import-BookState -Path $path
            $loaded['Language'] | Should -Be 'fr'
            $loaded['Theme'] | Should -Be 'light'
            @($loaded['Recent']).Count | Should -Be 1
            $loaded['Recent'][0].Title | Should -Be 'One'
        }
        finally {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }

    It 'uses the defaults when the file is missing' {
        $loaded = Import-BookState -Path (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'abook-no-state.json')
        $loaded['Language'] | Should -Be 'en'
        $loaded['Recent'].Count | Should -Be 0
    }

    It 'puts the state file under the profile of the user' {
        $path = Get-BookStatePath
        $path | Should -Match 'state.json'
        ($path -match 'APPDATA|HOME|USERPROFILE') | Should -Be $true
    }
}
