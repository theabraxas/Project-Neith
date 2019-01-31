$CylanceBaseURL = "https://protect.cylance.com/Reports/ThreatDataReportV1/"
$APIToken = "75630645C8074CF6B9B9D95FFB425744"
$APIEndpoints = "threats,devices,events,indicators,cleared,policies,externaldevices,memoryprotection"

#Initial Objects
$DeviceData = Invoke-RestMethod -Method Get -Uri "$CylanceBaseURL/devices/$ApiToken" | ConvertFrom-CSV
$ThreatData = Invoke-RestMethod -Method Get -Uri "$CylanceBaseURL/threats/$ApiToken" | ConvertFrom-CSV
$EventsData = Invoke-RestMethod -Method Get -Uri "$CylanceBaseURL/events/$ApiToken" | ConvertFrom-CSV
$IndicatorData = Invoke-RestMethod -Method Get -Uri "$CylanceBaseURL/indicators/$ApiToken" | ConvertFrom-CSV
$ClearedData = Invoke-RestMethod -Method Get -Uri "$CylanceBaseURL/cleared/$ApiToken" | ConvertFrom-CSV
$PolicyData = Invoke-RestMethod -Method Get -Uri "$CylanceBaseURL/policies/$ApiToken" | ConvertFrom-CSV
$ExtDevData = Invoke-RestMethod -Method Get -Uri "$CylanceBaseURL/externaldevices/$ApiToken" | ConvertFrom-CSV
$MemProtectData = Invoke-RestMethod -Method Get -Uri "$CylanceBaseURL/memoryprotection/$ApiToken" | ConvertFrom-CSV

#Chart Data
$Top10ComputersWithBlockedThreats = $ClearedData | Group-Object -property "Device Name" | Sort-Object -Property "Count" -Descending | Select-Object Count, Name -First 10 
$DevicesByZone = $DeviceData | Group-Object -Property Zones | Select-Object Count,Name
$DevicesByPolicy = $DeviceData | Group-Object -Property Policy | Select-Object Count,Name

#Other Stats
$CylanceComputerCount = $DeviceData.Count

$dash = New-UDDashboard -Title "Cylance Dashboard" -Content {
    New-UDLayout -Columns 3 -Content {
        New-UDChart -Title "Devices by Zone" -Type Bar -Endpoint {
            $DevicesByZone | Foreach-Object {
                [PSCustomObject]@{ 
                    Count = $_.Count;
                    Zone = $_.Name;
                    }
                } | Out-UDChartData -DataProperty Count -LabelProperty Zone -BackgroundColor '#FF530D' -BorderColor 'black' -HoverBackgroundColor '#FF9F0D' -
        }
        New-UDChart -Title "Devices by Policy" -Type Bar -Endpoint {
            $DevicesByPolicy | Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor '#FF530D' -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
        }
        New-UDChart -Title "Top 10 Computers with Blocked Events" -Type Doughnut -Endpoint {
            $Top10ComputersWithBlockedThreats | Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor '#FF530D' -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
        }
    }
}

Start-UDDashboard -Dashboard $dash -port81
