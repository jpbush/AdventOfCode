class ProgramState {
    [string[]] $codes
    [long] $PC
    [long] $RelativeBase
    [long[]] $InBuff
    [long[]] $OutBuff
    [int] $exitCode
    [bool] $isHalted

    ProgramState([string[]] $codes, [long] $PC, [long] $RelativeBase, [long[]] $InBuff, [long[]] $OutBuff, [int] $exitCode) {
        $this.codes = $codes
        $this.PC = $PC
        $this.RelativeBase = $RelativeBase
        $this.InBuff = $InBuff
        $this.OutBuff = $OutBuff
        $this.exitCode = $exitCode
        $this.isHalted = $false
    }

    AddMemory([int] $maxAddress) {
        $memoryToAdd = ($maxAddress - $this.codes.Length + 1)
        if($memoryToAdd -le 0) {
            throw "cannot add $memoryToAdd amount of memory"
        }
        Write-Verbose "Adding $memoryToAdd memory to codes"
        Write-Verbose "MaxAddress will be $maxAddress"

        $this.codes += ,@('0')*$memoryToAdd
        if($this.codes.Length -ne ($maxAddress+1)){
            throw "didn't add enough memory. memory: $($this.codes.Length), maxAddress: $maxAddress"
        }
        Write-Verbose "code length is now: $($this.codes.Length)"
    }

    [bool] IsValidAddress([int] $Address) {
        return $Address -lt $this.codes.Length
    }

    AddMemoryIfNeeded([int] $Address) {
        if(!$this.IsValidAddress($Address)) {
            Write-Verbose "Gonna need to add more memory to reach address: $Address"
            $this.AddMemory($Address)
        }
        return
    }

    [long] Get([int] $Address) {
        $this.AddMemoryIfNeeded($Address)
        return $this.codes[$Address]
    }

    Set([int] $Address, [long] $Val) {
        $this.AddMemoryIfNeeded($Address)
        $this.codes[$Address] = $Val
    }
}

function Run-OpCodes
{
    param(
        [ProgramState] $state
    )

    Write-Verbose "Program starting..."
    Write-Verbose "PC = $($state.PC), RelativeBase = $($state.RelativeBase), InBuff = ($($state.InBuff)), OutBuff = ($($state.OutBuff))"

    if($state.isHalted) {
        return $state
    }

    $inIndex = 0;
    $outBuff = @()
    for($i = $state.PC; $i -lt $state.codes.Length;)
    {
        Write-Verbose "i = $i"
        # Resolve op code
        $codeRaw = $state.Get($i)
        $codeStr = "{0:00000}" -f [int]$codeRaw
        $opcode = [int] $codeStr.Substring(3,2)
        $param1Mode = [int] $codeStr.Substring(2,1)
        $param2Mode = [int] $codeStr.Substring(1,1)
        $param3Mode = [int] $codeStr.Substring(0,1)

        switch ($opcode) {
            # add
            1 {
                Write-Verbose "Opcode: 1"
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                    $param1 = [long]$state.Get($i1)
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                elseif($param1Mode -eq 2) {
                    $param1 = [long]$state.Get($i1+$state.RelativeBase)
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                
                $i2 = [long]$state.Get($i + 2)
                if($param2Mode -eq 0) {
                    $param2 = [long]$state.Get($i2)
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                elseif($param2Mode -eq 2) {
                    $param2 = [long]$state.Get($i2+$state.RelativeBase)
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $result = [long]( $param1 + $param2)
                
                $i3 = [long]$state.Get($i + 3)
                if($param3Mode -eq 0) {
                    $state.Set($i3, $result)
                    Write-Verbose "$param1 + $param2 = $result, store at index $i3"
                }
                elseif($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                elseif($param3Mode -eq 2) {
                    $state.Set($i3+$state.RelativeBase, $result)
                    Write-Verbose "$param1 + $param2 = $result, store at index $i3+$($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $i += 4
                break
            }
            # multiply
            2 {
                Write-Verbose "Opcode: 2"
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                    $param1 = [long]$state.Get($i1)
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                elseif($param1Mode -eq 2) {
                    $param1 = [long]$state.Get($i1+$state.RelativeBase)
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                
                $i2 = [long]$state.Get($i + 2)
                if($param2Mode -eq 0) {
                    $param2 = [long]$state.Get($i2)
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                elseif($param2Mode -eq 2) {
                    $param2 = [long]$state.Get($i2+$state.RelativeBase)
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $result = [long]( $param1 * $param2)
                
                $i3 = [long]$state.Get($i + 3)
                if($param3Mode -eq 0) {
                    $state.Set($i3, $result)
                    Write-Verbose "$param1 * $param2 = $result, store at index $i3"
                }
                elseif($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                elseif($param3Mode -eq 2) {
                    $state.Set($i3+$state.RelativeBase, $result)
                    Write-Verbose "$param1 + $param2 = $result, store at index $i3+$($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $i += 4
                break
            }
            # input
            3 {
                Write-Verbose "Opcode: 3"
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                }
                elseif($param1Mode -eq 2) {
                    $i1 += $state.RelativeBase
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                if($inIndex -lt $state.InBuff.Length) {
                    $state.Set($i1, $state.InBuff[$inIndex])
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
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                    $param1 = [long]$state.Get($i1)
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                elseif($param1Mode -eq 2) {
                    $param1 = [long]$state.Get($i1+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i1+$state.RelativeBase) = $i1 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                Write-Verbose "send output $param1"
                $state.OutBuff += [long]( $param1 )

                $i += 2
                break
            }
            # jump if true
            5 {
                Write-Verbose "Opcode: 5"
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                    $param1 = [long]$state.Get($i1)
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                elseif($param1Mode -eq 2) {
                    $param1 = [long]$state.Get($i1+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i1+$state.RelativeBase) = $i1 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                
                $i2 = [long]$state.Get($i + 2)
                if($param2Mode -eq 0) {
                    $param2 = [long]$state.Get($i2)
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                elseif($param2Mode -eq 2) {
                    $param2 = [long]$state.Get($i2+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i2+$state.RelativeBase) = $i2 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                if(([long]$param1) -ne 0) {
                    $i = $param2
                    Write-Verbose "jump to $param2 cause $param1 true"
                }
                else {
                    $i += 3
                    Write-Verbose "don't jump to $param2 cause $param1 not true"
                }

                break
            }
            # jump if false
            6 {
                Write-Verbose "Opcode: 6"
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                    $param1 = [long]$state.Get($i1)
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                elseif($param1Mode -eq 2) {
                    $param1 = [long]$state.Get($i1+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i1+$state.RelativeBase) = $i1 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                
                $i2 = [long]$state.Get($i + 2)
                if($param2Mode -eq 0) {
                    $param2 = [long]$state.Get($i2)
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                elseif($param2Mode -eq 2) {
                    $param2 = [long]$state.Get($i2+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i2+$state.RelativeBase) = $i2 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                if(([long]$param1) -eq 0) {
                    $i = $param2
                    Write-Verbose "jump to $param2 cause $param1 false"
                }
                else {
                    $i += 3
                    Write-Verbose "don't jump to $param2 cause $param1 false"
                }

                break
            }
            # less than
            7 {
                Write-Verbose "Opcode: 7"
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                    $param1 = [long]$state.Get($i1)
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                elseif($param1Mode -eq 2) {
                    $param1 = [long]$state.Get($i1+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i1+$state.RelativeBase) = $i1 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                
                $i2 = [long]$state.Get($i + 2)
                if($param2Mode -eq 0) {
                    $param2 = [long]$state.Get($i2)
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                elseif($param2Mode -eq 2) {
                    $param2 = [long]$state.Get($i2+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i2+$state.RelativeBase) = $i2 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $result = [long]( $param1 -lt $param2 )
                
                $i3 = [long]$state.Get($i + 3)
                if($param3Mode -eq 0) {
                    $state.Set($i3, $result)
                    Write-Verbose "$param1 < $param2 = $result, store at index $i3"
                }
                elseif($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                elseif($param3Mode -eq 2) {
                    $state.Set($i3+$state.RelativeBase, $result)
                    Write-Verbose "$param1 < $param2 = $result, store at index $i3+$($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $i += 4
                break
            }
            # equal to
            8 {
                Write-Verbose "Opcode: 8"
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                    $param1 = [long]$state.Get($i1)
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                elseif($param1Mode -eq 2) {
                    $param1 = [long]$state.Get($i1+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i1+$state.RelativeBase) = $i1 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                
                $i2 = [long]$state.Get($i + 2)
                if($param2Mode -eq 0) {
                    $param2 = [long]$state.Get($i2)
                }
                elseif($param2Mode -eq 1) {
                    $param2 = $i2
                }
                elseif($param2Mode -eq 2) {
                    $param2 = [long]$state.Get($i2+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i2+$state.RelativeBase) = $i2 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 2 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $result = [long]( $param1 -eq $param2 )
                
                $i3 = [long]$state.Get($i + 3)
                if($param3Mode -eq 0) {
                    $state.Set($i3, $result)
                    Write-Verbose "$param1 == $param2 = $result, store at index $i3"
                }
                elseif($param3Mode -eq 1) {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }
                elseif($param3Mode -eq 2) {
                    $state.Set($i3+$state.RelativeBase, $result)
                    Write-Verbose "$param1 == $param2 = $result, store at index $i3+$($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 3 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $i += 4
                break
            }
            # adjust relative base
            9 {
                Write-Verbose "Opcode: 9"
                $i1 = [long]$state.Get($i + 1)
                if($param1Mode -eq 0) {
                    $param1 = [long]$state.Get($i1)
                }
                elseif($param1Mode -eq 1) {
                    $param1 = $i1
                }
                elseif($param1Mode -eq 2) {
                    $param1 = [long]$state.Get($i1+$state.RelativeBase)
                    Write-Verbose "Relative Address: $($i1+$state.RelativeBase) = $i1 + $($state.RelativeBase)"
                }
                else {
                    throw "ERROR: invalid param 1 mode at index [$i], instruction [$opcode, $($state.Get($i+1)), $($state.Get($i+2)), $($state.Get($i+3))]"
                }

                $oldBase = $state.RelativeBase
                $state.RelativeBase += [long]( $param1 )
                Write-Verbose "Add $param1 to Base. newBase: $($state.RelativeBase), oldBase: $oldBase"

                $i += 2
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


# 0 is an empty tile. No game object appears in this tile.
# 1 is a wall tile. Walls are indestructible barriers.
# 2 is a block tile. Blocks can be broken by the ball.
# 3 is a horizontal paddle tile. The paddle is indestructible.
# 4 is a ball tile. The ball moves diagonally and bounces off objects.
class Game {
    [ProgramState] $state
    [hashtable] $frame
    [int[]] $BoundX
    [int[]] $BoundY

    Game([string[]] $GameCodes) {
        $this.state = [ProgramState]::New($GameCodes, 0, 0, @(), @(), 0)
        $this.frame = @{}
    }

    AddInput([int[]] $InBuff) {
        $this.state.InBuff += $InBuff
    }

    [int[]] GetOutput() {
        $output = $this.state.OutBuff
        $this.state.OutBuff = @()
        return $output
    }

    BuildFrame() {
        $this.frame = @{}
        $this.BoundX = @(999, -999)
        $this.BoundY = @(999, -999)
        $output = $this.GetOutput()
        for($i = 0; $i -lt $output.length; $i+=3) {
            $x = $output[$i]
            $y = $output[$i+1]
            $tileID = $output[$i+2]

            $tile = switch ($tileID) {
                0 { " " } # empty
                1 { "|" } # wall
                2 { "#" } # block
                3 { "-" } # horizontal paddle
                3 { "o" } # ball
            }

            $this.BoundX[0] = [math]::min($this.BoundX[0], $x)
            $this.BoundX[1] = [math]::max($this.BoundX[1], $x)
            $this.BoundY[0] = [math]::min($this.BoundY[0], $y)
            $this.BoundY[1] = [math]::max($this.BoundY[1], $y)
            $this.frame["$x,$y"] = $tile
        }
    }

    WriteFrame() {
        for($y = $this.BoundY[0]; $y -lt $this.BoundY[1]; $y++) {
            for($x = $this.BoundX[0]; $x -lt $this.BoundX[1]; $x++) {
                if($this.frame.ContainsKey("$x,$y")) {
                    Write-Host $this.frame["$x,$y"] -NoNewline
                }
                else {
                    Write-Host " " -NoNewline
                }
            }
            Write-Host
        }
    }

    RunTick() {
        Run-OpCodes -state $this.state
        $this.BuildFrame()
    }
}