$ErrorActionPreference = 'Stop'

Import-Module Pester -RequiredVersion 5.7.1 -Force

$repoRoot = Split-Path -Parent $PSScriptRoot
$configuration = New-PesterConfiguration
$configuration.Run.Path = Join-Path $repoRoot 'tests/powershell'
$configuration.Run.Exit = $true
$configuration.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $configuration
