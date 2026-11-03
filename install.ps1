<#
.SYNOPSIS
    Installs, updates or verifies Book of Life on Windows.

.DESCRIPTION
    A one line installer that does the whole job: it checks the machine,
    creates an isolated environment, installs the dependencies, builds the
    search index, verifies the install, and leaves working launchers behind.

    The install is transactional. If anything fails, the previous working
    environment is put back, so an update can never leave the machine worse
    than it found it.

.PARAMETER Command
    install (default), update, verify, uninstall.

.PARAMETER Offline
    Install from vendor\wheels without touching the network.

.PARAMETER Rebuild
    Recreate the virtual environment from scratch.

.EXAMPLE
    irm https://raw.githubusercontent.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/main/install.ps1 | iex

.EXAMPLE
    .\install.ps1 -Command update
#>
[CmdletBinding()]
param(
    [ValidateSet('install', 'update', 'verify', 'uninstall')]
    [string]$Command = 'install',

    [switch]$Offline,
    [switch]$Rebuild,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoUrl = 'https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World.git'
$Root = $PSScriptRoot
if (-not $Root -or -not (Test-Path (Join-Path $Root 'manifest.toml'))) {
    $Root = (Get-Location).Path
}

function Write-Step { param([string]$Text) Write-Host "==> $Text" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Text) Write-Host "    ok  $Text" -ForegroundColor Green }
function Write-Warn { param([string]$Text) Write-Host "    !!  $Text" -ForegroundColor Yellow }
function Write-Fail { param([string]$Text) Write-Host "    xx  $Text" -ForegroundColor Red }

function Test-Python {
    foreach ($candidate in @('python', 'python3', 'py')) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if (-not $command) { continue }
        try {
            $version = & $command.Source -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>$null
            if ($LASTEXITCODE -eq 0 -and $version) {
                $parts = $version.Trim().Split('.')
                if ([int]$parts[0] -gt 3 -or ([int]$parts[0] -eq 3 -and [int]$parts[1] -ge 11)) {
                    return $command.Source
                }
            }
        } catch { }
    }
    return $null
}

function Invoke-Installer {
    param(
        [string]$Python,
        [string[]]$Arguments
    )
    $script = Join-Path $Root 'scripts\install.py'
    & $Python $script @Arguments
    return $LASTEXITCODE
}

Write-Host "Book of Life installer  |  $Root" -ForegroundColor White

Write-Step 'Checking the machine'
$python = Test-Python
if (-not $python) {
    Write-Fail 'Python 3.11 or newer is required and was not found.'
    Write-Host '  Install it from https://www.python.org/downloads/ and run this again.' -ForegroundColor Yellow
    exit 2
}
Write-Ok "python at $python"

if (-not (Test-Path (Join-Path $Root 'manifest.toml'))) {
    Write-Fail 'manifest.toml was not found, so this is not the project root.'
    exit 2
}

$drive = (Get-PSDrive -Name ((Get-Item $Root).PSDrive.Name)).Free / 1GB
if ($drive -lt 1.5) {
    Write-Fail ("only {0:N1} GB free; 2 GB is needed" -f $drive)
    exit 2
}
Write-Ok ("{0:N1} GB free" -f $drive)

$arguments = @($Command)
if ($Offline)  { $arguments += '--offline' }
if ($Rebuild)  { $arguments += '--rebuild' }
if ($Force)    { $arguments += '--force' }

$code = Invoke-Installer -Python $python -Arguments $arguments
if ($code -ne 0) {
    Write-Fail "the '$Command' did not complete (exit $code)."
    Write-Host '  The previous working environment was kept.' -ForegroundColor Yellow
    exit $code
}

Write-Ok "the '$Command' completed"
Write-Host ''
Write-Host '  start the local server:  .venv\Scripts\python scripts\serve.py' -ForegroundColor Gray
Write-Host '  run the pipeline:        .venv\Scripts\python scripts\local_pipeline.py' -ForegroundColor Gray
Write-Host ''
exit 0
