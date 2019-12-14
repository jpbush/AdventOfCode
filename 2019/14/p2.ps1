[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)

$nano = [nanoFactory]::new($content)

$resourceName = "FUEL"
$resourceProduced = 1
$maxOre = 1000000000000
$oreNeeded = 0
$prevOreNeeded = 0
$stepSize = 1
while($stepSize -gt 0) {
    $oreNeeded = $nano.getOreCost($resourceName, $resourceProduced)
    Write-Host "$oreNeeded ORE needed to produce $resourceProduced $resourceName"
    
    if($oreNeeded -gt $maxOre) {
        $resourceProduced -= $stepSize
        $oreNeeded = $prevOreNeeded
    }
    else {
        $orePerResource = $oreNeeded / $resourceProduced
        $stepSize = [math]::floor(($maxOre - $oreNeeded) / 2 / $orePerResource)
        $resourceProduced += $stepSize
        $prevOreNeeded = $oreNeeded
    }
}
