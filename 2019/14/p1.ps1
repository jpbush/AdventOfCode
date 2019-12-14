[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)

$nano = [nanoFactory]::new($content)

$name = "FUEL"
$amount = 1
$oreNeeded = $nano.getOreCost($name, $amount)

Write-Host "$oreNeeded ore needed to produce $amount $name"