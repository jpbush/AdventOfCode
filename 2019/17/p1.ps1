[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename).Split(',')

$controller = [AftScaffoldControl]::new($content)
$controller.StartAftScaffoldControl()
$controller.FindIntersectionPoints()
$controller.WriteMap()
$alignment = $controller.CalculateAlignmentParams()
Write-Host "Alignment parameter sum: $alignment"
