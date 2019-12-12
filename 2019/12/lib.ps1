

class point {
    [int]$x = 0
    [int]$y = 0
    [int]$z = 0

    point() { }

    point([int] $x, [int] $y, [int] $z) {
        $this.x = $x
        $this.y = $y
        $this.z = $z
    }

    point([point] $p)
    {
        $this.x = $p.x
        $this.y = $p.y
        $this.z = $p.z
    }

    point ([string] $str) 
    {
        # format: "<x=[x], y=[y], z=[z]>"
        $strArr = ($str.Substring(1, $str.Length-2)).Split(',').Trim()
        $strArr = foreach($str in $strArr) {
            $str.Substring(2, $str.Length-2)
        }
        $this.x = $strArr[0]
        $this.y = $strArr[1]
        $this.z = $strArr[2]
    }

    Add ([point] $p)
    {
        $this.x += $p.x
        $this.y += $p.y
        $this.z += $p.z
    }

    AddVector ([vector] $v)
    {
        $this.x += $v.x
        $this.y += $v.y
        $this.z += $v.z
    }

    [string] Hash () 
    {
        return "$($this.x),$($this.y),$($this.z)"
    }

    [string] ToString () 
    {
        return "x=$($this.x),y=$($this.y),z=$($this.z)"
    }
}

class vector {
    [int]$x = 0
    [int]$y = 0
    [int]$z = 0

    vector() { }

    vector([int] $x, [int] $y, [int] $z) {
        $this.x = $x
        $this.y = $y
        $this.z = $z
    }

    vector([vector] $v)
    {
        $this.x = $v.x
        $this.y = $v.y
        $this.z = $v.z
    }

    vector ([string] $str) 
    {
        $split = $str.split(',')
        $this.x = $split[0]
        $this.y = $split[1]
        $this.z = $split[2]
    }

    Add ([vector] $v)
    {
        $this.x += $v.x
        $this.y += $v.y
        $this.z += $v.z
    }

    [string] Hash () 
    {
        return "$($this.x),$($this.y),$($this.z)"
    }

    [string] ToString () 
    {
        return "x=$($this.x),y=$($this.y),z=$($this.z)"
    }
}

class moon {
    [string] $name
    [point] $location
    [vector] $velocity

    moon([string] $name, [point] $location) {
        $this.name = $name
        $this.location = [point]::new($location)
        $this.velocity = [vector]::new(0,0,0)
    }

    ApplyVelocity ([int] $axis = -1) {
        if($axis -lt 0 -or $axis -eq 0) {
            $this.location.x += $this.velocity.x
        }
        
        if($axis -lt 0 -or $axis -eq 1) {
            $this.location.y += $this.velocity.y
        }
        
        if($axis -lt 0 -or $axis -eq 2) {
            $this.location.z += $this.velocity.z
        }
    }

    [int] CalculateEnergy() {
        $p = $this.location
        $v = $this.velocity
        $potential = [math]::Abs($p.x) + [math]::Abs($p.y) + [math]::Abs($p.z)
        $kinetic = [math]::Abs($v.x) + [math]::Abs($v.y) + [math]::Abs($v.z)
        $energy = $potential * $kinetic
        return $energy
    }

    [string] Hash () {
        return "$($this.name)"
    }

    [string] ToString () {
        return "$($this.name), $($this.location.ToString()), $($this.velocity.ToString())"
    }
}

class system {
    [moon[]] $moons
    [hashtable] $uniquePairs
    [int] $tick

    system([moon[]] $moons) {
        $this.moons = $moons
        $this.tick = 0
        $this.BuildUniquePairs()
    }

    system([point[]] $locations) {
        $i = 0
        $this.moons = foreach($loc in $locations) {
            [moon]::new("moon$i", $loc)
            $i++
        }
        $this.tick = 0
        $this.BuildUniquePairs()
    }

    BuildUniquePairs() {
        $this.uniquePairs = @{}
        for($i = 0; $i -lt $this.moons.Length; $i++) {
            $m1 = $this.moons[$i]
            for($j = 0; $j -lt $this.moons.Length; $j++) {
                $m2 = $this.moons[$j]
                $hash1 = "$($m1.name), $($m2.name)"
                $hash2 = "$($m2.name), $($m1.name)"
                if(($m1.name -ne $m2.name) -and !$this.uniquePairs.ContainsKey($hash1) -and !$this.uniquePairs.ContainsKey($hash2)) {
                    $this.uniquePairs[$hash1] = @{m1 = $m1; m2 = $m2}
                }
            }
        }
    }

    ApplyGravityPair([moon] $m1, [moon] $m2, [int] $axis = -1) {
        $p1 = $m1.location
        $p2 = $m2.location
        
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

    ApplyGravity([int] $axis = -1) {
        foreach($key in $this.uniquePairs.Keys) {
            $pair = $this.uniquePairs[$key]
            $m1 = $pair.m1
            $m2 = $pair.m2

            $this.ApplyGravityPair($m1, $m2, $axis)
        }
    }

    ApplyVelocity([int] $axis = -1) {
        foreach($m in $this.moons) {
            $m.ApplyVelocity($axis)
        }
    }

    DoTick([int] $axis = -1) {
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

    [string] GetState() {
        $ret = @()
        foreach($m in $this.moons) {
            $ret += $m.ToString()
        }
        return $ret -join "`n"
    }

    [int] CalculateEnergy() {
        $energy = 0
        foreach($m in $this.moons) {
            $energy += $m.CalculateEnergy()
        }
        return $energy
    }

    [long] gcd([long]$a, [long]$b) {
        while($b -gt 0) {
            $temp = $b
            $b = $a % $b
            $a = $temp
        }
        return $a
    }
    
    [long] lcm([long]$a, [long]$b) {
        return [math]::floor(($a * $b) / ($this.gcd($a, $b)))
    }
}