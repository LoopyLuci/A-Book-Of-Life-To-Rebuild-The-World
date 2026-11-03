#Requires -Version 5.1

<#
    The tests of the interactive behaviour: the key handling, the search box,
    the filters, the overlays and the recently read list.

    The keys are built by hand, so the whole application can be driven without
    a terminal.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'BookOfLife.psd1'
    Import-Module -Name $script:ModulePath -Force
    $script:Root = Find-BookRoot -StartPath $script:ModulePath
    $script:Corpus = Get-BookCorpus -Root $script:Root
    $script:Catalog = Import-BookLanguageCatalog -Path (Join-Path -Path $script:Root -ChildPath 'i18n\strings') -Language 'en'

    $script:NewKey = {
        param(
            [ConsoleKey]$Key = [ConsoleKey]::NoName,
            [char]$Char = [char]0,
            [ConsoleModifiers]$Modifiers = [ConsoleModifiers]0
        )
        if (($Key -eq [ConsoleKey]::NoName) -and ($Char -ne [char]0)) {
            $Key = [ConsoleKey][int][char]::ToUpperInvariant($Char)
        }
        $shift = ($Modifiers -band [ConsoleModifiers]::Shift) -ne 0
        $alt = ($Modifiers -band [ConsoleModifiers]::Alt) -ne 0
        return [ConsoleKeyInfo]::new($Char, $Key, $shift, $alt, $Modifiers)
    }

    $script:NewState = {
        $state = Initialize-BookState -Corpus $script:Corpus -Catalog $script:Catalog -ThemeName 'dark' `
            -Capability (Get-BookConsoleCapability) -Glyphs (Get-BookGlyph -Unicode $true) `
            -Disclaimer (Get-BookDisclaimer -Root $script:Root) `
            -StringsPath (Join-Path -Path $script:Root -ChildPath 'i18n\strings')
        $state['Width'] = 100
        $state['Height'] = 30
        return $state
    }

    $script:SendText = {
        param([hashtable]$State, [string]$Text)
        foreach ($letter in $Text.ToCharArray()) {
            if ($letter -eq ' ') {
                $key = [ConsoleKey]::Spacebar
            }
            else {
                $key = [ConsoleKey][int][char]::ToUpperInvariant($letter)
            }
            Invoke-BookKey -State $State -Key (& $script:NewKey -Key $key -Char $letter)
        }
    }
}

Describe 'Invoke-BookKey' {
    It 'leaves the application on Ctrl+Q' {
        $state = & $script:NewState
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Q) -Char ([char]0x11) -Modifiers ([ConsoleModifiers]::Control))
        $state.Quit | Should -Be $true
    }

    It 'focuses the search box on Ctrl+F' {
        $state = & $script:NewState
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::F) -Char ([char]0x06) -Modifiers ([ConsoleModifiers]::Control))
        $state.Mode | Should -Be 'search'
    }

    It 'filters as the user types' {
        $state = & $script:NewState
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::F) -Char ([char]0x06) -Modifiers ([ConsoleModifiers]::Control))
        & $script:SendText -State $state -Text 'wat'
        $state.Query | Should -Be 'wat'
        (@($state.Results).Count -gt 0) | Should -Be $true
        $state.Results[0].Entry.TitleLower | Should -Match 'water'
    }

    It 'removes a character with backspace' {
        $state = & $script:NewState
        $state.Mode = 'search'
        $state.Query = 'water'
        Sync-BookResult -State $state
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Backspace) -Char ([char]8))
        $state.Query | Should -Be 'wate'
    }

    It 'leaves the search box on escape' {
        $state = & $script:NewState
        $state.Mode = 'search'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Escape) -Char ([char]27))
        $state.Mode | Should -Be 'browse'
    }

    It 'switches the pane on tab' {
        $state = & $script:NewState
        $state.Focus | Should -Be 'left'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Tab) -Char ([char]9))
        $state.Focus | Should -Be 'right'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Tab) -Char ([char]9))
        $state.Focus | Should -Be 'left'
    }

    It 'walks through the domains with the arrow keys' {
        $state = & $script:NewState
        $state.DomainIndex | Should -Be 0
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::DownArrow) -Char ([char]0))
        $state.DomainIndex | Should -Be 1
        $state.Domain | Should -Be 'water'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::UpArrow) -Char ([char]0))
        $state.DomainIndex | Should -Be 0
    }

    It 'walks through the entries with the arrow keys' {
        $state = & $script:NewState
        $state.Focus = 'right'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::DownArrow) -Char ([char]0))
        $state.Selected | Should -Be 1
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::UpArrow) -Char ([char]0))
        $state.Selected | Should -Be 0
    }

    It 'scrolls the entry with page down and page up' {
        $state = & $script:NewState
        $state.Focus = 'right'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::PageDown) -Char ([char]0))
        ($state.DetailScroll -gt 0) | Should -Be $true
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::PageUp) -Char ([char]0))
        $state.DetailScroll | Should -Be 0
    }

    It 'remembers the entries that were read' {
        $state = & $script:NewState
        $state.Focus = 'right'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::DownArrow) -Char ([char]0))
        @($state.Recent).Count | Should -Be 1
        $state.Recent[0].Id | Should -Be $state.Results[1].Entry.Id
    }
}

Describe 'The overlays' {
    It 'opens the help on F1 and closes it on escape' {
        $state = & $script:NewState
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::F1) -Char ([char]0))
        $state.Mode | Should -Be 'overlay'
        $state.Overlay.Kind | Should -Be 'help'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Escape) -Char ([char]27))
        $state.Mode | Should -Be 'browse'
        $state.Overlay | Should -BeNullOrEmpty
    }

    It 'opens the about screen on F5' {
        $state = & $script:NewState
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::F5) -Char ([char]0))
        $state.Overlay.Kind | Should -Be 'about'
    }

    It 'switches the theme on F2' {
        $state = & $script:NewState
        $state.ThemeName | Should -Be 'dark'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::F2) -Char ([char]0))
        $state.ThemeName | Should -Be 'light'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::F2) -Char ([char]0))
        $state.ThemeName | Should -Be 'dark'
    }

    It 'applies a filter from the filter picker' {
        $state = & $script:NewState
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::F4) -Char ([char]0))
        $state.Overlay.Kind | Should -Be 'filters'
        $state.Overlay.Selected = 1
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Enter) -Char ([char]13))
        $state.Mode | Should -Be 'browse'
        $state.Domain | Should -Be ''
    }

    It 'filters the quick jump list while typing' {
        $state = & $script:NewState
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::K) -Char ([char]0x0B) -Modifiers ([ConsoleModifiers]::Control))
        $state.Overlay.Kind | Should -Be 'jump'
        & $script:SendText -State $state -Text 'ra'
        $state.Overlay.Prompt | Should -Be 'ra'
        (@($state.Overlay.Items).Count -gt 0) | Should -Be $true
    }

    It 'opens the entry that was picked in the quick jump list' {
        $state = & $script:NewState
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::K) -Char ([char]0x0B) -Modifiers ([ConsoleModifiers]::Control))
        & $script:SendText -State $state -Text 'ra'
        $expected = $state.Overlay.Items[0].Value
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Enter) -Char ([char]13))
        $state.Mode | Should -Be 'browse'
        $state.Results[$state.Selected].Entry.Id | Should -Be $expected
    }
}

Describe 'The command prompt' {
    It 'runs a command that was typed at the prompt' {
        $state = & $script:NewState
        & $script:SendText -State $state -Text 'domain water'
        $state.Prompt | Should -Be 'domain water'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Enter) -Char ([char]13))
        $state.Prompt | Should -Be ''
        $state.Domain | Should -Be 'water'
        foreach ($result in @($state.Results)) {
            $result.Entry.Domain | Should -Be 'water'
        }
    }

    It 'reports an unknown command' {
        $state = & $script:NewState
        & $script:SendText -State $state -Text 'xyz'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Enter) -Char ([char]13))
        $state.Message | Should -Match 'unknown command'
    }

    It 'switches the language' {
        $state = & $script:NewState
        & $script:SendText -State $state -Text 'lang fr'
        Invoke-BookKey -State $state -Key (& $script:NewKey -Key ([ConsoleKey]::Enter) -Char ([char]13))
        $state.Language | Should -Be 'fr'
        (Get-BookLocalizedString -Catalog $state.Catalog -Key 'domains') | Should -Not -Be 'Domains'
    }
}
