$Global:sleepTime = 0

class point {
    [int]$x = 0
    [int]$y = 0

    point() { }

    point([int] $x, [int] $y) {
        $this.Set($x, $y)
    }

    point([point] $p) {
        $this.Set($p.x, $p.y)
    }

    point ([string] $str) 
    {
        $strArr = $str.split(',')
        $this.Set($strArr[0], $strArr[1])
    }

    Set([int] $x, [int] $y) {
        $this.x = $x
        $this.y = $y
    }

    Add([int] $x, [int] $y) {
        $this.x += $x
        $this.y += $y
    }

    Add([point] $p) {
        $this.Add($p.x, $p.y)
    }

    [bool] Equals([int] $x, [int] $y) {
        return ($this.x -eq $x) -and ($this.y -eq $y)
    }

    [string] GetHash() 
    {
        return "$($this.x),$($this.y)"
    }

    [string] ToString() 
    {
        return "x=$($this.x), y=$($this.y)"
    }
}

class tile {
    [point] $location
    [int] $tokenID
    [char] $tokenVisual

    tile([int] $x, [int] $y, $tokenID) {
        $this.location = [point]::new($x, $y)
        $this.tokenID = $tokenID
        $this.tokenVisual = switch($tokenID) {
            0 { "#"; break }
            1 { "."; break }
            2 { "*"; break }
            3 { "O"; break }
            10 { "^"; break }
            11 { "v"; break }
            12 { "<"; break }
            13 { ">"; break }
            20{ "X"; break }
            default { throw "Invalid tokenID: $tokenID"; break }
        }
    }
}

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
                    $state.exitCode = 3
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

class Droid {
    [ProgramState] $Brain
    [point] $Location
    [hashtable] $map
    [int[]] $BoundX
    [int[]] $BoundY

    Droid([string[]] $BrainCodes) {
        $this.Brain = [ProgramState]::New($BrainCodes, 0, 0, @(), @(), 0)
        $this.Location = [point]::New(0,0)
        $this.map = @{}
        $this.map[$this.location.GetHash()] = [tile]::new(0,0,1)
        $this.BoundX = @(0, 0)
        $this.BoundY = @(0, 0)
    }

    AddInput([long[]] $InBuff) {
        $this.Brain.InBuff += $InBuff
    }

    [long[]] GetOutput() {
        $output = $this.Brain.OutBuff
        $this.Brain.OutBuff = @()
        return $output
    }

    UpdateMap([int] $tokenID, [int] $x, [int] $y) {
        $updateLoc = [point]::new($x, $y)
        $this.map[$updateLoc.GetHash()] = [tile]::new($x, $y, $tokenID)
        $this.BoundX[0] = [math]::min($this.BoundX[0], $x)
        $this.BoundX[1] = [math]::max($this.BoundX[1], $x)
        $this.BoundY[0] = [math]::min($this.BoundY[0], $y)
        $this.BoundY[1] = [math]::max($this.BoundY[1], $y)
    }

    # 1. Accept a movement command via an input instruction.
    # 2. Send the movement command to the repair droid.
    # 3. Wait for the repair droid to finish the movement operation.
    # 4. Report on the status of the repair droid via an output instruction.
    # 
    # Only four movement commands are understood: north (1), south (2), west (3), and east (4). Any other command is invalid.
    # 
    # The repair droid can reply with any of the following status codes:
    # 0: The repair droid hit a wall. Its position has not changed.
    # 1: The repair droid has moved one step in the requested direction.
    # 2: The repair droid has moved one step in the requested direction; its new position is the location of the oxygen system.
    [int] Move([int] $direction, [bool] $clear) {
        Write-Verbose "Move $direction"
        $this.AddInput($direction)
        Run-OpCodes -state $this.Brain

        $output = $this.GetOutput()
        if($output.Length -ne 1) {
            throw "No output was returned :("
        }
        $status = $output[0]

        $move = [point]::new(0,0)
        switch ($direction) {
            1 { $move.y = -1; break }
            2 { $move.y = 1; break }
            3 { $move.x = -1; break }
            4 { $move.x = 1; break }
            default { throw "invalid direction $_"; break  }
        }

        switch($status) {
            0 {
                $x = $this.Location.x + $move.x
                $y = $this.Location.y + $move.y
                Write-Verbose "Wall at $x, $y, robot at $($this.Location.GetHash())"
                $this.UpdateMap(0, $x, $y)
                break
            }
            1 {
                $this.Location.Add($move)
                $this.UpdateMap(1, $this.Location.x, $this.Location.y)
                break
            }
            2 {
                $this.Location.Add($move)
                $this.UpdateMap(2, $this.Location.x, $this.Location.y)
                break
            }
            default {
                throw "invalid status $status"
            }
        }

        return $status
    }

    [int] Move([int] $direction) {
        return $this.Move($direction, $false)
    }

    Look() {
        $this.LookNS()
        $this.LookEW()
    }

    LookNS() {
        if($this.Move(1) -gt 0) {
            $this.Move(2)
        }
        if($this.Move(2) -gt 0) {
            $this.Move(1)
        }
    }

    LookEW() {
        if($this.Move(3) -gt 0) {
            $this.Move(4)
        }
        if($this.Move(4) -gt 0) {
            $this.Move(3)
        }
    }
}

class DroidController {
    [Droid] $droid
    [point] $goalPoint = $null

    DroidController([string[]] $droidCodes) {
        $this.droid = [Droid]::New($droidCodes)
        # $this.droid.Look()
        Clear-Host
        $this.WriteMap()
    }

    WriteMap() {
        $frame = [System.Collections.ArrayList]@()
        $frame.Add([System.Collections.ArrayList]@())
        $frameY = 0
        for($x = $this.droid.BoundX[0]-1; $x -le $this.droid.BoundX[1]+1; $x++) { $frame[$frameY].Add("+") }
        for($y = $this.droid.BoundY[0]; $y -le $this.droid.BoundY[1]; $y++) {
            $frame.Add([System.Collections.ArrayList]@())
            $frameY++
            $frame[$frameY].Add("+")
            for($x = $this.droid.BoundX[0]; $x -le $this.droid.BoundX[1]; $x++) {
                $currLocation = [point]::new($x, $y)
                if(($this.droid.location.x -eq $x) -and ($this.droid.location.y -eq $y)) {
                    $frame[$frameY].Add("@")
                }
                elseif($this.droid.map.ContainsKey($currLocation.GetHash())) {
                    $frame[$frameY].Add($this.droid.map[$currLocation.GetHash()].tokenVisual)
                }
                else {
                    $frame[$frameY].Add(" ")
                }
            }
            $frame[$frameY].Add("+")
        }
        
        $frame.Add([System.Collections.ArrayList]@())
        $frameY++
        for($x = $this.droid.BoundX[0]-1; $x -le $this.droid.BoundX[1]+1; $x++) { $frame[$frameY].Add("+") }
        
        Clear-Host
        foreach($line in $frame) {
            Write-Host ($line -join "")
        }
    }

    [point] BuildMap() {
        $stack = [System.Collections.Stack]::new()
        $foundGoal = $false
        $direction = 1
        $ittr = 0
        $this.goalPoint = $null
        do {
            $ittr++
            $status = $this.droid.Move($direction)
            $stack.Push($direction)
            Start-Sleep -Milliseconds $Global:sleepTime
            if(!($stack.Count % 100)) { $this.WriteMap() }
            # $this.WriteMap()
            Write-Verbose "Depth $($stack.Count)"
            switch($status) {
                0 {
                    Write-Verbose "Wall"
                    $direction = $stack.Pop()
                    $directionCopy = $direction
                    $foundClearPath = $false
                    for($i = 0; $i -lt 4; $i++) {
                        $direction = [math]::max(($direction + 1) % 5, 1)
                        $move = [point]::new(0,0)
                        switch ($direction) {
                            1 { $move.y = -1; break }
                            2 { $move.y = 1; break }
                            3 { $move.x = -1; break }
                            4 { $move.x = 1; break }
                            default { throw "invalid direction $_"; break  }
                        }
                        $move.Add($this.droid.Location)
                        if(!$this.droid.map.ContainsKey($move.GetHash())) {
                            Write-Verbose "send it"
                            $foundClearPath = $true
                            break
                        }
                        else {
                            Write-Verbose "already been there"
                        }
                    }

                    if(!$foundClearPath) {
                        Write-Verbose "Didn't stuck in a corner, backing up"
                        $direction = $stack.Pop()
                        switch($direction) {
                            1 { $this.droid.Move(2, $true); break }
                            2 { $this.droid.Move(1, $true); break }
                            3 { $this.droid.Move(4, $true); break }
                            4 { $this.droid.Move(3, $true); break }
                        }
                        $direction = [math]::max(($direction + 1) % 5, 1)
                    }

                    Write-Verbose "Try $direction next"
                    break
            }
            1 {
                    Write-Verbose "Not Wall"
                # up
                $nextLoc = [point]::new($this.droid.Location.x, ($this.droid.Location.y - 1))
                Write-Verbose "Try up : $($nextLoc.ToString())"
                if(!$this.droid.map.ContainsKey($nextLoc.GetHash())) {
                    Write-Verbose "send it"
                        $direction = 1
                        break
                    }
                else {
                    Write-Verbose "already been there"
                }
                # down
                $nextLoc = [point]::new($this.droid.Location.x, ($this.droid.Location.y + 1))
                Write-Verbose "Try down : $($nextLoc.ToString())"
                if(!$this.droid.map.ContainsKey($nextLoc.GetHash())) {
                    Write-Verbose "send it"
                        $direction = 2
                        break
                    }
                else {
                    Write-Verbose "already been there"
                }
                # left
                $nextLoc = [point]::new(($this.droid.Location.x - 1), $this.droid.Location.y)
                Write-Verbose "Try left : $($nextLoc.ToString())"
                if(!$this.droid.map.ContainsKey($nextLoc.GetHash())) {
                    Write-Verbose "send it"
                        $direction = 3
                        break
                }
                else {
                    Write-Verbose "already been there"
                }
                # right
                $nextLoc = [point]::new(($this.droid.Location.x + 1), $this.droid.Location.y)
                Write-Verbose "Try right : $($nextLoc.ToString())"
                if(!$this.droid.map.ContainsKey($nextLoc.GetHash())) {
                    Write-Verbose "send it"
                        $direction = 4
                        break
                }
                else {
                    Write-Verbose "already been there"
                }
                Write-Verbose "Didn't find it, backing up"
                # throw "Didn't find it, backing up"
                # backup
                    $direction = $stack.Pop()
                switch($direction) {
                        1 { $this.droid.Move(2, $true); break }
                        2 { $this.droid.Move(1, $true); break }
                        3 { $this.droid.Move(4, $true); break }
                        4 { $this.droid.Move(3, $true); break }
                    }
                    $direction = [math]::max(($direction + 1) % 5, 1)
                    break
                }
                2 {
                    Write-Host "Found Target at $($this.droid.Location.GetHash())"
                    Start-sleep 3
                    $foundGoal = $true
                    $this.goalPoint = [point]::new($this.droid.Location)
                    break
                }
                default { throw "invalid status $status" }
            }
        } while($stack.Count -gt 0 -or $ittr -lt 2)

        $stack2 = [System.Collections.Stack]::new($stack)
        While($stack2.Count) {
            $this.droid.map[$this.droid.Location.GetHash()] = [tile]::new($this.location.x, $this.location.y, 3)
            $direction = $stack2.Pop()
            switch($direction) {
                    1 { $this.droid.Move(2); break }
                    2 { $this.droid.Move(1); break }
                    3 { $this.droid.Move(4); break }
                    4 { $this.droid.Move(3); break }
                }
            Write-Verbose "Depth $($stack2.Count)"
            $this.WriteMap()
        }

        return $this.goalPoint
    }

    [int] BFS([point] $start) {
        $start = [point]::new(-20, -16)
        Write-Host "Start Pos: $($start.GetHash())"
        Start-Sleep 5
        $q = [System.Collections.Queue]::new()
        $q.Enqueue(@{pos = $start; depth = 0})
        $seen = @{}
        $seen[$start.GetHash()] = $true
        $maxDepth = 0
        while($q.Count) {
            $item = $q.Dequeue()
            $maxDepth = [math]::max($item.depth, $maxDepth)
            $seen[$item.pos.GetHash()] = $true
            $tokenID = $this.droid.map[$item.pos.GetHash()].tokenID
            if(!($item.depth % 10)) { $this.WriteMap() }
            # $this.WriteMap()
            switch($tokenID) {
                0 { break }
                1 {
                    $this.droid.map[$item.pos.GetHash()].tokenVisual = "X"
                    # add children
                    $next = [point]::new($item.pos.x, $item.pos.y - 1)
                    if(!$seen[$next.GetHash()] -and $this.droid.map.ContainsKey($next.GetHash()) -and ($this.droid.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x, $item.pos.y + 1)
                    if(!$seen[$next.GetHash()] -and $this.droid.map.ContainsKey($next.GetHash()) -and ($this.droid.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x - 1, $item.pos.y)
                    if(!$seen[$next.GetHash()] -and $this.droid.map.ContainsKey($next.GetHash()) -and ($this.droid.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x + 1, $item.pos.y)
                    if(!$seen[$next.GetHash()] -and $this.droid.map.ContainsKey($next.GetHash()) -and ($this.droid.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    break
                }
                2 {
                    $this.droid.map[$item.pos.GetHash()].tokenVisual = "X"
                    # add children
                    $next = [point]::new($item.pos.x, $item.pos.y - 1)
                    if(!$seen[$next.GetHash()] -and $this.droid.map.ContainsKey($next.GetHash()) -and ($this.droid.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x, $item.pos.y + 1)
                    if(!$seen[$next.GetHash()] -and $this.droid.map.ContainsKey($next.GetHash()) -and ($this.droid.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x - 1, $item.pos.y)
                    if(!$seen[$next.GetHash()] -and $this.droid.map.ContainsKey($next.GetHash()) -and ($this.droid.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x + 1, $item.pos.y)
                    if(!$seen[$next.GetHash()] -and $this.droid.map.ContainsKey($next.GetHash()) -and ($this.droid.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    break
                }
            }
        }
        return $maxDepth
    }

    [int] StartDroidAuto() {
        $result = $this.BuildMap()
        $result = $this.BFS([point]::new(0,0))
        return $result
    }

    [int] CalculateOxygenFillTime() {
        $this.goalPoint = $this.BuildMap()
        $this.droid.map[$this.goalPoint.GetHash()] = [tile]::new($this.goalPoint.x, $this.goalPoint.y, 1)
        Write-Host "goalPoint: $($this.goalPoint.GetHash())"
        Start-Sleep 5
        # $result = $this.BFS($this.goalPoint)
        return 0
    }

    StartDroidController() {
        $userInput = '0'
        while($userInput -ne 'q') {
            $userInput = Read-Host "What next (? for help)"
            for($i = 0; $i -lt $userInput.Length; $i++) {
                $input = $userInput[$i]
                switch($input) {
                    'w' {
                        $this.droid.Move(1)
                        $this.droid.LookEW()
                        break
                    }
                    's' {
                        $this.droid.Move(2)
                        $this.droid.LookEW()
                        break
                    }
                    'a' {
                        $this.droid.Move(3)
                        $this.droid.LookNS()
                        break
                    }
                    'd' {
                        $this.droid.Move(4)
                        $this.droid.LookNS()
                        break
                    }
                    'e' { $this.droid.Look(); break }
                    'p' { break }
                    '?' {
                        Write-Host "w : up, s : down, a : left, d : right, e : look around, p : print map, ? : help, q : quit"
                        break
                     }
                     'q' { return }
                     default {
                        Write-Host "invalid input, q for help"
                        break
                     }
                }
            }
            Clear-Host
            $this.WriteMap()
        }
    }
}
