class reactant {
    [string] $name
    [long] $amount

    reactant([string] $name, [long] $amount) {
        $this.name = $name
        $this.amount = $amount
    }

    reactant([string] $formattedStr) {
        $split = $formattedStr.Split().Trim()
        $this.amount = $split[0]
        $this.name = $split[1]
    }

    [string] GetHash() 
    {
        return "$($this.name),$($this.amount)"
    }

    [string] ToString() 
    {
        return "$($this.amount) $($this.name)"
    }
}

class reaction {
    [reactant] $output
    [reactant[]] $inputs

    reaction([string] $formattedStr) {
        $split = $formattedStr.Split('=>').Trim()
        $inStrs = $split[0].Split(',').Trim()
        $outStr = $split[2]
        $this.inputs = foreach($str in $inStrs) {
            [reactant]::new($str)
        }
        $this.output = [reactant]::new($outStr)
    }

    [string] GetHash() 
    {
        $inputStr = foreach($in in $this.inputs) { $in.GetHash() }
        $inputStr = $inputStr -join ","
        return "$($this.output.GetHash()),$inputStr"
    }

    [string] ToString() 
    {
        $inputStr = foreach($in in $this.inputs) { $in.ToString() }
        $inputStr = $inputStr -join ", "
        return "$inputStr => $($this.output.ToString())"
    }
}

class nanoFactory {
    [hashtable] $reactions

    nanoFactory([string[]] $reactionStrs) {
        $this.reactions = @{}
        foreach($str in $reactionStrs) {
            $reaction = [reaction]::new($str)
            $key = $reaction.output.name
            if(!$this.reactions.ContainsKey($key)) {
                $this.reactions[$key] = $reaction
            }
            else {
                throw "oops, there is more than one way to make $key"
            }
        }
    }

    [long] GetOreCost([string] $name, [long] $amount) {
        $need = @{"$name" = $amount}
        $have = @{}
        $oreNeed = 0
        while($need.Count -gt 0) {
            $needStr = foreach($outName in $need.Keys) {"$($need[$outName]) $outName"}
            $needStr = $needStr -join ", "
            Write-verbose "Need: $needStr"

            $newNeed = @{}
            foreach($outName in $need.Keys) {
                $outNeed = $need[$outName]

                # Use up what we have first
                if($have.ContainsKey($outName)) {
                    $outHave = $have[$outName]
                    Write-verbose "Have $outHave $outName"

                    if($outNeed -lt $outHave) {
                        $have[$outName] -= $outNeed
                        $outNeed = 0
                    }
                    elseif($outNeed -eq $outHave) {
                        $have.Remove($outName)
                        $outNeed = 0
                    }
                    else {
                        $have.Remove($outName)
                        $outNeed -= $outHave
                    }
                }

                # Figure out what we need to make this need
                if($outNeed -gt 0) {
                    Write-verbose "Still need $outNeed $outName"

                    $reaction = $this.reactions[$outName]
                    $reactionMultiplier = [math]::Ceiling($outNeed / $reaction.output.amount)
                    $outProduced = $reaction.output.amount * $reactionMultiplier
                    $have[$outName] = $outProduced - $outNeed

                    foreach($input in $reaction.inputs) {
                        $inputNeed = $input.amount * $reactionMultiplier
                        Write-Verbose "Adding need $inputNeed $($input.name) for $outProduced $outName"
                        if($input.name -eq "ORE") {
                            $oreNeed += $inputNeed
                        }
                        else {
                            $newNeed[$input.name] += $inputNeed
                        }
                    }
                }
            }

            $need = $newNeed
        }

        return $oreNeed
    }

    [string] GetHash() 
    {
        $hash = foreach($reaction in $this.reactions) { $reaction.GetHash() }
        $hash = $hash -join ","
        return "$hash"
    }

    [string] ToString() 
    {
        $str = foreach($reaction in $this.reactions) { $reaction.ToString() }
        $str = $str -join "`n"
        return "$str"
    }
}
