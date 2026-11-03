#Requires -Version 5.1

<#
    The tests of the search and the ranking of BookOfLife.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'BookOfLife.psd1'
    Import-Module -Name $script:ModulePath -Force
    $script:Root = Find-BookRoot -StartPath $script:ModulePath

    function ConvertTo-BookTestEntry {
        param(
            [string]$Id,
            [string]$Title,
            [string]$Domain = 'water',
            [string[]]$Tags = @(),
            [string]$Body = '',
            [string]$Safety = 'green',
            [string]$Difficulty = 'novice'
        )
        return [pscustomobject]@{
            Id             = $Id
            Title          = $Title
            Domain         = $Domain
            Slug           = $Id
            Path           = ''
            Tags           = $Tags
            Difficulty     = $Difficulty
            Safety         = $Safety
            TimeToComplete = ''
            Prerequisites  = @()
            Materials      = @()
            Tools          = @()
            Hazards        = @()
            Sources        = @()
            Verification   = @{ status = 'draft'; date = ''; reviewers = ''; tested_by = ''; location = '' }
            Links          = @()
            Body           = $Body
            TitleLower     = $Title.ToLowerInvariant()
            TagsLower      = ($Tags -join ' ').ToLowerInvariant()
            BodyLower      = $Body.ToLowerInvariant()
            TitleTokens    = (Get-BookToken -Text $Title)
            TagTokens      = (Get-BookToken -Text ($Tags -join ' '))
            WordCount      = 0
        }
    }

    $script:Entries = @(
        (ConvertTo-BookTestEntry -Id 'title' -Title 'Rainwater Storage' -Tags @('tank') -Body 'nothing here'),
        (ConvertTo-BookTestEntry -Id 'tags' -Title 'Cistern Basics' -Tags @('rainwater', 'storage') -Body 'nothing here'),
        (ConvertTo-BookTestEntry -Id 'body' -Title 'Cistern Basics Two' -Tags @('tank') -Body 'a note about rainwater'),
        (ConvertTo-BookTestEntry -Id 'other' -Title 'Solar Still' -Domain 'energy' -Tags @('sun') -Body 'nothing here' -Safety 'red' -Difficulty 'master')
    )
    $script:Corpus = [pscustomobject]@{
        Entries         = $script:Entries
        Domains         = @('water', 'energy')
        DomainCounts    = @{ water = 3; energy = 1 }
        SafetyCounts    = @{ green = 3; red = 1 }
        DifficultyCounts = @{ novice = 3; master = 1 }
        EntriesById     = @{}
        EntriesByDomain = @{}
        Version         = '0.1.0-alpha'
        Root            = $script:Root
        IndexPresent    = $false
        Source          = 'filesystem'
        Warnings        = @()
    }
}

Describe 'Search-BookEntry' {
    It 'ranks a title match above a tag match and a tag match above a body match' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query 'rainwater'
        $results.Count | Should -Be 3
        $results[0].Entry.Id | Should -Be 'title'
        $results[1].Entry.Id | Should -Be 'tags'
        $results[2].Entry.Id | Should -Be 'body'
    }

    It 'reports the field that produced the match' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query 'rainwater'
        $results[0].MatchedField | Should -Be 'title'
        $results[1].MatchedField | Should -Be 'tags'
        $results[2].MatchedField | Should -Be 'body'
    }

    It 'leaves out the entries that do not match at all' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query 'rainwater'
        foreach ($result in $results) {
            $result.Entry.Id | Should -Not -Be 'other'
        }
    }

    It 'returns every entry for an empty query' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query ''
        $results.Count | Should -Be 4
    }

    It 'filters by domain' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query 'rainwater' -Domain 'energy'
        $results.Count | Should -Be 0
        $results = Search-BookEntry -Corpus $script:Corpus -Query '' -Domain 'energy'
        $results.Count | Should -Be 1
    }

    It 'filters by safety level' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query '' -Safety 'red'
        $results.Count | Should -Be 1
        $results[0].Entry.Id | Should -Be 'other'
    }

    It 'filters by difficulty' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query '' -Difficulty 'master'
        $results.Count | Should -Be 1
        $results[0].Entry.Id | Should -Be 'other'
    }

    It 'honours the limit' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query '' -Limit 2
        $results.Count | Should -Be 2
    }

    It 'finds a prefix of a title' {
        $results = Search-BookEntry -Corpus $script:Corpus -Query 'rain'
        $results.Count | Should -Be 3
        $results[0].Entry.Id | Should -Be 'title'
    }
}

Describe 'Search-BookEntry on the real corpus' {
    It 'finds the entries of a domain' {
        $corpus = Get-BookCorpus -Root $script:Root
        $results = Search-BookEntry -Corpus $corpus -Query 'water' -Domain 'water'
        ($results.Count -gt 0) | Should -Be $true
        foreach ($result in $results) {
            $result.Entry.Domain | Should -Be 'water'
        }
    }

    It 'puts a title match first' {
        $corpus = Get-BookCorpus -Root $script:Root
        $results = Search-BookEntry -Corpus $corpus -Query 'water purification' -Limit 10
        ($results.Count -gt 0) | Should -Be $true
        $results[0].Tier | Should -Be 3
    }

    It 'never returns the same entry twice' {
        $corpus = Get-BookCorpus -Root $script:Root
        $results = Search-BookEntry -Corpus $corpus -Query 'water'
        $ids = @($results | ForEach-Object { $_.Entry.Id })
        @($ids | Sort-Object -Unique).Count | Should -Be $ids.Count
    }
}

Describe 'Get-BookQuickJump' {
    It 'puts a title that starts with the query first' {
        $corpus = Get-BookCorpus -Root $script:Root
        $entries = Get-BookQuickJump -Corpus $corpus -Query 'water' -Limit 10
        $entries.Count | Should -Be 10
        $entries[0].TitleLower | Should -Match '^water'
        $entries[4].TitleLower | Should -Match '^water'
        $entries[5].TitleLower | Should -Not -Match '^water'
    }

    It 'returns the first entries for an empty query' {
        $corpus = Get-BookCorpus -Root $script:Root
        $entries = Get-BookQuickJump -Corpus $corpus -Query '' -Limit 3
        $entries.Count | Should -Be 3
    }
}
