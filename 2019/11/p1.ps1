[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)
$robot = [Robot]::New($content.split(','))

While($robot.Brain.isHalted -eq $false)
{
    $robot.RunTick()
}

Write-Host "Number of unique spaces painted: $($robot.PastSpots.Keys.Count)"
