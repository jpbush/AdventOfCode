[CmdletBinding()]
param(
    [string] $InFilename,
    [int[]] $In
)

. $PSScriptRoot/9.ps1

$content = (Get-Content $InFilename)
$program = [ProgramState]::New($content.split(','), 0, 0, $In, @(), 0)
$program = Run-OpCodes -state $program
Write-Verbose "program: [$($content.split(',') -join ',')]"
Write-Host "output:  [$($program.outBuff -join ',')]"
