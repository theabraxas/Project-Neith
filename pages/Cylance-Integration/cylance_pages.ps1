Set-Location SQLSERVER:\SQL\$computername\DEFAULT\databases\$dbname 

$CylanceActive = Invoke-SqlCmd -Query "SELECT active FROM template_configs WHERE template_name = 'Cylance'"
$Query = "SELECT * FROM cylance_threat_data WHERE device_name = '$ComputerName'"
$DetectionData = Invoke-Sqlcmd -Query $Query
$Query = "SELECT * FROM cylance_device_data WHERE device_name = '$ComputerName'"
$AgentData = Invoke-Sqlcmd -Query $Query
$Threattypes = @()

Foreach ($Threat in $DetectionData) {
    $Threattypes += $Threat.classification}
$Threats_by_type = $Threattypes | Group-Object |Select Name,Count



If ($CylanceActive.active -eq "yes") {
    $Ddata = Invoke-Sqlcmd -Query "Select * from cylance_device_data"
    $Tdata = Invoke-Sqlcmd -Query "Select * from cylance_threat_data"
    $Edata = Invoke-Sqlcmd -Query "Select * from cylance_event_data"
    $Cdata = Invoke-Sqlcmd -Query "Select * from cylance_cleared_data"
    $MData = Invoke-Sqlcmd -Query "Select * from cylance_memprotect_data"

    #Chart Data
    $Top10ComputersWithBlockedThreats = $ClearedData | Group-Object -property "Device Name" | Sort-Object -Property "Count" -Descending | Select-Object Count, Name -First 10 
    $Top10ComputersWithBlockedThreats = $CData |Group-Object -Property "device_name" |Sort-Object -Property "Count" -Descending |Select-Object Count, Name -First 10
    $DevicesByZone = $DeviceData | Group-Object -Property Zones | Select-Object Count, Name
    $DevicesByZone = $Ddata | Group-Object -Property Zones | Select-Object Count, Name
    $DevicesByPolicy = $DeviceData | Group-Object -Property Policy | Select-Object Count,Name
    $DevicesByPolicy = $DData | Group-Object -Property Policy | Select-Object Count,Name
    $ThreatAction = $ThreatData | Group-Object -Property "File Status"
    $ThreatAction = $TData | Group-Object -Property "file_status"
    $CylanceOSList = $DeviceData | Group-Object -Property "OS Version" | Sort-Object -property count -Descending | select count, name -First 10
    $CylanceOSList = $DData | Group-Object -Property "OS_Version" | Sort-Object -property count -Descending | select count, name -First 10
    $OnlineHosts = ($DeviceData | Where-Object -Property "Is Online" -EQ "True").count
    $OnlineHosts = ($DData | Where-Object -Property "is_online" -EQ "True").count
    $Classifications = $Threatdata | Group-Object -Property Classification | Sort-Object -Property Count -Descending | Select Count, Name -First 10
    $Classifications = $TData | Group-Object -Property Classification | Sort-Object -Property Count -Descending | Select Count, Name -First 10
    $ClearedThreatsByType = $ClearedData | Group-Object -Property Classification | Sort-Object Count -Descending | Select Count, Name -First 10
    $ClearedThreatsByType = $CData | Group-Object -Property Classification | Sort-Object Count -Descending | Select Count, Name -First 10
    $RecentMemoryProtectHits = $MemProtectData.count
    $RecentMemoryProtectHits = $MData.count
    $CylanceComputerCount = $DeviceData.Count
    $CylanceComputerCount = $DData.Count

    #Clean up text
    Foreach ($os in $CylanceOSList) {
        $os.name = $os.name.trim("Microsoft")
        $os.name = $os.name.trim("Â®")
        $os.name = $os.name.replace("Windows","Win")
        $os.name = $os.name.replace("Enterprise","Ent")
        $os.name = $os.name.replace("Server","Srv")
        $os.name = $os.name.replace("Standard","Std")
    }
}

$CylanceComputerPage = New-UDPage -Url "/cylance/computer/:$ComputerName" -Endpoint {
    param($ComputerName)
    New-UDLayout -Columns 3 -Content {
        New-UdTable -Title "$ComputerName Agent Information" -Headers @(" ", " ") -Endpoint {
        @{
            'Operating System' = ($AgentData.os_version)
            'Cylance Policy' = ($AgentData.Policy)
            'Agent Version' = ($AgentData.agent_version)
            'Zone' = ($AgentData.zones)
            'Installed Date' = ($AgentData.created)
            'Files Analyzed' = ($AgentData.files_analyzed)
            'Last Online Date' = ($AgentData.online_date)
            'Last Reported User' = ($AgentData.last_reported_user)
            'IP Address' = ($AgentData.ip_addresses)
            'MAC Addresses' = ($AgentData.mac_addresses)
            }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
        }
    }
}

#Add default policy counter and no-zone counters to table.
$CylancePage = New-UDPage -Name "Cylance" -Icon unlock -Endpoint {
    New-UDLayout -Columns 3 -Content {
        New-UDInput -Title "Enter Computer Name: " -Endpoint {
            param($ComputerName)
            New-UDInputAction -RedirectUrl "/cylance/computer/$ComputerName"
            }
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

$CylancePages = @($CylancePage, $CylanceComputerPage)