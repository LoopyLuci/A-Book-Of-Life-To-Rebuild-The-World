#Requires -Version 5.1

<#
    The tests of the version comparison of BookOfLife.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'BookOfLife.psd1'
    Import-Module -Name $script:ModulePath -Force
    $script:Root = Find-BookRoot -StartPath $script:ModulePath
}

Describe 'Compare-BookVersion' {
    It 'reports two equal versions as equal' {
        Compare-BookVersion -Reference '1.0.0' -Difference '1.0.0' | Should -Be 0
    }

    It 'reports an older version' {
        Compare-BookVersion -Reference '0.1.0' -Difference '0.2.0' | Should -Be -1
    }

    It 'reports a newer version' {
        Compare-BookVersion -Reference '2.0.0' -Difference '1.9.9' | Should -Be 1
    }

    It 'compares the numeric parts and not the text' {
        Compare-BookVersion -Reference '1.2.0' -Difference '1.10.0' | Should -Be -1
        Compare-BookVersion -Reference '1.10.0' -Difference '1.2.0' | Should -Be 1
    }

    It 'treats a missing part as zero' {
        Compare-BookVersion -Reference '2.0' -Difference '2.0.0' | Should -Be 0
        Compare-BookVersion -Reference '2.0.1' -Difference '2.0' | Should -Be 1
    }

    It 'makes a pre-release older than the release' {
        Compare-BookVersion -Reference '0.1.0-alpha' -Difference '0.1.0' | Should -Be -1
        Compare-BookVersion -Reference '0.1.0' -Difference '0.1.0-alpha' | Should -Be 1
        Compare-BookVersion -Reference '0.1.0-alpha' -Difference '0.1.0-alpha' | Should -Be 0
    }

    It 'compares two pre-releases' {
        Compare-BookVersion -Reference '0.1.0-alpha.1' -Difference '0.1.0-alpha.2' | Should -Be -1
        Compare-BookVersion -Reference '0.1.0-alpha.2' -Difference '0.1.0-alpha.1' | Should -Be 1
    }

    It 'compares the version of the repository' {
        $manifest = Read-BookManifest -Root $script:Root
        $version = [string]$manifest['project']['version']
        $version | Should -Be '0.1.0-alpha'
        Compare-BookVersion -Reference $version -Difference '0.1.0' | Should -Be -1
        Compare-BookVersion -Reference $version -Difference '0.0.9' | Should -Be 1
    }
}
