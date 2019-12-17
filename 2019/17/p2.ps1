[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename).Split(',')

$controller = [AftScaffoldControl]::new($content)
$result = $controller.RunMovementRoutine()
$controller.WriteMap()
Write-Host "Result : $result"