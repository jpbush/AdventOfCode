[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)

$nano = [nanoFactory]::new($content)

$name = "FUEL"
$oreNeeded = 0
$prevOreNeeded = 0
$amount = 1000000
$stepSize = $amount
$maxOre = 1000000000000
while(($oreNeeded -lt $maxOre) -and ($stepSize -ge 1)) {
    $oreNeeded = $nano.getOreCost($name, $amount)
    if($oreNeeded -gt $maxOre) {
        $amount -= $stepSize
        $stepSize /= 10
        $oreNeeded = $prevOreNeeded
    }
    else {
        Write-Host "$oreNeeded ORE needed to produce $amount $name"
        $prevOreNeeded = $oreNeeded
    }
    $amount += $stepSize
}
