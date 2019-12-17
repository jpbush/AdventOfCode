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
        $this.tokenVisual = [char][byte]$tokenID
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

class Robot {
    [ProgramState] $Brain
    [point] $Location

    Robot([string[]] $BrainCodes) {
        $this.Brain = [ProgramState]::New($BrainCodes, 0, 0, @(), @(), 0)
        $this.Location = [point]::New(0,0)
    }

    AddInput([long[]] $InBuff) {
        $this.Brain.InBuff += $InBuff
    }

    [long[]] GetOutput() {
        $output = $this.Brain.OutBuff
        $this.Brain.OutBuff = @()
        return $output
    }
}

class AftScaffoldControl {
    [ProgramState] $ASCIIProg
    [hashtable] $map
    [int[]] $BoundX
    [int[]] $BoundY
    [Robot] $robot

    AftScaffoldControl([string[]] $ASCIIProg) {
        $this.ASCIIProg = [Robot]::New($ASCIIProg)
        $this.map = @{}
        $this.BoundX = @(0, 0)
        $this.BoundY = @(0, 0)
    }

    UpdateMap([int] $tokenID, [int] $x, [int] $y) {
        $updateLoc = [point]::new($x, $y)
        $this.map[$updateLoc.GetHash()] = [tile]::new($x, $y, $tokenID)
        $this.BoundX[0] = [math]::min($this.BoundX[0], $x)
        $this.BoundX[1] = [math]::max($this.BoundX[1], $x)
        $this.BoundY[0] = [math]::min($this.BoundY[0], $y)
        $this.BoundY[1] = [math]::max($this.BoundY[1], $y)
    }

    WriteMap() {
        $frame = [System.Collections.ArrayList]@()
        
        $line = [System.Collections.ArrayList]@()
        for($x = $this.BoundX[0]-1; $x -le $this.BoundX[1]+1; $x++) { $line.Add("+") }
        $frame.Add(($line -join ""))

        for($y = $this.BoundY[0]; $y -le $this.BoundY[1]; $y++) {
            $line = [System.Collections.ArrayList]@()
            $line.Add("+")
            for($x = $this.BoundX[0]; $x -le $this.BoundX[1]; $x++) {
                $currLocation = [point]::new($x, $y)
                if($this.map.ContainsKey($currLocation.GetHash())) {
                    $line.Add($this.map[$currLocation.GetHash()].tokenVisual)
                }
                else {
                    $line.Add(" ")
                }
            }
            $line.Add("+")
            $frame.Add(($line -join ""))
        }
        
        $line = [System.Collections.ArrayList]@()
        for($x = $this.BoundX[0]-1; $x -le $this.BoundX[1]+1; $x++) { $line.Add("+") }
        $frame.Add(($line -join ""))
        
        Clear-Host
        foreach($line in $frame) {
            Write-Host ($line -join "")
        }
        $frameStr = $frame -join "`n"
    }

    [point] BuildMap() {
        $stack = [System.Collections.Stack]::new()
        $foundGoal = $false
        $direction = 1
        $ittr = 0
        $this.goalPoint = $null
        do {
            $ittr++
            $status = $this.Robot.Move($direction)
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
                        $move.Add($this.Robot.Location)
                        if(!$this.map.ContainsKey($move.GetHash())) {
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
                            1 { $this.Robot.Move(2, $true); break }
                            2 { $this.Robot.Move(1, $true); break }
                            3 { $this.Robot.Move(4, $true); break }
                            4 { $this.Robot.Move(3, $true); break }
                        }
                        $direction = [math]::max(($direction + 1) % 5, 1)
                    }

                    Write-Verbose "Try $direction next"
                    break
            }
            1 {
                    Write-Verbose "Not Wall"
                # up
                $nextLoc = [point]::new($this.Robot.Location.x, ($this.Robot.Location.y - 1))
                Write-Verbose "Try up : $($nextLoc.ToString())"
                if(!$this.map.ContainsKey($nextLoc.GetHash())) {
                    Write-Verbose "send it"
                        $direction = 1
                        break
                    }
                else {
                    Write-Verbose "already been there"
                }
                # down
                $nextLoc = [point]::new($this.Robot.Location.x, ($this.Robot.Location.y + 1))
                Write-Verbose "Try down : $($nextLoc.ToString())"
                if(!$this.map.ContainsKey($nextLoc.GetHash())) {
                    Write-Verbose "send it"
                        $direction = 2
                        break
                    }
                else {
                    Write-Verbose "already been there"
                }
                # left
                $nextLoc = [point]::new(($this.Robot.Location.x - 1), $this.Robot.Location.y)
                Write-Verbose "Try left : $($nextLoc.ToString())"
                if(!$this.map.ContainsKey($nextLoc.GetHash())) {
                    Write-Verbose "send it"
                        $direction = 3
                        break
                }
                else {
                    Write-Verbose "already been there"
                }
                # right
                $nextLoc = [point]::new(($this.Robot.Location.x + 1), $this.Robot.Location.y)
                Write-Verbose "Try right : $($nextLoc.ToString())"
                if(!$this.map.ContainsKey($nextLoc.GetHash())) {
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
                        1 { $this.Robot.Move(2, $true); break }
                        2 { $this.Robot.Move(1, $true); break }
                        3 { $this.Robot.Move(4, $true); break }
                        4 { $this.Robot.Move(3, $true); break }
                    }
                    $direction = [math]::max(($direction + 1) % 5, 1)
                    break
                }
                2 {
                    Write-Host "Found Target at $($this.Robot.Location.GetHash())"
                    $foundGoal = $true
                    $this.goalPoint = [point]::new($this.Robot.Location)
                    break
                }
                default { throw "invalid status $status" }
            }
        } while($stack.Count -gt 0 -or $ittr -lt 2)

        $stack2 = [System.Collections.Stack]::new($stack)
        While($stack2.Count) {
            $this.map[$this.Robot.Location.GetHash()] = [tile]::new($this.location.x, $this.location.y, 3)
            $direction = $stack2.Pop()
            switch($direction) {
                    1 { $this.Robot.Move(2); break }
                    2 { $this.Robot.Move(1); break }
                    3 { $this.Robot.Move(4); break }
                    4 { $this.Robot.Move(3); break }
                }
            Write-Verbose "Depth $($stack2.Count)"
            $this.WriteMap()
        }

        return $this.goalPoint
    }

    [int] BFS([point] $startPos) {
        $q = [System.Collections.Queue]::new()
        $q.Enqueue(@{pos = $startPos; depth = 0})
        $seen = @{}
        $seen[$startPos.GetHash()] = $true
        $maxDepth = 0
        while($q.Count) {
            $item = $q.Dequeue()
            $maxDepth = [math]::max($item.depth, $maxDepth)
            $seen[$item.pos.GetHash()] = $true
            $tokenID = $this.map[$item.pos.GetHash()].tokenID
            if(!($item.depth % 10)) { $this.WriteMap() }
            # $this.WriteMap()
            switch($tokenID) {
                0 { break }
                1 {
                    $this.map[$item.pos.GetHash()].tokenVisual = "X"
                    # add children
                    $next = [point]::new($item.pos.x, $item.pos.y - 1)
                    if(!$seen[$next.GetHash()] -and $this.map.ContainsKey($next.GetHash()) -and ($this.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x, $item.pos.y + 1)
                    if(!$seen[$next.GetHash()] -and $this.map.ContainsKey($next.GetHash()) -and ($this.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x - 1, $item.pos.y)
                    if(!$seen[$next.GetHash()] -and $this.map.ContainsKey($next.GetHash()) -and ($this.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    $next = [point]::new($item.pos.x + 1, $item.pos.y)
                    if(!$seen[$next.GetHash()] -and $this.map.ContainsKey($next.GetHash()) -and ($this.map[$next.GetHash()].tokenID -ne 0)) {
                        $q.Enqueue(@{pos = $next; depth = $item.depth + 1})
                    }
                    break
                }
                2 {
                    return $item.depth
                }
            }
        }
        return $maxDepth
    }

    [int] StartRobotAuto() {
        $result = $this.BuildMap()
        $result = $this.BFS([point]::new(0,0))
        return $result
    }

    [int] CalculateOxygenFillTime() {
        $this.goalPoint = $this.BuildMap()
        $this.map[$this.goalPoint.GetHash()] = [tile]::new($this.goalPoint.x, $this.goalPoint.y, 1)
        $result = $this.BFS($this.goalPoint)
        return $result
    }

    StartAftScaffoldControl() {
        $userInput = '0'
        while($userInput -ne 'q') {
            $userInput = Read-Host "What next (? for help)"
            for($i = 0; $i -lt $userInput.Length; $i++) {
                $input = $userInput[$i]
                switch($input) {
                    'w' {
                        $this.Robot.Move(1)
                        $this.Robot.LookEW()
                        break
                    }
                    's' {
                        $this.Robot.Move(2)
                        $this.Robot.LookEW()
                        break
                    }
                    'a' {
                        $this.Robot.Move(3)
                        $this.Robot.LookNS()
                        break
                    }
                    'd' {
                        $this.Robot.Move(4)
                        $this.Robot.LookNS()
                        break
                    }
                    'e' { $this.Robot.Look(); break }
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
