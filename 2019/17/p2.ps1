[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename).Split(',')

$controller = [AftScaffoldControl]::new($content)
$output = $controller.RunMovementRoutine()
$controller.WriteMap()
