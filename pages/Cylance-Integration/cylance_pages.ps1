$CylanceBaseURL = "https://protect.cylance.com/Reports/ThreatDataReportV1/"
$APIToken = "75630645C8074CF6B9B9D95FFB425744" #replace with query
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
$ThreatAction = $ThreatData | Group-Object -Property "File Status"
$CylanceOSList = $DeviceData | Group-Object -Property "OS Version" | Sort-Object -property count -Descending | select count, name -First 10
$OnlineHosts = ($DeviceData | Where-Object -Property "Is Online" -EQ "True").count
$Classifications = $Threatdata | Group-Object -Property Classification | Sort-Object -Property Count -Descending | Select Count, Name -First 10
$ClearedThreatsByType = $ClearedData | Group-Object -Property Classification | Sort-Object Count -Descending | Select Count, Name -First 10
$RecentMemoryProtectHits = $MemProtectData.count
$CylanceComputerCount = $DeviceData.Count

#Clean up text
Foreach ($os in $CylanceOSList) {
    $os.name = $os.name.trim("Microsoft")
    $os.name = $os.name.trim("Â®")
    $os.name = $os.name.replace("Windows","Win")
    $os.name = $os.name.replace("Enterprise","Ent")}


$CylancePage = New-UDPage -Name "Cylance" -Icon unlock -Content {
    New-UDLayout -Columns 3 -Content {
        New-UDChart -Title "Devices by Zone" -Type HorizontalBar -Endpoint {
            $DevicesByZone | Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor @("#75cac3","#2a6171","#f3d516","#4b989e","#86df4a","#b816f3","#f31651","#4e4b9e") -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
        }
        New-UDChart -Title "Devices by Policy" -Type HorizontalBar -Endpoint {
            $DevicesByPolicy | Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor @("#75cac3","#2a6171","#f3d516","#4b989e","#86df4a","#b816f3","#f31651","#4e4b9e") -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
        }
        New-UDChart -Title "Top 10 Computers with Blocked Events" -Type Doughnut -Endpoint {
            $Top10ComputersWithBlockedThreats | Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor @("#75cac3","#2a6171","#f3d516","#4b989e","#86df4a","#b816f3","#f31651","#4e4b9e","#1F1F1F","#777777","#FFFFFF") -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
        }
        New-UDChart -Title "Quarantined vs Unquarantined Events" -Type Doughnut -Endpoint {
            $ThreatAction | Out-UDChartData -DataProperty Count -Label Name -BackgroundColor @("#75cac3","#2a6171","#f3d516","#4b989e","#86df4a","#b816f3","#f31651","#4e4b9e","#1F1F1F","#777777","#FFFFFF") -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
        }
        New-UDChart -Title "OS of Cylance Computers" -Type Doughnut -Endpoint {
            $CylanceOSList | Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor @("#75cac3","#2a6171","#f3d516","#4b989e","#86df4a","#b816f3","#f31651","#4e4b9e","#1F1F1F","#777777","#FFFFFF") -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
        }
        New-UDChart -Title "Cleared Threats by Type" -Type Doughnut -Endpoint {
            $ClearedThreatsByType | Out-UDChartData -DataProperty Count -Label Name -BackgroundColor @("#75cac3","#2a6171","#f3d516","#4b989e","#86df4a","#b816f3","#f31651","#4e4b9e","#1F1F1F","#777777","#FFFFFF") -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
        }
        New-UDCounter -Title "Cylance Computers" -Endpoint {
            $CylanceComputerCount
        }
        New-UDCounter -Title "Cylance Memory Protection Events (Past 7 Days)" -Endpoint {
            $RecentMemoryProtectHits
        }
    }
}