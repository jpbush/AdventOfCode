[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename).Split(',')

$controller = [DroidController]::new($content)
# $controller.StartDroidController()
$result = $controller.BuildMap()
Write-Host "Took $result moves to find the end"
$depth = $controller.BFS([point]::new(0,0))
Write-Host "depth $depth"
