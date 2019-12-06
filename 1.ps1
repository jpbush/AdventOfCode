
function Resolve-FuelBasic
{
    param(
        [int] $Mass
    )

    Return [math]::floor($Mass / 3) - 2
}

function Resolve-FuelRecurse
{
    param(
        [int] $Mass
    )

    $fuelMass = [math]::floor($Mass / 3) - 2
    if($fuelMass -le 0) {
        return 0
    }
    else {
        return $fuelMass + (Resolve-FuelRecurse -Mass $fuelMass)
    }
}

function Run-Part1 {
    [CmdletBinding()]
    param(
        [string] $InFilename
    )
    $total = 0
    foreach ($mass in Get-Content $InFilename) {
        $total += Resolve-FuelBasic -Mass $mass
    }

    Write-Host "Total fuel needed: $total"
}

function Run-Part2 {
    [CmdletBinding()]
    param(
        [string] $InFilename
    )
    $total = 0
    foreach ($mass in Get-Content $InFilename) {
        $total += Resolve-FuelRecurse -Mass $mass
    }
    
    Write-Host "Total fuel needed: $total"
}
