[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$space = Create-Space -InFilename $InFilename

Find-OneWithMostVisible -Space $space
