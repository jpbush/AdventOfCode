[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)
