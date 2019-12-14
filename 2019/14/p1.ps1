[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)

$nano = [nanoFactory]::new($content)

$resourceName = "FUEL"
$resourceProduced = 1
$oreNeeded = $nano.getOreCost($resourceName, $resourceProduced)

Write-Host "$oreNeeded ORE needed to produce $resourceProduced $resourceName"
