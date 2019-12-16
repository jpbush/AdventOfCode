function CalcFFTIteration {
    [CmdletBinding()]
    param(
        [int[]] $inArr,
        [int[]] $pattern,
        [int] $iteration
    )

    # $strArr = [System.Collections.Arraylist]::new()
    $result = 0
    for($i = 0; $i -lt $inArr.Length; $i++) {
        $in = $inArr[$i]
        $pati = ([math]::floor(($i+1)/$iteration) % $pattern.Length)
        $pat = $pattern[$pati]

        $result += $in * $pat
        # $strArr.Add("$in*$pat") 1>$null
    }
    $resMod = [math]::abs($result % 10)

    # Write-Verbose "$($strArr -join " + ") = $resMod"

    return $resMod
}

function CalcFFTPhase {
    [CmdletBinding()]
    param(
        [int[]] $inArr,
        [int[]] $pattern
    )

    $strArr = [System.Collections.Arraylist]::new()
    for($i = 1; $i -le $inArr.Length; $i++) {
        $strArr.Add( "$(CalcFFTIteration -inArr $inArr -pattern $pattern -iteration $i)" ) 1>$null
    }
    return $strArr.toArray()
}

function CalcFFTUpToPhase {
    [CmdletBinding()]
    param(
        [string] $inStr,
        [int[]] $pattern,
        [int] $phase
    )
    Write-Verbose "inStr: $inStr"
    $inArr = $inStr -split ""
    $inArr = $inArr[1..($inArr.length-2)]
    Write-Verbose "inArr: $($inArr -join ' ')"

    for($i = 1; $i -le $phase; $i++) {
        $inArr = @(CalcFFTPhase -inArr $inArr -pattern $pattern)
        Write-Host "After $i phases:  $($inArr -join '')"
    }
    return $inArr -join ""
}