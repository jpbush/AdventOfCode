

class point {
    [int]$x = 0
    [int]$y = 0
    [int]$z = 0

    point(){ }

    point([int] $x, [int] $y, [int] $z) {
        $this.Set($x, $y, $z)
    }

    point([point] $p) {
        $this.Set($p.x, $p.y, $p.z)
    }

    point([string] $str) {
        # format: "<x=[x], y=[y], z=[z]>"
        $strArr = ($str.Substring(1, $str.Length-2)).Split(',').Trim()
        $strArr = foreach($str in $strArr) {
            $str.Substring(2, $str.Length-2)
        }
        $this.Set($strArr[0], $strArr[1], $strArr[2])
    }

    Set([int] $x, [int] $y, [int] $z) {
        $this.x = $x
        $this.y = $y
        $this.z = $z
    }

    Add([int] $x, [int] $y, [int] $z) {
        $this.x += $x
        $this.y += $y
        $this.z += $z
    }

    Add([point] $p) {
        $this.Add($p.x, $p.y, $p.z)
    }

    AddVector([vector] $v) {
        $this.Add($v.x, $v.y, $v.z)
    }

    [string] GetHash() 
    {
        return "$($this.x),$($this.y),$($this.z)"
    }

    [string] ToString() 
    {
        return "x=$($this.x), y=$($this.y), z=$($this.z)"
    }
}

class vector {
    [int]$x = 0
    [int]$y = 0
    [int]$z = 0

    vector(){ }

    vector([int] $x, [int] $y, [int] $z) {
        $this.Set($x, $y, $z)
    }

    vector([vector] $v) {
        $this.Set($v.x, $v.y, $v.z)
    }

    Set([int] $x, [int] $y, [int] $z) {
        $this.x = $x
        $this.y = $y
        $this.z = $z
    }

    Add([int] $x, [int] $y, [int] $z) {
        $this.x += $x
        $this.y += $y
        $this.z += $z
    }

    Add([vector] $v) {
        $this.Add($v.x, $v.y, $v.z)
    }

    [string] GetHash() 
    {
        return "$($this.x),$($this.y),$($this.z)"
    }

    [string] ToString() 
    {
        return "x=$($this.x), y=$($this.y), z=$($this.z)"
    }
}

class moon {
    [string] $name
    [point] $position
    [vector] $velocity

    moon([string] $name, [point] $position) {
        $this.name = $name
        $this.position = [point]::new($position)
        $this.velocity = [vector]::new(0,0,0)
    }

    ApplyVelocity([int] $axis) {
        switch ($axis) {
            0 {
                $this.position.x += $this.velocity.x
            }
            1 {
                $this.position.y += $this.velocity.y
            }
            2 {
                $this.position.z += $this.velocity.z
            }
            default {
                $this.position.AddVector($this.velocity)
            }
        }
    }

    [int] CalculateEnergy() {
        $p = $this.position
        $v = $this.velocity
        $potential = [math]::Abs($p.x) + [math]::Abs($p.y) + [math]::Abs($p.z)
        $kinetic = [math]::Abs($v.x) + [math]::Abs($v.y) + [math]::Abs($v.z)
        $energy = $potential * $kinetic
        return $energy
    }

    [string] GetHash() {
        return "$($this.name),$($this.position.GetHash()),$($this.velocity.GetHash())"
    }

    [string] ToString() {
        return "$($this.name), position: $($this.position.ToString()), velocity: $($this.velocity.ToString())"
    }
}

class system {
    [moon[]] $moons
    [hashtable] $uniquePairs
    [long] $tick

    system([point[]] $positions) {
        $i = 0
        $this.moons = foreach($pos in $positions) {
            [moon]::new("moon-$i", $pos)
            $i++
        }
        $this.tick = 0
        $this.BuildUniquePairs()
    }

    BuildUniquePairs() {
        $this.uniquePairs = @{}
        foreach($m1 in $this.moons) {
            foreach($m2 in $this.moons) {
                $hash1 = "$($m1.name), $($m2.name)"
                $hash2 = "$($m2.name), $($m1.name)"
                if(($m1.name -ne $m2.name) -and !$this.uniquePairs.ContainsKey($hash1) -and !$this.uniquePairs.ContainsKey($hash2)) {
                    $this.uniquePairs[$hash1] = @{m1 = $m1; m2 = $m2}
                }
            }
        }
    }

    ApplyGravityPair([moon] $m1, [moon] $m2, [int] $axis) {
        $p1 = $m1.position
        $p2 = $m2.position
        
        if($axis -lt 0 -or $axis -eq 0) {
            if($p1.x -lt $p2.x) {
                $m1.velocity.x++
                $m2.velocity.x--
            }
            elseif($p1.x -gt $p2.x) {
                $m1.velocity.x--
                $m2.velocity.x++
            }
        }
        
        if($axis -lt 0 -or $axis -eq 1) {
            if($p1.y -lt $p2.y) {
                $m1.velocity.y++
                $m2.velocity.y--
            }
            elseif($p1.y -gt $p2.y) {
                $m1.velocity.y--
                $m2.velocity.y++
            }
        }
        
        if($axis -lt 0 -or $axis -eq 2) {
            if($p1.z -lt $p2.z) {
                $m1.velocity.z++
                $m2.velocity.z--
            }
            elseif($p1.z -gt $p2.z) {
                $m1.velocity.z--
                $m2.velocity.z++
            }
        }
    }

    ApplyGravity([int] $axis) {
        foreach($key in $this.uniquePairs.Keys) {
            $pair = $this.uniquePairs[$key]
            $this.ApplyGravityPair($pair.m1, $pair.m2, $axis)
        }
    }

    ApplyVelocity([int] $axis) {
        foreach($m in $this.moons) {
            $m.ApplyVelocity($axis)
        }
    }

    [int] CalculateEnergy() {
        $energy = 0
        foreach($m in $this.moons) {
            $energy += $m.CalculateEnergy()
        }
        return $energy
    }

    DoTick([int] $axis) {
        $this.ApplyGravity($axis)
        $this.ApplyVelocity($axis)
        $this.tick++
    }

    [string] ToString() {
        $ret = @("Tick: $($this.tick)")
        foreach($m in $this.moons) {
            $ret += $m.ToString()
        }
        return $ret -join "`n"
    }

    [string] GetHash() {
        $ret = @()
        foreach($m in $this.moons) {
            $ret += $m.GetHash()
        }
        return $ret -join ","
    }
}

function gcd {
    param (
        [long]$n1,
        [long]$n2
    )
    while($n2 -gt 0) {
        $temp = $n2
        $n2 = $n1 % $n2
        $n1 = $temp
    }
    return $n1
}

function lcm {
    param (
        [long]$n1,
        [long]$n2
    )
    return [math]::floor(($n1 * $n2) / (gcd -n1 $n1 -n2 $n2))
}
