[CmdletBinding()]
param(
    [string] $InFilename
)

. $PSScriptRoot/lib.ps1

$content = (Get-Content $InFilename)
$game = [Game]::New($content.split(','))
$game.RunTick()
$game.WriteFrame()

$blocks = 0
foreach($key in $game.frame.Keys) {
    $tile = $game.frame[$key]
    if($tile -eq '#') {
        $blocks++
    }
}

Write-Host "Number of blocks $blocks"
