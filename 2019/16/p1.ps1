[CmdletBinding()]
param(
    [string] $InFilename,
    [int[]] $pattern,
    [int] $phase
)

. $PSScriptRoot/lib.ps1

$content = Get-Content $InFilename

$result = CalcFFTUpToPhase -inStr $content -pattern $pattern -phase $phase
Write-Host "After $phase phases: $result"
