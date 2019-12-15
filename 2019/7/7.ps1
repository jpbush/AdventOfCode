
class ProgramState {
    [string[]] $codes
    [int] $PC
    [int[]] $InBuff
    [int[]] $OutBuff
    [int] $exitCode
    [bool] $isHalted

    ProgramState([string[]] $codes, [int] $PC, [int[]] $InBuff, [int[]] $OutBuff, [int] $exitCode) {
        $this.codes = $codes
        $this.PC = $PC
        $this.InBuff = $InBuff
        $this.OutBuff = $OutBuff
        $this.exitCode = $exitCode
        $this.isHalted = $false
    }
}

function Run-OpCodes
{
    param(
        [ProgramState] $state
    )
    if($state.isHalted) {
        return $state
    }

    $inIndex = 0;
    $outBuff = @()
    for($i = $state.PC; $i -lt $state.codes.Length;)
    {
        Write-Verbose "i = $i"
        # Resolve op code
        $codeRaw = $state.codes[$i]
        $codeStr = "{0:00000}" -f [int]$codeRaw
        $opcode = [int] $codeStr.Substring(3,2)
        $param1Mode = [int] $codeStr.Substring(2,1)
        $param2Mode = [int] $codeStr.Substring(1,1)
        $param3Mode = [int] $codeStr.Substring(0,1)

        switch ($opcode) {
            # add
            1 {
                Write-Verbose "Opcode: 1"
                $i1 = [int]$state.codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$state.codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i2 = [int]$state.codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$state.codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i3 = [int]$state.codes[$i + 3]
                if($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }

                $result = [int]( $param1 + $param2)
                $state.codes[$i3] = $result
                Write-Verbose "$param1 + $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # multiply
            2 {
                Write-Verbose "Opcode: 2"
                $i1 = [int]$state.codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$state.codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i2 = [int]$state.codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$state.codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i3 = [int]$state.codes[$i + 3]
                if($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }

                $result = [int]( $param1 * $param2)
                $state.codes[$i3] = $result
                Write-Verbose "$param1 * $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # input
            3 {
                Write-Verbose "Opcode: 3"
                $i1 = [int]$state.codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$state.codes[$i1]
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.codes[$i+1])]"
                }

                if($inIndex -lt $state.InBuff.Length) {
                    $state.codes[$i1] = $state.InBuff[$inIndex]
                    Write-Verbose "store setting $($state.InBuff) at index $i1"
                    $inIndex++
                }
                else {
                    Write-Verbose "ran out of arguments, returning"
                    $state.exitCode = 0
                    $state.InBuff = @()
                    $state.PC = $i
                    return $state
                }

                $i += 2
                break
            }
            # output
            4 {
                Write-Verbose "Opcode: 4"
                $i1 = [int]$state.codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$state.codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.codes[$i+1])"
                }

                Write-Verbose "store output $param1"
                $state.OutBuff += [int]( $param1 )

                $i += 2
                break
            }
            # jump if true
            5 {
                Write-Verbose "Opcode: 5"
                $i1 = [int]$state.codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$state.codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i2 = [int]$state.codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$state.codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
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
                $i1 = [int]$state.codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$state.codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i2 = [int]$state.codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$state.codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
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
                $i1 = [int]$state.codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$state.codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i2 = [int]$state.codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$state.codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i3 = [int]$state.codes[$i + 3]
                if($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }

                $state.codes[$i3] = [int]( $param1 -lt $param2 )

                $i += 4
                break
            }
            # equal to
            8 {
                Write-Verbose "Opcode: 8"
                $i1 = [int]$state.codes[$i + 1]
                if($param1Mode -eq 0) {
                    $param1 = [int]$state.codes[$i1]
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i2 = [int]$state.codes[$i + 2]
                if($param2Mode -eq 0) {
                    $param2 = [int]$state.codes[$i2]
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }
                
                $i3 = [int]$state.codes[$i + 3]
                if($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.codes[$i+1]), $($state.codes[$i+2]), $($state.codes[$i+2])]"
                }

                $result = [int]( $param1 -eq $param2 )
                $state.codes[$i3] = $result
                Write-Verbose "$param1 -lt $param2 = $result, store at index $i3"

                $i += 4
                break
            }
            # exit
            99 {
                Write-Verbose "Opcode: 99"
                $state.exitCode = 99
                $state.InBuff = @($state.InBuff[$inIndex..($state.InBuff.Length-1)])
                $state.PC = $i
                $state.isHalted = $true
                return $state
                break
            }
            Default {
                throw "ERROR: invalid opcode at index [$i], opcode [$opcode]"
            }
        }
    }
    $state.exitCode = 2
    $state.InBuff = @($state.InBuff[$inIndex..($state.InBuff.Length-1)])
    $state.PC = $i
    $state.isHalted = $true
    return $state
}

function Run-Amps
{
    param(
        [string] $CsvCodes,
        [int[]] $Settings,
        [int] $In
    )

    $stateA = [ProgramState]::New($CsvCodes.split(','), 0, @($Settings[0], $In), @(), 0)
    $stateB = [ProgramState]::New($CsvCodes.split(','), 0, @($Settings[1]), @(), 0)
    $stateC = [ProgramState]::New($CsvCodes.split(','), 0, @($Settings[2]), @(), 0)
    $stateD = [ProgramState]::New($CsvCodes.split(','), 0, @($Settings[3]), @(), 0)
    $stateE = [ProgramState]::New($CsvCodes.split(','), 0, @($Settings[4]), @(), 0)

    $allHalted = $false
    while(!$allHalted){
        $stateA = Run-OpCodes -state $stateA
        $stateB.InBuff += $stateA.outBuff
        Write-Verbose "outA $($stateA.outBuff)"
        $stateA.outBuff = @()
        
        $stateB = Run-OpCodes -state $stateB
        $stateC.InBuff += $stateB.outBuff
        Write-Verbose "outB $($stateB.outBuff)"
        $stateB.outBuff = @()
        
        $stateC = Run-OpCodes -state $stateC
        $stateD.InBuff += $stateC.outBuff
        Write-Verbose "outC $($stateC.outBuff)"
        $stateC.outBuff = @()
        
        $stateD = Run-OpCodes -state $stateD
        $stateE.InBuff += $stateD.outBuff
        Write-Verbose "outD $($stateD.outBuff)"
        $stateD.outBuff = @()
        
        $stateE = Run-OpCodes -state $stateE
        $stateA.InBuff += $stateE.outBuff
        Write-Verbose "outE $($stateE.outBuff)"
        $output = $stateE.OutBuff
        $stateE.outBuff = @()

        if($stateA.isHalted -and $stateB.isHalted -and $stateC.isHalted -and $stateD.isHalted -and $stateE.isHalted) {
            $allHalted = $true
        }
        Write-Verbose "output $output"
    }
    
    return $output
}

function Run-Part1
{
    [CmdletBinding()]
    param(
        [string] $InFilename,
        [int] $In
    )

    $content = (Get-Content $InFilename)

    $minInput = 5
    $maxInput = 10
    $maxOutput = -1

    for ($a = $minInput; $a -lt $maxInput; $a++) {
        for ($b = $minInput; $b -lt $maxInput; $b++) {
            for ($c = $minInput; $c -lt $maxInput; $c++) {
                for ($d = $minInput; $d -lt $maxInput; $d++) {
                    for ($e = $minInput; $e -lt $maxInput; $e++) {
                        $Settings = @($a, $b, $c, $d, $e)
                        if($Settings.Contains(5) -and $Settings.Contains(6) -and $Settings.Contains(7) -and $Settings.Contains(8) -and $Settings.Contains(9)){
                            
                            $out = @(Run-Amps -CsvCodes $content -Settings $Settings -In $In)
                            if($out.Length -gt 1) {
                                throw "output too long $out"
                            }
                            $out = [int]$out[0]

                            if(($maxOutput -lt 0) -or ($out -gt $maxOutput)) {
                                $maxOutput = $out
                                $maxSettings = "$Settings"
                            }
                            Write-Host "maxSettings: $maxSettings, maxOutput: $maxOutput, settings: $Settings output: $out"
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
