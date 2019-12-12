[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)

$locations = foreach($line in $content) {
    [point]::new($line)
}

$sys = [system]::new($locations)

$initialState = $sys.GetState()
$sys.ToString() | Write-Host
Write-Host

$axisMatch = @(0,0,0)
for($axis = 0; $axis -lt 3; $axis++) {
    Write-Host "Axis: $axis"
    $tick = 0
    do {
        $sys.DoTick($axis)
        $currState = $sys.GetState()
        $tick++
        if(!($tick % 10000)) {
            Write-Verbose $tick
        }
    } while ($currState -ne $initialState) 
    $axisMatch[$axis] = $tick
    Write-Host "Axis: $axis, Tick: $tick"
}

Write-Host "Each axis: $($axisMatch[0]), $($axisMatch[1]), $($axisMatch[2])"
$lcm = $sys.lcm($sys.lcm([int]$axisMatch[0], [int]$axisMatch[1]), [int]$axisMatch[2])
Write-Host "Found previous state on tick: $lcm"
