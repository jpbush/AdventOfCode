[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$space = Create-Space -InFilename $InFilename

$result = Find-OneWithMostVisible -Space $space
$result.point
$result.count
