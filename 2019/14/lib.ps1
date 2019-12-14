class reactant {
    [string] $name
    [int] $amount

    reactant([string] $name, [int] $amount) {
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

    [long] GetOreCost([string] $name, [int] $amount) {
        $need = @{"$name" = $amount}
        $have = @{}
        $oreNeeded = 0
        while($need.Count -gt 0) {
            $str = foreach($needName in $need.Keys) {"$($need[$needName]) $needName"}
            $str = $str -join ", "
            Write-verbose "Need: $str"

            $newNeed = @{}
            foreach($needName in $need.Keys) {
                $amountNeed = $need[$needName]

                # Use up what we have
                if($have.ContainsKey($needName)) {
                    Write-verbose "Have $($have[$needName]) $needName"

                    $amountHave = $have[$needName]
                    if($amountNeed -lt $amountHave) {
                        $have[$needName] -= $amountNeed
                        $amountNeed = 0
                    }
                    elseif($amountNeed -eq $amountHave) {
                        $have.Remove($needName)
                        $amountNeed = 0
                    }
                    else {
                        $have.Remove($needName)
                        $amountNeed -= $amountHave
                    }
                }

                # Figure out what we need to make this need
                if($amountNeed -gt 0) {
                    Write-verbose "Still need $amountNeed $needName"

                    $reaction = $this.reactions[$needName]
                    $numReactions = [math]::Ceiling($amountNeed / $reaction.output.amount)
                    $produced = $reaction.output.amount * $numReactions
                    $have[$needName] = $produced - $amountNeed

                    foreach($input in $reaction.inputs) {
                        $inputTotal = $input.amount * $numReactions
                        if($input.name -eq "ORE") {
                            Write-Verbose "ORE $inputTotal for $produced $needName"
                            $oreNeeded += $input.amount * $numReactions
                        }
                        else {
                            Write-Verbose "Adding need $inputTotal $($input.name) for $produced $needName"
                            $newNeed[$input.name] += $input.amount * $numReactions
                        }
                    }
                }
            }

            # merge needs
            $need = $newNeed
        }

        return $oreNeeded
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