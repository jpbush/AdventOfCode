

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
    
    Write-Verbose "searchNum: $searchNum"

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

# 0 is black, 1 is white, and 2 is transparent.
function Run-Part2
{
    [CmdletBinding()]
    param(
        [string] $InFilename,
        [int] $Width,
        [int] $Height,
        [int] $searchNum
    )
    "searchNum: $searchNum"

    $outFilename = "out.txt"
    Remove-Item $outFilename

    $imgStr = (Get-Content -Path $InFilename)
    $layerSize = $Width * $Height
    Write-Verbose "layerSize: $layerSize"
    $imgLayers = @()
    for ($i = 0; $i -lt $imgStr.Length; $i += $layerSize) {
        $imgLayers += ,@($imgStr[$i..($i+$layerSize-1)])
    }
    $layerCount = $imgLayers.Length
    Write-Verbose "LayerCount: $layerCount"
    
    for($j = 0; $j -lt $layerCount; $j++) {
        $layer = $imgLayers[$j]
        Write-Verbose "Layer $layer"
    }

    $minCount = $null
    $minLayer = $null
    $minLayerIndex = $null
    $output = ,-1 * $layerSize
    for ($i = 0; $i -lt $layerSize; $i++) {
        $colorFound = 2
        for($j = 0; $j -lt $layerCount; $j++) {
            $layer = $imgLayers[$j]
            $color = $layer[$i]
            Write-Verbose "Layer $j processed for pixel $i, color: $color"
            if ($color -ne '2') {
                $colorFound = $color
                break
            }
        }
        $output[$i] = $colorFound
    }

    for($i = 0; $i -lt $layerSize; $i+=$Width) {
        $row = $output[$i..($i+$Width-1)]

        $result = ($row -join ",")
        Write-Host $result
        $result | Out-File -FilePath $outFilename -Append
    }
    # "sep=," | Out-File -FilePath $outFilename -Append
}
