#Requires -Version 5.1

<#
    The tests of the corpus loader of BookOfLife.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'BookOfLife.psd1'
    Import-Module -Name $script:ModulePath -Force
    $script:Root = Find-BookRoot -StartPath $script:ModulePath
    $script:Corpus = Get-BookCorpus -Root $script:Root
}

Describe 'Find-BookRoot' {
    It 'finds the repository root' {
        (Test-Path -LiteralPath (Join-Path -Path $script:Root -ChildPath 'manifest.toml') -PathType Leaf) | Should -Be $true
    }

    It 'finds the root when it starts from another working directory' {
        $before = (Get-Location).Path
        try {
            Set-Location -Path ([System.IO.Path]::GetTempPath())
            $found = Find-BookRoot -StartPath $script:ModulePath
            $found | Should -Be $script:Root
        }
        finally {
            Set-Location -Path $before
        }
    }
}

Describe 'Get-BookCorpus' {
    It 'loads the entries' {
        $count = @($script:Corpus.Entries).Count
        ($count -gt 100) | Should -Be $true
    }

    It 'loads the sixteen domains of the manifest' {
        $manifest = Read-BookManifest -Root $script:Root
        $declared = @($manifest['domains']['list'])
        @($script:Corpus.Domains).Count | Should -Be $declared.Count
        foreach ($domain in $declared) {
            @($script:Corpus.Domains) | Should -Contain $domain
        }
    }

    It 'counts every entry in exactly one domain' {
        $total = 0
        foreach ($domain in @($script:Corpus.Domains)) {
            $total += [int]$script:Corpus.DomainCounts[$domain]
        }
        $total | Should -Be @($script:Corpus.Entries).Count
    }

    It 'gives every entry an id, a title and a domain' {
        foreach ($entry in @($script:Corpus.Entries)) {
            $entry.Id | Should -Not -Be ''
            $entry.Title | Should -Not -Be ''
            $entry.Domain | Should -Not -Be ''
        }
    }

    It 'reads the Markdown body of every entry' {
        $missing = @($script:Corpus.Entries | Where-Object { $_.Body.Length -eq 0 })
        $missing.Count | Should -Be 0
    }

    It 'reads the metadata of every entry' {
        $entry = @($script:Corpus.Entries | Where-Object { $_.Domain -eq 'water' })[0]
        ($entry.Tags.Count -gt 0) | Should -Be $true
        $entry.Difficulty | Should -Not -Be ''
        $entry.Safety | Should -Not -Be ''
        $entry.Verification['status'] | Should -Not -Be ''
    }

    It 'reports the version of manifest.toml' {
        $script:Corpus.Version | Should -Be '0.1.0-alpha'
    }
}

Describe 'Get-BookCorpus without an index' {
    It 'scans the sidecars and the domains when build/index.db is missing' {
        $fixture = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('abook-fixture-' + [System.Guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path $fixture | Out-Null
            New-Item -ItemType Directory -Path (Join-Path -Path $fixture -ChildPath 'sidecars\water') | Out-Null
            New-Item -ItemType Directory -Path (Join-Path -Path $fixture -ChildPath 'domains\water') | Out-Null
            Copy-Item -LiteralPath (Join-Path -Path $script:Root -ChildPath 'manifest.toml') -Destination $fixture
            Copy-Item -LiteralPath (Join-Path -Path $script:Root -ChildPath 'sidecars\water\rainwater-harvesting.pnk.yaml') -Destination (Join-Path -Path $fixture -ChildPath 'sidecars\water')
            Copy-Item -LiteralPath (Join-Path -Path $script:Root -ChildPath 'domains\water\rainwater-harvesting.md') -Destination (Join-Path -Path $fixture -ChildPath 'domains\water')

            (Test-Path -LiteralPath (Join-Path -Path $fixture -ChildPath 'build\index.db')) | Should -Be $false
            $corpus = Get-BookCorpus -Root $fixture
            $corpus.IndexPresent | Should -Be $false
            @($corpus.Entries).Count | Should -Be 1
            $corpus.Entries[0].Title | Should -Be 'Rainwater Harvesting'
            ($corpus.Entries[0].Body.Length -gt 0) | Should -Be $true
        }
        finally {
            Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
