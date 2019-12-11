
class Planet {
    [string]$ID = $null
    [Planet]$ParentPlanet = $null
    [hashtable]$ChildPlanets = @{}

    Planet([string]$ID) {
        $this.ID = $ID
    }
    
    Planet([string]$ID, [Planet]$ParentPlanet) {
        $this.ID = $ID
        $this.ParentPlanet = $ParentPlanet
    }
}

function Add-Orbit
{
    param(
        [string] $ParentID,
        [string] $ChildID,
        [hashtable] $Space
    )

    if($Space.ContainsKey($ParentID)) {
        $parentPlanet = $Space[$ParentID]
    }
    else {
        $parentPlanet = [Planet]::New($ParentID)
        $Space[$ParentID] = $parentPlanet
    }
    
    if($Space.ContainsKey($ChildID)) {
        $childPlanet = $Space[$ChildID]
    }
    else {
        $childPlanet = [Planet]::New($ChildID)
        $Space[$ChildID] = $childPlanet
    }

    if(!$parentPlanet.ChildPlanets.ContainsKey($ChildID)) {
        $parentPlanet.ChildPlanets[$ChildID] = $childPlanet
        $childPlanet.ParentPlanet = $parentPlanet
    }
    else {
        throw "Duplicate planet orbit found [$ChildID] is already orbiting [$ParentID]"
    }
}

function Count-SubOrbits
{
    param(
        [Planet] $CurrPlanet,
        [int] $CurrDepth
    )
    $orbitCount = 0
    foreach ($key in $CurrPlanet.ChildPlanets.Keys)
    {
        $childPlanet = $CurrPlanet.ChildPlanets[$key]
        $orbitCount += (Count-SubOrbits -CurrPlanet $childPlanet -CurrDepth ($CurrDepth + 1))
    }
    $orbitCount += $CurrDepth

    return $orbitCount
}

function Count-Orbits
{
    param(
        [hashtable] $Space
    )

    if(!$Space.ContainsKey("COM")) {
        throw "No center of mass key [COM] found in space"
    }

    return (Count-SubOrbits -CurrPlanet $Space['COM'] -CurrDepth 0)
}

function Create-Space
{
    param(
        [string] $InFilename
    )
    $orbitStrings = (Get-Content -Path $InFilename)

    $space = @{}
    foreach ($orbitStr in $orbitStrings) {
        $orbitPair = $orbitStr.split(')')
        Add-Orbit -ParentID $orbitPair[0] -ChildID $orbitPair[1] -Space $space
    }

    return $space
}

function Run-Part1
{
    [CmdletBinding()]
    param(
        [string] $InFilename
    )

    $space = Create-Space -InFilename $InFilename
    Write-Verbose "Planets in space = $($space.Count)"

    $orbitCount = Count-Orbits -Space $space
    Write-Host "Orbit count in space = $orbitCount"
}

function Find-PlanetOrbit
{
    param(
        [string] $DestPlanetID,
        [hashtable] $Space
    )

    if(!$space.ContainsKey($DestPlanetID)) {
        throw "Planet ID [$($DestPlanetID)] not found in space"
    }

    $orbit = New-Object Collections.Generic.List[string]
    for($currPlanet = $Space[$DestPlanetID]; $currPlanet; $currPlanet = $currPlanet.ParentPlanet) {
        $orbit.Add($currPlanet.ID)
    }
    $orbit.Reverse()

    return $orbit
}

function Find-OrbitTransferCount
{
    param(
        [string[]]$Orbit1,
        [string[]]$Orbit2
    )

    # Find last common parent
    $i = 0
    for(; (($Orbit1[$i] -eq $Orbit2[$i]) -and ($i -lt $Orbit1.Length) -and ($i -lt $Orbit2.Length)); $i++) { }
    Write-Verbose "Last common planet $($Orbit1[$i-1]), yup definitely $($Orbit2[$i-1])"

    $orbitDiff1 = 0
    for(; ($i + $orbitDiff1) -lt $Orbit1.Length - 1; $orbitDiff1++) { }

    $orbitDiff2 = 0
    for(; ($i + $orbitDiff2) -lt $Orbit2.Length - 1; $orbitDiff2++) { }

    Write-Verbose "Planet 1 diff $orbitDiff1, Planet 2 diff $orbitDiff2"

    return $orbitDiff1 + $orbitDiff2
}

function Run-Part2
{
    [CmdletBinding()]
    param(
        [string] $InFilename,
        [string] $planetID1,
        [string] $planetID2
    )

    $space = Create-Space -InFilename $InFilename
    Write-Verbose "Planets in space = $($space.Count)"

    $orbit1 = (Find-PlanetOrbit -DestPlanet $planetID1 -Space $space)
    $orbit2 = (Find-PlanetOrbit -DestPlanet $planetID2 -Space $space)
    Write-Verbose "Planet 1 orbit [$orbit1]"
    Write-Verbose "Planet 2 orbit [$orbit2]"

    $orbitTransferCount = Find-OrbitTransferCount -Orbit1 $orbit1 -Orbit2 $orbit2
    Write-Host "Orbit transfer count between $planetID1 and $planetID2 is $orbitTransferCount"
}
