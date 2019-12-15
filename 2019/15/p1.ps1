[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename).Split(',')

$controller = [DroidController]::new($content)
# $controller.StartDroidController()
$result = $controller.StartDroidAuto()
Write-Host "Took $result moves to find the end"
