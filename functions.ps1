#Drop file for useful functions

#From https://github.com/ironmansoftware/ud-bginfo/blob/master/ud-bginfo.psm1
function New-UDProgressMetric {
    param($Total, $Value, $Metric, $Label, [Switch]$HighIsGood)

    $Percent = [Math]::Round(($Value / $Total) * 100)
    New-UDElement -Tag "h5" -Content { $Label }

    New-UDElement -Tag "div" -Attributes @{ className = "row" } -Content {
        New-UDElement -Tag "span" -Attributes @{ className = "grey-text lighten-1" } -Content { "$Percent% - $($Value.ToString('N')) of $($Total.ToString('N')) $Metric" }
    } 

    if ($HighIsGood) {
        if ($Percent -lt 20) {
            $Color = 'red'
        }
        elseif ($Percent -gt 25 -and $Percent -lt 75) {
            $Color = 'yellow'
        } else {
            $Color = 'green'
        }
    
    } else {
        if ($Percent -lt 50) {
            $Color = 'green'
        }
        elseif ($Percent -gt 50 -and $Percent -lt 75) {
            $Color = 'yellow'
        } else {
            $Color = 'red'
        }
    
    }


    New-UDElement -Tag "div" -Attributes @{ className = 'progress grey' } -Content {
        New-UDElement -Tag "div" -Attributes @{ className = "determinate $color"; style = @{ width = "$Percent%"} }
    }    
}
