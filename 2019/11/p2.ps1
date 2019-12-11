[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)
$robot = [Robot]::New($content.split(','))
$robot.PaintSpot(1)

While($robot.Brain.isHalted -eq $false)
{
    $robot.RunTick()
}

Write-Host "Number of unique spaces painted: $($robot.PastSpots.Keys.Count)"

# Figure out the message
# Find dimensions
$minX = $minY = 10000
$maxX = $maxY = -10000
foreach($key in $robot.PastSpots.Keys) {
    $point = $robot.PastSpots[$key].Point
    $x = $point.x
    $y = $point.y
    Write-Verbose "($x, $y)"

    $minX = [math]::min($x, $minX)
    $maxX = [math]::max($x, $maxX)
    $minY = [math]::min($y, $minY)
    $maxY = [math]::max($y, $maxY)
}
Write-Host "minX = $minX, maxX = $maxX, miny = $minY, maxY = $maxY"

# Build the message array
$yDiff = $maxY-$minY
$xDiff = $maxX-$minX
$arr = New-Object 'object[,]' ($yDiff+1),($xDiff+1)
Write-Host "Array size $($arr.Count)"
foreach($key in $robot.PastSpots.Keys) {
    $point = $robot.PastSpots[$key].Point
    $x = $point.x
    $y = $point.y
    $color = $robot.PastSpots[$key].Color
    $yI = $y-$minY
    $xI = $x-$minX
    Write-Verbose "x, y: ($xI),($yI)"
    $arr[$yI,$xI] = $color
}

$OutFile = "out.txt"
Remove-Item $OutFile -Force -ErrorAction Ignore
for($y = $minY; $y -le $maxY; $y++) {
    $line = for($x = $minX; $x -le $maxX; $x++) {
        $yI = $y-$minY
        $xI = $x-$minX
        $arr[$yI,$xI]
    }
    $line = $line -join ','
    $line | Add-Content -Path $OutFile
}
