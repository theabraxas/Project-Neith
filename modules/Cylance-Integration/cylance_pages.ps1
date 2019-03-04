$CylanceActive = Invoke-SqlCmd -Query "SELECT active FROM template_configs WHERE template_name = 'Cylance'" -ServerInstance $cache:sql_instance -Database $cache:db_name
$Threattypes = @()

Foreach ($Threat in $DetectionData) {
    $Threattypes += $Threat.classification}
$Threats_by_type = $Threattypes | Group-Object |Select Name,Count



If ($CylanceActive.active -eq "yes") {
    $Ddata = Invoke-Sqlcmd -Query "Select * from cylance_device_data" -ServerInstance $cache:sql_instance -Database $cache:db_name
    $Tdata = Invoke-Sqlcmd -Query "Select * from cylance_threat_data" -ServerInstance $cache:sql_instance -Database $cache:db_name
    $Edata = Invoke-Sqlcmd -Query "Select * from cylance_event_data" -ServerInstance $cache:sql_instance -Database $cache:db_name
    $Cdata = Invoke-Sqlcmd -Query "Select * from cylance_cleared_data" -ServerInstance $cache:sql_instance -Database $cache:db_name
    $MData = Invoke-Sqlcmd -Query "Select * from cylance_memprotect_data" -ServerInstance $cache:sql_instance -Database $cache:db_name

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

$CylanceComputerPage = New-UDPage -Url "/dynamic/cylance/computer/:CompName" -Endpoint {
    param($CompName)
    $query = "SELECT * FROM cylance_device_data WHERE device_name = '$CompName'"
    $AgentData = Invoke-Sqlcmd -Query $Query -ServerInstance $cache:sql_instance -Database $cache:db_name
    $query = "SELECT * FROM cylance_event_data WHERE device_name = '$CompName'"
    $EventsData = Invoke-Sqlcmd -Query $Query -ServerInstance $cache:sql_instance -Database $cache:db_name
    $query = "SELECT * FROM cylance_cleared_data WHERE device_name = '$CompName'"
    $ClearedData = Invoke-Sqlcmd -Query $Query -ServerInstance $cache:sql_instance -Database $cache:db_name
    $query = "SELECT * FROM cylance_threat_data WHERE device_name = '$CompName'"
    $ThreatData = Invoke-Sqlcmd -Query $Query -ServerInstance $cache:sql_instance -Database $cache:db_name
    New-UDRow -Columns {
        New-UDColumn -Size 4 {
            New-UdTable -Title "$CompName Agent Information" -Headers @(" ", " ") -Endpoint {
        ([ordered]@{
            'Operating System' = ($AgentData.os_version)
            'Cylance Policy' = ($AgentData.Policy)
            'Agent Version' = ($AgentData.agent_version)
            'Zone' = ($AgentData.zones)
            'Installed Date' = ($AgentData.created)
            'Files Analyzed' = ($AgentData.files_analyzed)
            'Last Online Date' = ($AgentData.online_date)
            'Last Reported User' = ($AgentData.last_reported_user)
            'IP Address' = ($AgentData.ip_addresses.Replace(',',', '))
            'MAC Addresses' = ($AgentData.mac_addresses)
            'Return to Cylance Page' = (New-UDButton -Text "Return" -OnClick {
                Invoke-UDRedirect -Url "/Cylance"}
                )
            }).GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
            }
        }
        New-UDColumn -Size 4 {
            $TopThreats = $ThreatData | Group-Object -Property Classification | Sort-Object -Property Count -Descending | Select Count, Name -First 10
            New-UDChart -Title "Classification of Threats" -Type Doughnut -Endpoint {
                $TopThreats| Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor @("#75cac3","#2a6171","#f3d516","#4b989e","#86df4a","#b816f3","#f31651","#4e4b9e","#1F1F1F","#777777","#FFFFFF") -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
            }
        }
        New-UDColumn -Size 4 {
            $DetectionsByType = $ClearedData | Group-Object -Property detected_by | Sort-Object -Property Count -Descending | Select Count, Name -First 10
            New-UDChart -Title "Findings by Detection Method" -Type Doughnut -Endpoint {
                $DetectionsByType| Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor @("#75cac3","#2a6171","#f3d516","#4b989e","#86df4a","#b816f3","#f31651","#4e4b9e","#1F1F1F","#777777","#FFFFFF") -BorderColor 'black' -HoverBackgroundColor '#FF9F0D'
            }
        }
        New-UDRow        
        New-UDColumn -Size 12 {
            New-UDGrid -Title "$compname Recent Event Data" -Headers @('date','file_path','event_status','cylance_score','classification','detected_by','running','ever_run') `
        -Properties @('date','file_path','event_status','cylance_score','classification','detected_by','running','ever_run') -Endpoint {
            $EventsData | ForEach-Object {
                [PSCustomObject]@{
                    date = $_.date
                    file_path = $_.file_path.Replace('\',' \')
                    event_status = $_.event_status.ToString()
                    cylance_score = $_.cylance_score.ToString()
                    classification = $_.classification.ToString()
                    detected_by = $_.detected_by.ToString()
                    running = $_.running.ToString()
                    ever_run = $_.ever_run.ToString()
                }
            } | Out-UDGridData
        }}
        New-UDRow
        New-UDColumn -Size 12 {
            New-UDGrid -Title "$CompName Cleared Data" -Headers @('date_removed','file_path','cylance_score','classification','detected_by','running','ever_run') `
            -Properties @('date_removed','file_path','cylance_score','classification','detected_by','running','ever_run') -Endpoint {
            $ClearedData | Foreach-Object {
                [PSCustomObject]@{
                    date_removed = $_.date_removed.toString()
                    file_path = $_.file_path.Replace('\',' \').toString()
                    cylance_score = $_.cylance_score.toString()
                    classification = $_.classification.toString()
                    detected_by = $_.detected_by.ToString()
                    running = $_.running.toString()
                    ever_run = $_.ever_run.toString()
                    }
                } | Out-UDGridData
            }
        }
        New-UDRow
        New-UDColumn -Size 12 {
            New-UDGrid -Title "$CompName Threat Data" -Headers @('file_name','file_status','cylance_score','signature_status','av_industry','safelisted','classification','ever_run','detected_by') -Properties @('file_name','file_status','cylance_score','signature_status','av_industry','safelisted','classification','ever_run','detected_by') -Endpoint {
            $ThreatData | ForEach-Object {    
                [PSCustomObject]@{
                    file_name = $_.file_name.ToString()
                    file_status = $_.file_status.ToString()
                    cylance_score = $_.cylance_score.ToString()
                    signature_status = $_.signature_status.ToString()
                    av_industry = $_.av_industry.ToString()
                    safelisted = $_.safelisted.ToString()
                    classification = $_.classification.ToString()
                    ever_run = $_.ever_run.ToString()
                    detected_by = $_.detected_by.ToString()
                }
            } | Out-UDGridData
            }
        }
    }
}

#Add default policy counter and no-zone counters to table.
$CylancePage = New-UDPage -Name "Cylance" -Icon unlock -Endpoint {
    $CylanceComputers = (Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "SELECT device_name FROM cylance_device_data ORDER BY device_name")
    New-UDLayout -Columns 3 -Content {
        New-UDInput -Title "Enter Computer Name: " -Content {
            New-UDInputField -Type select -Values @($CylanceComputers.device_name) -Name "CompName" -DefaultValue $CylanceComputers.device_name[0]
        } -Endpoint {
            param($Compname)
            New-UDInputAction -RedirectUrl "/dynamic/cylance/computer/$CompName"
        }
        New-UDCounter -Title "Cylance Computers" -Endpoint {
            $CylanceComputerCount
            }
        New-UDCounter -Title "Cylance Memory Protection Events (Past 7 Days)" -Endpoint {
            $RecentMemoryProtectHits
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
    }
}

$CylancePages = @($CylancePage, $CylanceComputerPage)