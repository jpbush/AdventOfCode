[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)

$posistions = foreach($line in $content) {
    [point]::new($line)
}

$sys = [system]::new($posistions)
Write-Host "Starting state:"
$sys.ToString() | Write-Host
Write-Host

$firstState = $sys.GetHash()
$matchAxis = @(0,0,0)
for($axis = 0; $axis -lt 3; $axis++) {
    Write-Host "Axis: $axis"
    $sys.tick = 0
    do {
        $sys.DoTick($axis)
        $currState = $sys.GetHash()
        if(!($sys.tick % 10000)) {
            Write-Verbose $sys.tick
        }
    } while ($currState -ne $firstState) 
    $matchAxis[$axis] = $sys.tick
    Write-Host "Axis: $axis, match tick: $($sys.tick)"
}

Write-Host "Match on tick: x: $($matchAxis[0]), y: $($matchAxis[1]), z: $($matchAxis[2])"

$matchAll = lcm -n1 (lcm -n1 $matchAxis[0] -n2 $matchAxis[1]) -n2 $matchAxis[2]
Write-Host "Found previous state on tick: $matchAll"
