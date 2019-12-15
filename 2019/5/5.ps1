
# ABCDE
#  1002

# DE - two-digit opcode,      02 == opcode 2
#  C - mode of 1st parameter,  0 == position mode
#  B - mode of 2nd parameter,  1 == immediate mode
#  A - mode of 3rd parameter,  0 == position mode,
#                                   omitted due to being a leading zero

# to run: 
# Get-Content .\day2in.txt | Resolve-OpCodes
function Run-OpCodes
{
    param(
        [string] $CsvCodes,
        [int] $In
    )

    $codes = $CsvCodes.split(',')

    for($i = 0; $i -lt $codes.Length;)
    {
        Write-Host "i = $i"
        # Resolve op code
        $codeRaw = $codes[$i]
        $codeStr = "{0:00000}" -f [int]$codeRaw
        $opcode = [int] $codeStr.Substring(3,2)
        $param1Mode = [int] $codeStr.Substring(2,1)
        $param2Mode = [int] $codeStr.Substring(1,1)
        $param3Mode = [int] $codeStr.Substring(0,1)

        switch ($opcode) {
            # add
            1 {
                Write-Host "Opcode: 1"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i2 = [int]$codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i3 = [int]$codes[$i + 3]
                if($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }

                $result = [int]( $param1 + $param2)
                $codes[$i3] = $result
                Write-Host "$param1 + $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # multiply
            2 {
                Write-Host "Opcode: 2"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i2 = [int]$codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i3 = [int]$codes[$i + 3]
                if($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }

                $result = [int]( $param1 * $param2)
                $codes[$i3] = $result
                Write-Host "$param1 * $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # input
            3 {
                Write-Host "Opcode: 3"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1])]"
                }

                $codes[$i1] = [int]( $In )
                Write-Host "store input $In at index $i1"

                $i += 2
                break
            }
            # output
            4 {
                Write-Host "Opcode: 4"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1])"
                }

                $Output = [int]( $param1 )
                Write-Host "store output $In"

                $i += 2
                break
            }
            # jump if true
            5 {
                Write-Host "Opcode: 5"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i2 = [int]$codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }

                if(([int]$param1) -ne 0) {
                    $i = $param2
                    Write-Host "jump to $param2 cause true"
                }
                else {
                    $i += 3
                    Write-Host "don't jump cause was not true"
                }

                break
            }
            # jump if false
            6 {
                Write-Host "Opcode: 6"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i2 = [int]$codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }

                if(([int]$param1) -eq 0) {
                    $i = $param2
                    Write-Host "jump to $param2 cause false"
                }
                else {
                    $i += 3
                    Write-Host "don't jump cause was not false"
                }

                break
            }
            # less than
            7 {
                Write-Host "Opcode: 7"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i2 = [int]$codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i3 = [int]$codes[$i + 3]
                if($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }

                $codes[$i3] = [int]( $param1 -lt $param2 )

                $i += 4
                break
            }
            # equal to
            8 {
                Write-Host "Opcode: 8"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i2 = [int]$codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }
                
                $i3 = [int]$codes[$i + 3]
                if($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($codes[$i+1]), $($codes[$i+2]), $($codes[$i+2])]"
                }

                $result = [int]( $param1 -eq $param2 )
                $codes[$i3] = $result
                Write-Host "$param1 -lt $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # exit
            99 {
                Write-Host "Opcode: 99"
                return "Output: $Output"
                break
            }
            Default {
                throw "ERROR: invalid opcode at index [$i], opcode [$opcode]"
            }
        }
    }
    return "Output: $Output"
}
