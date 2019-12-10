[CmdletBinding()]
param(
    [string] $InFilename,
    [int] $numToDestroy
)

. $PSScriptRoot/lib.ps1

$space = Create-Space -InFilename $InFilename

$result = Find-OneWithMostVisible -Space $space
$result.point
$result.count

$asteroids = Group-ByAngleSortByDist -Space $space -P1 $result.point

$angles = [System.Collections.ArrayList]($asteroids.Keys | Sort-Object)

for ($i = 0; $i -lt $numToDestroy; $i++) {
    $angle = $angles[$i % ($angles.Count)]
    
    $toDestroy = @($asteroids[$angle])[0]
    Write-Host "Destroy $($toDestroy.point.X), $($toDestroy.point.Y)"

    $asteroids[$angle] = $asteroids[$angle][1..($asteroids[$angle].Length-1)]
    
    if($asteroids[$angle].Length -lt 1) {
        Write-Verbose "Remove the angle $angle"
        $asteroids.Remove($angle)
        $angles.RemoveAt($i % $angles.Length)
    }
}

