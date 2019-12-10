
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

function Find-Angle {
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

function Find-Distance {
    [CmdletBinding()]
    param(
        [hashtable] $P1,
        [hashtable] $P2
    )
    
    $diffX = $P2.X - $P1.X
    $diffY = $P2.Y - $P1.Y
    $len = [math]::Sqrt(($diffX*$diffX) + ($diffY*$diffY))
    return $len
}

function Find-VectorAngle {
    [CmdletBinding()]
    param(
        [hashtable] $P1
    )

    if ($P1.X -eq 0) {
        # can't divide by 0
        if($P1.Y -ge 0) {
            return 90
        }
        else {
            return 270
        }
    }
    
    $angle = [math]::round(([math]::atan($P1.Y / $P1.X) * 180 / [math]::pi), 3)
    if($P1.Y -ge 0) {
        if($P1.X -ge 0) {
            # quad 1
        }
        else {
            # quad 2
            $angle += 180
        }
    }
    else {
        if($P1.X -ge 0) {
            # quad 4
            $angle += 360
        }
        else {
            # quad 3
            $angle += 180
        }
    }

    return $angle
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
            $unitKey = "$($unitVector.X), $($unitVector.Y)"
            $uniqueVectors[$unitKey] = $unitVector
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
    
    return @{point = $biggestCountPoint; count = $biggestCount}
}

function Group-ByAngleSortByDist {
    param(
        [hashtable] $Space,
        [hashtable] $P1
    )

    Write-Verbose "Group-ByAngleSortByDist"

    $asteroids = @{}
    foreach ($key in $space.Keys) {
        $P2 = $Space[$key]
        if( ($P2.X -eq $P1.X) -and ($P2.Y -eq $P1.Y) ) {
            Write-Verbose "ignore the same point"
        }
        else {
            $angle = ((Find-VectorAngle -P1 (Find-UnitVector -P1 $P1 -P2 $P2)) + 450) % 360
            $distance = Find-Distance -P1 $P1 -P2 $P2
            
            Write-Verbose "($($P2.X), $($P2.X)), angle $angle, dist $dist"
            if ($asteroids.ContainsKey($angle)) {
                $asteroids[$angle] += @(@{angle = $angle; point = $P2; dist = $distance})
            }
            else {
                $asteroids[$angle] = @(@{angle = $angle; point = $P2; dist = $distance})
            }
        }
    }

    $uniqueCount = $($asteroids.Keys).Length
    Write-Verbose "unique: $uniqueCount"

    # Sort by distance, angle
    $asteroids2 = @{}
    foreach ($key in $asteroids.Keys) {
        $sorted = $asteroids[$key] | Sort-Object -Property dist
        $asteroids2[$key] = $sorted
    }
    $asteroids = $asteroids2

    $uniqueCount = $($asteroids.Keys).Length
    Write-Verbose "unique: $uniqueCount"

    return $asteroids
}
