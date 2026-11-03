#Requires -Version 5.1

<#
    The tests of the translations of BookOfLife.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'BookOfLife.psd1'
    Import-Module -Name $script:ModulePath -Force
    $script:Root = Find-BookRoot -StartPath $script:ModulePath
    $script:StringsPath = Join-Path -Path $script:Root -ChildPath 'i18n\strings'
}

Describe 'Import-BookLanguageCatalog' {
    It 'loads the English catalogue' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'en'
        $catalog.Language | Should -Be 'en'
        $catalog.Fallback | Should -Be $false
        (@($catalog.Strings.Keys).Count -gt 20) | Should -Be $true
    }

    It 'falls back to English for a language that does not exist' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'zz'
        $catalog.Language | Should -Be 'en'
        $catalog.Fallback | Should -Be $true
        (Get-BookLocalizedString -Catalog $catalog -Key 'domains') | Should -Be 'Domains'
    }

    It 'falls back to English when the catalogue file is missing' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'en' -FallbackLanguage 'zz'
        $catalog.Language | Should -Be 'en'
        (Get-BookLocalizedString -Catalog $catalog -Key 'domains') | Should -Be 'Domains'
    }

    It 'falls back to English when the whole directory is missing' {
        $missing = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('abook-no-i18n-' + [System.Guid]::NewGuid().ToString('N'))
        $catalog = Import-BookLanguageCatalog -Path $missing -Language 'fr'
        $catalog.Language | Should -Be 'en'
        $catalog.Fallback | Should -Be $true
        (Get-BookLocalizedString -Catalog $catalog -Key 'search') | Should -Be 'Search'
    }

    It 'switches to another language' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'fr'
        $catalog.Language | Should -Be 'fr'
        $catalog.Fallback | Should -Be $false
        (Get-BookLocalizedString -Catalog $catalog -Key 'domains') | Should -Not -Be 'Domains'
    }

    It 'offers the nine languages of the repository' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'en'
        $available = @($catalog.Available)
        foreach ($code in @('en', 'es', 'fr', 'de', 'pt', 'hi', 'ar', 'sw', 'zh')) {
            $available | Should -Contain $code
        }
    }
}

Describe 'Get-BookLocalizedString' {
    It 'returns the string of the key' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'en'
        (Get-BookLocalizedString -Catalog $catalog -Key 'search') | Should -Be 'Search'
    }

    It 'returns the key itself when the string is unknown' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'en'
        (Get-BookLocalizedString -Catalog $catalog -Key 'no_such_string_at_all') | Should -Be 'no_such_string_at_all'
    }

    It 'fills in the placeholders' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'en'
        (Get-BookLocalizedString -Catalog $catalog -Key 'entry_count' -Values @{ count = 42 }) | Should -Be '42 entries'
    }

    It 'keeps the placeholders when no value is given' {
        $catalog = Import-BookLanguageCatalog -Path $script:StringsPath -Language 'en'
        (Get-BookLocalizedString -Catalog $catalog -Key 'entry_count') | Should -Be '{count} entries'
    }

    It 'names every language in its own language' {
        (Get-BookLanguageName -Language 'en') | Should -Be 'English'
        (Get-BookLanguageName -Language 'zz') | Should -Be 'zz'
    }
}
