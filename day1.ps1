# to run: 
# (Get-Content .\day1in.txt | ForEach-Object {Resolve-FuelBasic -Mass $_} | Measure-Object -Sum).Sum
function Resolve-FuelBasic()
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [int]
        $Mass
    )

    Return [math]::floor($Mass / 3) - 2
}

# to run: 
# (Get-Content .\day1in.txt | ForEach-Object {Resolve-FuelBasic -Mass $_} | Measure-Object -Sum).Sum
function Resolve-FuelRecurse()
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [int]
        $Mass
    )

    $fuelMass = [math]::floor($Mass / 3) - 2
    if($fuelMass -le 0)
    {
        return 0
    }
    else
    {
        return $fuelMass + (Resolve-FuelRecurse -Mass $fuelMass)
    }
}
