

function Count-Nums{
    param(
        [string] $inStr,
        [string] $searchNum
    )

    $count = 0
    for ($i = 0; $i -lt $inStr.Length; $i++) {
        if ($inStr[$i] -eq $searchNum) {
            $count++
        }
    }

    return $count
}
function Run-Part1
{
    [CmdletBinding()]
    param(
        [string] $InFilename,
        [int] $Width,
        [int] $Height,
        [int] $searchNum
    )
    
    "searchNum: $searchNum"

    $imgStr = (Get-Content -Path $InFilename)
    $layerSize = $Width * $Height
    Write-Verbose "layerSize: $layerSize"
    $imgLayers = @()
    for ($i = 0; $i -lt $imgStr.Length; $i += $layerSize) {
        $imgLayers += ,@($imgStr[$i..($i+$layerSize-1)])
    }
    Write-Verbose "LayerCount: $($imgLayers.Length)"

    $minCount = $null
    $minLayer = $null
    $minLayerIndex = $null
    for ($i = 0; $i -lt $imgLayers.Length; $i++) {
        
        ""

        $layer = $imgLayers[$i]
        $numNums = Count-Nums -inStr $layer -searchNum $searchNum

        "layer: $layer"
        "numNums: $numNums"

        if(($minCount -eq $null) -or ($numNums -lt $minCount)) {
            $minCount = $numNums
            $minLayerIndex = $i
            $minLayer = $layer
            
            "minCount: $minCount"
            "minLayerIndex: $minLayerIndex"
        }
    }

    
    $count1s = Count-Nums -inStr $minLayer -searchNum 1
    $count2s = Count-Nums -inStr $minLayer -searchNum 2
    "count1s: $count1s"
    "count2s: $count2s"

    $answer = $count1s * $count2s

    Write-Host "Answer: $answer"
}

function Run-Part2
{
    [CmdletBinding()]
    param(
        [string] $InFilename
    )
}
