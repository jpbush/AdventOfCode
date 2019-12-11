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
for($y = $minY; $y -le $maxY; $y++) {
    for($x = $minX; $x -le $maxX; $x++) {
        $color = $robot.PastSpots["$x,$y"].Color
        if($color -eq 1) {
            $fg = "White"
            $bc = "Gray"
        }
        else {
            $fg = "DarkGray"
            $bc = "Black"
            $color = 0
        }
        Write-Host "$color" -BackgroundColor $bc -ForegroundColor $fg -NoNewline
    }
    Write-Host
}
