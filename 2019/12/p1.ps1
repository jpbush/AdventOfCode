[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)

$locations = foreach($line in $content) {
    [point]::new($line)
}

$sys = [system]::new($locations)

$sys.ToString() | Write-Host
Write-Host
for($i = 0; $i -lt 1000; $i++) {
    $sys.DoTick()
    $sys.ToString() | Write-Host
    Write-Host
}

$energy = $sys.CalculateEnergy()
Write-Host "Total Engergy: $energy"
