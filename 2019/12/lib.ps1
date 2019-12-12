

class point {
    [int]$x = 0
    [int]$y = 0

    point() { }

    point([int] $x, [int] $y) {
        $this.x = $x
        $this.y = $y
    }

    point([point] $p)
    {
        $this.x = $p.x
        $this.y = $p.y
    }

    point ([string] $str) 
    {
        $split = $str.split(',')
        $this.x = $split[0]
        $this.y = $split[1]
    }

    Add ([point] $p)
    {
        $this.x += $p.x
        $this.y += $p.y
    }

    AddVector ([vector] $v)
    {
        $this.x += $v.x
        $this.y += $v.y
    }

    [string] Hash () 
    {
        return "$($this.x),$($this.y)"
    }

}

class vector {
    [int]$x = 0
    [int]$y = 0

    vector() { }

    vector([vector] $v)
    {
        $this.x = $v.x
        $this.y = $v.y
    }

    Add ([vector] $v)
    {
        $this.x += $v.x
        $this.y += $v.y
    }

    [string] Hash () 
    {
        return "x: $($this.x), y: $($this.y)"
    }
}
