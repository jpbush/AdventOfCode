
param(
    [string] $inFileName
)

class point {
    [int]$x = 0
    [int]$y = 0

    point() { }

    point([int] $x, [int] $y) {
        $this.x = $x
        $this.y = $y
    }

    point([point] $p)
    {
        $this.x = $p.x
        $this.y = $p.y
    }

    point ([string] $str) 
    {
        $split = $str.split(',')
        $this.x = $split[0]
        $this.y = $split[1]
    }

    Add ([point] $p)
    {
        $this.x += $p.x
        $this.y += $p.y
    }

    AddVector ([vector] $v)
    {
        $this.x += $v.x
        $this.y += $v.y
    }

    [string] Hash () 
    {
        return "$($this.x),$($this.y)"
    }

}

class vector {
    [int]$x = 0
    [int]$y = 0

    vector() { }

    vector([vector] $v)
    {
        $this.x = $v.x
        $this.y = $v.y
    }

    Add ([vector] $v)
    {
        $this.x += $v.x
        $this.y += $v.y
    }

    [string] Hash () 
    {
        return "x: $($this.x), y: $($this.y)"
    }
}

function Resolve-VectorStr
{
    param(
        [string] $VectorStr
    )

    $direction = $VectorStr.Substring(0, 1)
    $length = [int]$VectorStr.Substring(1)

    $v = New-Object vector
    switch ($direction) {
        "U" { $v.y = $length }
        "D" { $v.y = $length * -1 }
        "L" { $v.x = $length * -1 }
        "R" { $v.x = $length }
    }

    Write-Verbose "x = $($v.x), y = $($v.y)"

    return $v
}

function Add-PathSegment
{
    param(
        [point] $startPoint,
        [vector] $Vector,
        [hashtable] $path
    )

    $finishPoint = [point]::New($startPoint)
    $finishPoint.AddVector($Vector)

    for($p = [point]::New($startPoint); $p.x -lt $finishPoint.x; $p.x++) {
        $path[$p.Hash()] = $true
    }
    for($p = [point]::New($startPoint); $p.x -gt $finishPoint.x; $p.x--) {
        $path[$p.Hash()] = $true
    }
    for($p = [point]::New($startPoint); $p.y -lt $finishPoint.y; $p.y++) {
        $path[$p.Hash()] = $true
    }
    for($p = [point]::New($startPoint); $p.y -gt $finishPoint.y; $p.y--) {
        $path[$p.Hash()] = $true
    }
}

function Build-Intersections
{
    param(
        [string[]] $pathVectors,
        [hashtable] $otherPath,
        [hashtable] $intersections
    )
    $currPoint = [point]::New()

    foreach($vectorStr in $pathVectors) {
        $vector = Resolve-VectorStr -VectorStr $vectorStr
        
        $finishPoint = [point]::New($currPoint)
        $finishPoint.AddVector($vector)

        for($p = [point]::New($currPoint); $p.x -lt $finishPoint.x; $p.x++) {
            if($otherPath[$p.Hash()]) {
                $intersections[$p.Hash()] = $true
            }
        }
        for($p = [point]::New($currPoint); $p.x -gt $finishPoint.x; $p.x--) {
            if($otherPath[$p.Hash()]) {
                $intersections[$p.Hash()] = $true
            }
        }
        for($p = [point]::New($currPoint); $p.y -lt $finishPoint.y; $p.y++) {
            if($otherPath[$p.Hash()]) {
                $intersections[$p.Hash()] = $true
            }
        }
        for($p = [point]::New($currPoint); $p.y -gt $finishPoint.y; $p.y--) {
            if($otherPath[$p.Hash()]) {
                $intersections[$p.Hash()] = $true
            }
        }

        $currPoint.AddVector($vector)
    }
    return $intersections
}

function Build-WirePath
{
    param(
        [string[]] $pathVectors
    )

    $path = @{}
    $currPoint = [point]::New()

    foreach($vectorStr in $pathVectors) {
        $vector = Resolve-VectorStr -VectorStr $vectorStr
        Add-PathSegment -startPoint $currPoint -Vector $vector -path $path
        $currPoint.AddVector($vector)
    }

    return $path
}

function Find-ClosestIntersection
{
    param(
        [string] $inFileName
    )
    if(!(Test-Path -path $inFileName)) {
        throw "inFileName: [$inFileName] does not exist"
    }

    $content = Get-Content -Path $inFileName
    if($content.Length -ne 2) {
        throw "2 paths not found in file"
    }

    $pathVectors1 = $content[0].split(',')
    $pathVectors2 = $content[1].split(',')

    Write-Host "Building path 1"
    $path1 = Build-WirePath -pathVectors $pathVectors1
    Write-Host "Building path 2"
    $intersections = @{}
    $intersections = Build-Intersections -pathVectors $pathVectors2 -otherPath $path1 -intersections $intersections
    Write-Host "Intersections: "

    $minDist = -1
    foreach($key in $intersections.Keys)
    {
        $p = [point]::New($key)
        $dist = [int]$p.x + [int]$p.y
        Write-Host "Key: [$key], p.x: [$($p.x)], p.y: [$($p.y)], Dist: $dist"
        if((($dist -lt $minDist) -or ($minDist -lt 0)) -and ($dist -gt 0)) {
            $minDist = $dist
        }
    }

    return $minDist
}

Find-ClosestIntersection -inFileName $inFileName
