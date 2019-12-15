[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)
$game = [Game]::New($content.split(','))
# set number of quarters

$game.PlayGame()
