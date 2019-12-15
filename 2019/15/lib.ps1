
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
            2 { "+"; break }
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
        $this.BoundX = @(999, -999)
        $this.BoundY = @(999, -999)
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
        $this.map[$this.location.GetHash()] = [tile]::new($x, $y, $tokenID)
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
    [int] Move([int] $direction) {

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
                UpdateMap(0, $x, $y)
            }
            1 {
                $this.Location.Add($move)
                UpdateMap(1, $this.Location.x, $this.Location.y)
            }
            2 {
                $this.Location.Add($move)
                UpdateMap(2, $this.Location.x, $this.Location.y)
            }
        }

        return $status
    }
}

class DroidController {
    [Droid] $droid

    DroidController([string[]] $droidCodes) {
        $this.droid = [Droid]::New($droidCodes)
    }

    WriteMap() {
        for($y = $this.droid.BoundY[0]; $y -lt $this.droid.BoundY[1]; $y++) {
            for($x = $this.droid.BoundX[0]; $x -lt $this.droid.BoundX[1]; $x++) {
                $currLocation = [point]::new($x, $y)
                if($currLocation.Equals($x, $y)) {
                    Write-Host "@" -NoNewline
                }
                elseif($this.map.ContainsKey($currLocation.GetHash())) {
                    Write-Host $this.map[$currLocation.GetHash()].tokenVisual -NoNewline
                }
                else {
                    Write-Host " " -NoNewline
                }
            }
            Write-Host
        }
    }

    StartDroidController() {
        $userInput = '0'
        while($userInput -ne 'q') {
            $userInput = Read-Host "What next (? for help)"

            switch($userInput) {
                'u' { $this.droid.Move(1); break }
                'd' { $this.droid.Move(2); break }
                'l' { $this.droid.Move(3); break }
                'r' { $this.droid.Move(4); break }
                '?' {
                    Write-Host "u : up, d : down, l : left, r : right, ? : help, q : quit"
                    break
                 }
                 'q' { return }
                 default {
                    Write-Host "invalid input, q for help"
                    break
                 }
            }

            $this.WriteMap()
        }
    }
}
