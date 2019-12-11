<#
--- Day 4: Secure Container ---
You arrive at the Venus fuel depot only to discover it's protected by a password. The Elves had written the password on a sticky note, but someone threw it out.

However, they do remember a few key facts about the password:

It is a six-digit number.
The value is within the range given in your puzzle input.
Two adjacent digits are the same (like 22 in 122345).
Going from left to right, the digits never decrease; they only ever increase or stay the same (like 111123 or 135679).
Other than the range rule, the following are true:

111111 meets these criteria (double 11, never decreases).
223450 does not meet these criteria (decreasing pair of digits 50).
123789 does not meet these criteria (no double).
How many different passwords within the range given in your puzzle input meet these criteria?

Your puzzle input is 356261-846303.
#>

<#
Rules:
    1. 6 digits
    2. Two adjacent digits are the same (like 22 in 122345).
    3. Going from left to right, the digits never decrease
    4. within the range given in your puzzle input

How many different passwords within the range given in your puzzle input meet these criteria
#>
$Script:PwLength = 6

function Confirm-ValidPassword1
{
    param(
        [int] $Word
    )

    $wordStr = $Word.ToString()

    if($WordStr.Length -ne $Script:PwLength) {
        return $false
    }
    $hasPair = $false
    for($i = 1; $i -lt $wordStr.Length; $i++) {
        $c1 = $wordStr[$i-1]
        $c2 = $wordStr[$i]

        if($c1 -eq $c2) {
            $hasPair = $true
        }
        if($c1 -gt $c2) {
            return $false
        }
    }
    return $hasPair
}
function Confirm-ValidPassword2
{
    param(
        [int] $Word
    )

    $wordStr = $Word.ToString()

    if($WordStr.Length -ne $Script:PwLength) {
        return $false
    }

    $hasPair = $false
    $runLength = 0
    $c0 = $wordStr[0]
    for($i = 1; $i -lt $wordStr.Length; $i++) {
        $c1 = $wordStr[$i]

        # Write-Host "pair: $c0, $c1"
        if($c0 -eq $c1) {
            $runLength++
            # Write-Host "runlength: $runLength"
        }
        elseif($runLength -eq 1) {
            # Write-Host "Found pair"
            $hasPair = $true
        }
        else {
            $runLength = 0
        }

        if($c0 -gt $c1) {
            return $false
        }

        $c0 = $c1
    }
    
    return $hasPair -or ($runLength -eq 1)
}

function Find-NumPasswordsInRange1
{
    param(
        [int] $MinVal,
        [int] $MaxVal
    )
    $count = 0
    for($i = $MinVal; $i -lt $MaxVal; $i++) {
        if(Confirm-ValidPassword1 -Word $i) {
            Write-Host "Valid: [$i]"
            $count++
        }
    }
    
    Write-Host "Count: [$count]"
}

function Find-NumPasswordsInRange2
{
    param(
        [int] $MinVal,
        [int] $MaxVal
    )
    $count = 0
    for($i = $MinVal; $i -lt $MaxVal; $i++) {
        if(Confirm-ValidPassword2 -Word $i) {
            Write-Host "Valid: [$i]"
            $count++
        }
    }
    
    Write-Host "Count: [$count]"
}
