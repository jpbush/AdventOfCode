# to run: 
# Get-Content .\day2in.txt | Resolve-OpCodes
function Resolve-OpCodes()
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $csvCodes,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [int]
        $noun,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [int]
        $verb
    )

    $codes = $csvCodes.split(',')
    $codes[1] = $noun
    $codes[2] = $verb

    for($i = 0; $i -lt $codes.Length; $i += 4)
    {
        $codes | Out-File "out$($i).txt"

        $i1 = [int]$codes[$i + 1]
        $i2 = [int]$codes[$i + 2]
        $resi = [int]$codes[$i + 3]

        $n1 = [int]$codes[$i1]
        $n2 = [int]$codes[$i2]

        if($codes[$i] -eq 1) {
            $codes[$resi] = [int]( $n1 + $n2)
            $res = [int]$codes[$resi]
            #Write-Host "i($i) : codes[$resi]($res) = codes[$i1]($n1) + codes[$i2]($n2)"
        }
        elseif($codes[$i] -eq 2) {
            $codes[$resi] = [int]( $n1 * $n2)
            $res = [int]$codes[$resi]
            #Write-Host "i($i) : codes[$resi]($res) = codes[$i1]($n1) + codes[$i2]($n2)"
        }
        elseif($codes[$i] -eq 99)
        {
            #Write-Host "exit code at codes[$i]"
            break
        }
        else {
            throw "bad code codes[$i] == [$codes[$i]"
        }
    }

    return $codes[0]
}

function TryAllNounVerbs()
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $csvCodes,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [int]
        $desiredResult
    )
    $max = 99
    for($noun = 0; $noun -le $max;) {
        for($verb = 0; $verb -le $max;) {
            $result = Resolve-OpCodes -csvCodes $csvCodes -noun $noun -verb $verb
            Write-Verbose "noun: $noun, verb: $verb == $result : expected $desiredResult"
            
            if($result -eq $desiredResult) {
                Write-Verbose "noun: $noun, verb: $verb"
                return $noun * 100 + $verb
            }
            elseif(($desiredResult - $result) -gt 100) {
                $noun++
            }
            else{
                $verb++
            }
        }
    }
}