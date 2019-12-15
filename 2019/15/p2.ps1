[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename).Split(',')

$controller = [DroidController]::new($content)
$depth = $controller.CalculateOxygenFillTime()
Write-Host "depth $depth"
