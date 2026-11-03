#!/usr/bin/env pwsh
# Verification script for the Book of Life PowerShell app.
# Run: pwsh -NoProfile -File apps/powershell/tests/run-tests.ps1

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'BookOfLife.psm1'

$script:Failures = 0
$script:Checks = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:Checks++
    if ($Condition) {
        Write-Host "  ok  $Message" -ForegroundColor DarkGreen
    } else {
        Write-Host "  xx  $Message" -ForegroundColor Red
        $script:Failures++
    }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    Assert-True ($Expected -eq $Actual) "$Message (expected '$Expected', got '$Actual')"
}

Write-Host "Book of Life PowerShell tests" -ForegroundColor Cyan

Import-Module $modulePath -Force -ErrorAction Stop
Write-Host "  ok  the module imports"

$root = Get-AbookRoot
Assert-True (Test-Path -LiteralPath (Join-Path $root 'manifest.toml')) 'the repository root is found'

# ---------------------------------------------------------------- YAML ----
$yaml = @'
id: pnk:01ABC/chemistry/demo
title: Demo Entry
tags: [alpha, beta-gamma]
difficulty: novice
safety: yellow
sources:
  - title: A Public Manual
    license: public-domain
  - title: Another Source
    license: CC-BY-4.0
verification:
  status: draft
  reviewers:
    - Alice
    - Bob
resource_budget:
  batch: one
  labor_hours: 3
empty_list: []
'@

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("abook-yaml-{0}.yaml" -f ([guid]::NewGuid()))
Set-Content -LiteralPath $temp -Value $yaml -Encoding UTF8
$parsed = ConvertFrom-AbookYaml -Path $temp
Remove-Item -LiteralPath $temp -Force

Assert-Equal 'Demo Entry' $parsed['title'] 'a scalar is parsed'
Assert-Equal 'novice' $parsed['difficulty'] 'a second scalar is parsed'
Assert-Equal 2 (@($parsed['tags']).Count) 'an inline list is parsed'
Assert-Equal 'alpha' (@($parsed['tags'])[0]) 'an inline list keeps its order'
Assert-Equal 'beta-gamma' (@($parsed['tags'])[1]) 'an inline list keeps its hyphens'
Assert-Equal 2 (@($parsed['sources']).Count) 'a sequence of mappings is parsed'
Assert-Equal 'A Public Manual' (@($parsed['sources'])[0])['title'] 'a sequence item keeps its keys'
Assert-Equal 'public-domain' (@($parsed['sources'])[0])['license'] 'a sequence item keeps every key'
Assert-Equal 'draft' $parsed['verification']['status'] 'a nested mapping is parsed'
Assert-Equal 2 (@($parsed['verification']['reviewers']).Count) 'a nested sequence is parsed'
Assert-Equal 3 $parsed['resource_budget']['labor_hours'] 'a nested number is parsed'
Assert-Equal 0 (@($parsed['empty_list']).Count) 'an empty inline list is parsed'

# -------------------------------------------------------------- corpus ----
$corpus = Import-AbookCorpus -Root $root
Assert-True ($corpus.Entries.Count -gt 100) "the corpus loads ($($corpus.Entries.Count) entries)"
Assert-True ($corpus.Counts.Count -ge 16) "the corpus has the domains ($($corpus.Counts.Count))"

$first = $corpus.Entries[0]
Assert-True (-not [string]::IsNullOrWhiteSpace($first.Title)) 'an entry has a title'
Assert-True (-not [string]::IsNullOrWhiteSpace($first.Body)) 'an entry has a body'
Assert-True ($first.Body.Contains('## Overview')) 'an entry body has the Overview section'

$domains = Get-AbookDomains -Root $root
Assert-True ($domains.Count -ge 16) "the manifest lists the domains ($($domains.Count))"
Assert-True ($domains -contains 'chemistry') 'the manifest lists the new domains'

# -------------------------------------------------------------- search ----
$results = Search-Abook -Query 'fire' -Corpus $corpus
Assert-True ($results.Count -gt 0) "a search finds something ($($results.Count) hits)"
$titleHit = Search-Abook -Query 'Making Fire' -Corpus $corpus
Assert-True ($titleHit.Count -gt 0) 'a title search finds the entry'
Assert-Equal 'Making Fire' $titleHit[0].Entry.Title 'a title match ranks first'

$filtered = Search-Abook -Query 'fire' -Domain 'survival' -Corpus $corpus
Assert-True ($filtered.Count -le $results.Count) 'a domain filter narrows the results'
$allSurvival = @($filtered | Where-Object { $_.Entry.Domain -ne 'survival' })
Assert-Equal 0 $allSurvival.Count 'a domain filter only returns that domain'

$none = Search-Abook -Query 'zzzzznotfoundzzzzz' -Corpus $corpus
Assert-Equal 0 @($none).Count 'a search with no match returns nothing'

# ---------------------------------------------------------------- i18n ----
$languages = Get-AbookSupportedLanguages -Root $root
Assert-True ($languages.Count -ge 9) "the languages are listed ($($languages.Count))"
Assert-True ($languages -contains 'es') 'a translated language is present'

$enString = Get-AbookString -Key 'domains' -Language 'en' -Root $root
Assert-Equal 'Domains' $enString 'the English interface string is read'
$esString = Get-AbookString -Key 'domains' -Language 'es' -Root $root
Assert-True (-not [string]::IsNullOrWhiteSpace($esString)) 'a translated interface string is read'
$fallback = Get-AbookString -Key 'domains' -Language 'zz' -Root $root
Assert-Equal 'Domains' $fallback 'an unknown language falls back to English'

# ----------------------------------------------------------- disclaimer ---
$disclaimer = Get-AbookDisclaimer -Root $root
Assert-True ($disclaimer.Length -gt 40) 'the disclaimer is read from the document'
Assert-True ($disclaimer -match 'sole source') 'the disclaimer mentions a sole source'

# -------------------------------------------------------------- version ---
Assert-Equal 1 (Compare-AbookVersion -Left 'v1.0.1' -Right '1.0.0') 'a higher patch is newer'
Assert-Equal 0 (Compare-AbookVersion -Left '1.0.0' -Right 'v1.0.0') 'a leading v is ignored'
Assert-Equal 1 (Compare-AbookVersion -Left '1.0.0' -Right '1.0.0-rc1') 'a release beats a pre-release'
Assert-Equal -1 (Compare-AbookVersion -Left '1.0.0-rc1' -Right '1.0.0') 'a pre-release loses to a release'
Assert-Equal 1 (Compare-AbookVersion -Left '2.0.0' -Right '1.9.9') 'a higher minor is newer'

# ------------------------------------------------------------- settings ---
$settings = Get-AbookSettings
Assert-True ($settings.ContainsKey('language')) 'the settings have a language'
Assert-True ($settings.ContainsKey('recent')) 'the settings have a recent list'

Write-Host ''
if ($script:Failures -gt 0) {
    Write-Host "$($script:Failures) of $($script:Checks) checks FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "all $($script:Checks) checks passed" -ForegroundColor Green
exit 0
