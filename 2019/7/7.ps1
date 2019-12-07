
function Run-OpCodes
{
    param(
        [string] $CsvCodes,
        [int] $Setting,
        [int] $In
    )

    $codes = $CsvCodes.split(',')
    $inputIndex = 0;

    for($i = 0; $i -lt $codes.Length;)
    {
        Write-Verbose "i = $i"
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
                Write-Verbose "Opcode: 1"
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
                Write-Verbose "$param1 + $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # multiply
            2 {
                Write-Verbose "Opcode: 2"
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
                Write-Verbose "$param1 * $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # input
            3 {
                Write-Verbose "Opcode: 3"
                $i1 = [int]$codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$codes[$i1]
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($codes[$i+1])]"
                }

                if($inputIndex -eq 0) {
                    $codes[$i1] = $Setting
                    Write-Verbose "store setting $setting at index $i1"
                    $inputIndex++

                }
                elseif($inputIndex -eq 1) {
                    $codes[$i1] = $In
                    Write-Verbose "store setting $In at index $i1"
                    $inputIndex++
                }
                else {
                   throw "too many inputs $inputIndex"
                }

                $i += 2
                break
            }
            # output
            4 {
                Write-Verbose "Opcode: 4"
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
                Write-Verbose "store output $Output"

                $i += 2
                break
            }
            # jump if true
            5 {
                Write-Verbose "Opcode: 5"
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
                    Write-Verbose "jump to $param2 cause true"
                }
                else {
                    $i += 3
                    Write-Verbose "don't jump cause was not true"
                }

                break
            }
            # jump if false
            6 {
                Write-Verbose "Opcode: 6"
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
                    Write-Verbose "jump to $param2 cause false"
                }
                else {
                    $i += 3
                    Write-Verbose "don't jump cause was not false"
                }

                break
            }
            # less than
            7 {
                Write-Verbose "Opcode: 7"
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
                Write-Verbose "Opcode: 8"
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
                Write-Verbose "$param1 -lt $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # exit
            99 {
                Write-Verbose "Opcode: 99"
                return $Output
                break
            }
            Default {
                throw "ERROR: invalid opcode at index [$i], opcode [$opcode]"
            }
        }
    }
    return $Output
}

function Run-Amps
{
    param(
        [string] $CsvCodes,
        [int[]] $Settings,
        [int] $In
    )
    
    $aOut = Run-OpCodes -CsvCodes $content -Setting $Settings[0] -In $In
    $bOut = Run-OpCodes -CsvCodes $content -Setting $Settings[1] -In $aOut
    $cOut = Run-OpCodes -CsvCodes $content -Setting $Settings[2] -In $bOut
    $dOut = Run-OpCodes -CsvCodes $content -Setting $Settings[3] -In $cOut
    $eOut = Run-OpCodes -CsvCodes $content -Setting $Settings[4] -In $dOut
    
    return $eOut
}

function Run-Part1
{
    [CmdletBinding()]
    param(
        [string] $InFilename,
        [int] $In
    )

    $content = (Get-Content $InFilename)

    $minInput = 0
    $maxInput = 5
    $maxOutput = -1

    for ($a = $minInput; $a -lt $maxInput; $a++) {
        for ($b = $minInput; $b -lt $maxInput; $b++) {
            for ($c = $minInput; $c -lt $maxInput; $c++) {
                for ($d = $minInput; $d -lt $maxInput; $d++) {
                    for ($e = $minInput; $e -lt $maxInput; $e++) {
                        $settings = @($a, $b, $c, $d, $e)
                        if($settings.Contains(0) -and $settings.Contains(1) -and $settings.Contains(2) -and $settings.Contains(3) -and $settings.Contains(4)){
                            
                            $out = [int](Run-Amps -CsvCodes $content -Settings $settings -In $In)

                            if(($maxOutput -lt 0) -or ($out -gt $maxOutput)) {
                                $maxOutput = $out
                                $maxSettings = "$settings"
                            }
                            Write-Host "maxSettings: $maxSettings, maxOutput: $maxOutput, settings: $settings output: $out"
                        }
                    }
                }
            }
        }
    }
}

function Run-Part2
{
    [CmdletBinding()]
    param(
        [string] $InFilename
    )
}
