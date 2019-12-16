[CmdletBinding()]
param(
    [string] $InFilename,
    [int[]] $pattern,
    [int] $phase,
    [int] $multiplier
)

. $PSScriptRoot/lib.ps1

$content = Get-Content $InFilename
$contentLen = $content.Length

$offset = [int]$content.SubString(0, 7)

$contemtMul = $content * $($multiplier/2)
$pad = "0" * $contemtMul.Length
$contemtMul = $pad + $contemtMul
$contentMulLen = $contemtMul.Length

Write-Host "input length : $contentLen"
Write-Host "input multiplied length : $contentMulLen"
Write-Host "offset : $offset, offsetInt $offsetInt, half length : $($contemtMul.Length / 2)"

$inArr = [int[]] ($contemtMul -split "")
$inArr = $inArr[1..($inArr.length-2)]
for($p = 1; $p -le $phase; $p++) {
    Write-Host "Phase : $p"
    $temp = $inArr[$contentMulLen - 1]
    for($i = $contentMulLen - 2; $i -ge ($contentMulLen / 2); $i--) {
        # Write-Host $i
        $inArr[$i + 1] = $temp
        $temp = ($inArr[$i] + $inArr[$i + 1]) % 10
    }
    # Write-Host "After $p phases:  $($inArr -join '')"
}

$result = ($inArr -join '').SubString($offset, 8)
Write-Host "Result after $phase phases:  $result"
