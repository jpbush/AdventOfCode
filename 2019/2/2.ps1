
function Invoke-IntCodes
{
    param(
        [string[]] $IntCodes,
        [int] $Noun,
        [int] $Verb
    )

    $IntCodes[1] = $Noun
    $IntCodes[2] = $Verb

    for($i = 0; $i -lt $IntCodes.Length; $i += 4)
    {
        $i1 = [int]$IntCodes[$i + 1]
        $i2 = [int]$IntCodes[$i + 2]
        $resi = [int]$IntCodes[$i + 3]

        $n1 = [int]$IntCodes[$i1]
        $n2 = [int]$IntCodes[$i2]

        if($IntCodes[$i] -eq 1) {
            $IntCodes[$resi] = ($n1 + $n2)
            Write-Verbose "i($i) : IntCodes[$resi]($res) = IntCodes[$i1]($n1) +  IntCodes[$i2]($n2)"
        }
        elseif($IntCodes[$i] -eq 2) {
            $IntCodes[$resi] = ($n1 * $n2)
            Write-Verbose "i($i) : IntCodes[$resi]($res) = IntCodes[$i1]($n1) *  IntCodes[$i2]($n2)"
        }
        elseif($IntCodes[$i] -eq 99)
        {
            Write-Verbose "Exit code at IntCodes[$i]"
            break
        }
        else {
            throw "Bad code IntCodes[$i] == [$($IntCodes[$i])]"
        }

        $res = [int]$IntCodes[$resi]
    }

    return [int]$IntCodes[0]
}

function Invoke-AllNounVerbCombo
{
    param(
        [string] $IntCodes,
        [int] $DesiredResult
    )

    $max = 99
    for($noun = 0; $noun -le $max;) {
        for($verb = 0; $verb -le $max;) {
            $result = Invoke-IntCodes -IntCodes $intCodes.split(',') -noun $noun -verb $verb
            Write-Verbose "noun: $noun, verb: $verb, result: $result, expected $DesiredResult"
            
            if($result -eq $DesiredResult) {
                return $noun * 100 + $verb
            }
            elseif(($DesiredResult - $result) -gt 100) {
                $noun++
            }
            else{
                $verb++
            }
        }
    }
}

function Run-Part1 {
    [CmdletBinding()]
    param(
        [string] $InFilename,
        [int] $Noun,
        [int] $Verb
    )
    $intCodes = (Get-Content $InFilename).Split(',')
    $result = Invoke-IntCodes -IntCodes $intCodes -noun $Noun -verb $Verb
    Write-Host "Program result: $result"
}

function Run-Part2 {
    [CmdletBinding()]
    param(
        [string] $InFilename,
        [int] $DesiredResult
    )
    $intCodes = Get-Content $InFilename
    $result = Invoke-AllNounVerbCombo -IntCodes $intCodes -DesiredResult $DesiredResult
    Write-Host "Program result: $result"
}
