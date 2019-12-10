
function Create-Space
{
    [CmdletBinding()]
    param(
        [string] $InFilename
    )
    $rows = (Get-Content -Path $InFilename)

    $space = @{}
    for ($y = 0; $y -lt $rows.Length; $y++) {
        for ($x = 0; $x -lt $rows[0].Length; $x++) {
            if ($rows[$y][$x] -eq '#') {
                $space["$x, $y"] = @{X = $x; Y = $y}
            }
        }
    }

    return $space
}

function Find-UnitVector {
    [CmdletBinding()]
    param(
        [hashtable] $P1,
        [hashtable] $P2
    )
    
    $diffX = $P2.X - $P1.X
    $diffY = $P2.Y - $P1.Y
    $len = [math]::Sqrt(($diffX*$diffX) + ($diffY*$diffY))
    $unitX = [math]::round(($diffX / $len), 3)
    $unitY = [math]::round(($diffY / $len), 3)
    # $unitX = ($diffX / $len)
    # $unitY = ($diffY / $len)

    return @{X = $unitX; Y = $unitY}
}

function Find-VisbleCount {
    [CmdletBinding()]
    param(
        [hashtable] $P1,
        [hashtable] $Space
    )
    $uniqueVectors = @{}
    foreach ($key in $space.Keys) {
        $P2 = $Space[$key]
        if( ($P2.X -eq $P1.X) -and ($P2.Y -eq $P1.Y) ) {
            Write-Verbose "ignore the same point"
        }
        else {
            $unitVector = (Find-UnitVector -P1 $P1 -P2 $P2)
            $uniqueVectors["$($unitVector.X), $($unitVector.Y)"] = $unitVector
        }
    }
    $uniqueCount = $($uniqueVectors.Keys).Length
    Write-Verbose "unique: $uniqueCount"

    return $uniqueCount
}

function Find-OneWithMostVisible {
    param(
        [hashtable] $Space
    )
    $biggestCount = -1
    $biggestCountPoint = $null

    foreach ($key in $space.Keys) {
        $P1 = $Space[$key]
        $count = (Find-VisbleCount -P1 $P1 -Space $space)
        
        Write-Verbose "$($P1.X), $($P1.Y), count: $count"

        if(($biggestCountPoint -eq $null) -or ($count -gt $biggestCount)) {
            $biggestCount = $count
            $biggestCountPoint = $P1
        }
    }
    
    Write-Host "count: $biggestCount, X: $($biggestCountPoint.X), Y: $($biggestCountPoint.Y)"
}
