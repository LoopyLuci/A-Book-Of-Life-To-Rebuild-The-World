#Requires -Version 5.1

<#
    The tests of the YAML parser of BookOfLife.

    They run under Pester and under the standalone runner in run-tests.ps1:
    both provide Describe, It, BeforeAll and Should.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'BookOfLife.psd1'
    Import-Module -Name $script:ModulePath -Force

    $script:Sample = @"
# a leading comment
name: "quoted value"
count: 12
ratio: 1.5
flag: true
missing: null
tilde: ~
tags:
- one
- two
inline: [a, b, c]
empty: []
nested:
  inner: value
  deeper:
    leaf: 3
list:
- title: First
  license: CC-BY-SA
- title: Second
  license: MIT
people:
- name: Ada
  age: 36
trailing: value  # a trailing comment
"@
}

Describe 'ConvertFrom-BookYaml' {
    It 'parses a mapping' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        ($parsed -is [hashtable]) | Should -Be $true
        $parsed['name'] | Should -Be 'quoted value'
        $parsed['count'] | Should -Be 12
        $parsed['ratio'] | Should -Be 1.5
        $parsed['flag'] | Should -Be $true
    }

    It 'parses null and the null shorthand' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        $parsed['missing'] | Should -BeNullOrEmpty
        $parsed['tilde'] | Should -BeNullOrEmpty
    }

    It 'parses a block sequence at the indentation of its key' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        @($parsed['tags']).Count | Should -Be 2
        $parsed['tags'][0] | Should -Be 'one'
        $parsed['tags'][1] | Should -Be 'two'
    }

    It 'parses an inline flow list' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        @($parsed['inline']).Count | Should -Be 3
        $parsed['inline'][2] | Should -Be 'c'
    }

    It 'parses an empty inline flow list' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        @($parsed['empty']).Count | Should -Be 0
    }

    It 'parses nested mappings' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        $parsed['nested']['inner'] | Should -Be 'value'
        $parsed['nested']['deeper']['leaf'] | Should -Be 3
    }

    It 'parses a sequence of mappings' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        @($parsed['list']).Count | Should -Be 2
        $parsed['list'][0]['title'] | Should -Be 'First'
        $parsed['list'][0]['license'] | Should -Be 'CC-BY-SA'
        $parsed['list'][1]['title'] | Should -Be 'Second'
    }

    It 'parses a sequence of mappings that continue on the next line' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        @($parsed['people']).Count | Should -Be 1
        $parsed['people'][0]['name'] | Should -Be 'Ada'
        $parsed['people'][0]['age'] | Should -Be 36
    }

    It 'ignores whole line and trailing comments' {
        $parsed = ConvertFrom-BookYaml -Text $script:Sample
        $parsed['trailing'] | Should -Be 'value'
        $parsed.ContainsKey('a leading comment') | Should -Be $false
    }

    It 'keeps a colon that is part of an identifier' {
        $parsed = ConvertFrom-BookYaml -Text 'id: pnk:01HZX0K8J9Q7R3VY6T2M4B8N1W'
        $parsed['id'] | Should -Be 'pnk:01HZX0K8J9Q7R3VY6T2M4B8N1W'
    }

    It 'expands the escape sequences of a double quoted scalar' {
        $parsed = ConvertFrom-BookYaml -Text 'value: "a\tb\nc"'
        $parsed['value'] | Should -Be "a`tb`nc"
    }

    It 'keeps the content of a single quoted scalar' {
        $parsed = ConvertFrom-BookYaml -Text "value: 'it''s here'"
        $parsed['value'] | Should -Be "it's here"
    }

    It 'returns nothing for an empty document' {
        $parsed = ConvertFrom-BookYaml -Text ''
        $parsed | Should -BeNullOrEmpty
    }

    It 'reads a sidecar of the repository' {
        $root = Find-BookRoot -StartPath $script:ModulePath
        $sidecar = Join-Path -Path $root -ChildPath 'sidecars\water\rainwater-harvesting.pnk.yaml'
        $parsed = Read-BookYamlFile -Path $sidecar
        $parsed['title'] | Should -Be 'Rainwater Harvesting'
        $parsed['domain'] | Should -Be 'water'
        @($parsed['tags']).Count | Should -Be 5
        @($parsed['prerequisites']).Count | Should -Be 0
        $parsed['verification']['status'] | Should -Be 'draft'
        @($parsed['sources']).Count | Should -Be 3
        $parsed['sources'][0]['title'] | Should -Be 'WHO Guidelines for Drinking-water Quality'
    }

    It 'reads every sidecar of the repository' {
        $root = Find-BookRoot -StartPath $script:ModulePath
        $sidecars = @(Get-ChildItem -LiteralPath (Join-Path -Path $root -ChildPath 'sidecars') -Recurse -File -Filter '*.pnk.yaml')
        $sidecars.Count | Should -Be $sidecars.Count
        ($sidecars.Count -gt 100) | Should -Be $true
        foreach ($sidecar in $sidecars) {
            { Read-BookYamlFile -Path $sidecar.FullName } | Should -Not -Throw
        }
    }
}
