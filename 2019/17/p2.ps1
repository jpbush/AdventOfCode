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

# A: L10 R10 L10 L10
# B: R10 R12 L12
# C: R12 L12 R6
# Main: A B A B C C B A B C