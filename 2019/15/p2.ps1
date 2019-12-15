[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename).Split(',')

$controller = [DroidController]::new($content)
$depth = $controller.CalculateOxygenFillTime()
$start = [point]::new(-20, -16)
$depth = $this.BFS($start)
Write-Host "depth $depth"
