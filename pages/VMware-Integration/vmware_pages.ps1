$VMWareSummaryData= @(Invoke-Sqlcmd -Query "Select TOP 1 * from vmware_summary ORDER BY date DESC")
$VMWareHostData = @(Invoke-Sqlcmd -Query "SELECT * FROM vmware_hosts")
$VMWareVMData = @(Invoke-Sqlcmd -Query "SELECT * FROM vmware_guests")
$CPU_Percent = ($VMWareSummaryData.cpu_usage / $VMWareSummaryData.cpu_total) * 100
$Mem_Percent = ($VMWareSummaryData.mem_usagegb / $VMWareSummaryData.mem_totalgb) * 100

$VMWareSummaryPage = New-UDPage -Name "VMWare" -Icon desktop -Endpoint {
    New-UDLayout -Columns 3 -Content {
        New-UdTable -Title "VMware Information" -Headers @("name", "value") -Endpoint {
            $NoHyperThread = Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $dbname -Query "SELECT hyper_threading FROM vmware_hosts WHERE hyper_threading = 'False'"
        ([ordered]@{
            'Number of Hosts' = $VMWareSummaryData.num_hosts
            'Number of VMs' = $VMWareSummaryData.num_vms
            'Number of CPUs' = $VMWareSummaryData.num_cpu
            'Memory Total' =  [math]::Round($VMWareSummaryData.mem_totalgb).ToString() + "GB"
            'Memory Usage' = [math]::Round($VMWareSummaryData.mem_usagegb).ToString() + "GB"
            'Memory Percentage' = [Math]::Round($Mem_Percent,2).ToString() + "%"
            'CPU Total' = ([math]::Round(($VMWareSummaryData.cpu_total / 1024),2)).ToString() + "Ghz"
            'CPU Usage' = ([math]::Round(($VMWareSummaryData.cpu_usage / 1024),2)).ToString() + "Ghz"
            'CPU Percentage' = [Math]::Round($CPU_Percent,2).ToString() + "%"
            'Hosts without Hyperthreading' = $NoHyperThread.ItemArray.Count.ToString()
            }).GetEnumerator() | Out-UDTableData -Property @("name","value")
        }
        New-UDInput -Title "Enter VM Name: " -Content {
            $VMs = @(Invoke-Sqlcmd  -ServerInstance $SQLInstance -Database $dbname -Query "SELECT host_name FROM vmware_guests")
            New-UDInputField -type select -Values @($VMs.host_name) -Name "VMName"
        } -Endpoint {
            param($VMName)
            New-UDInputAction -RedirectUrl "/vm/$VMName"
        }
        New-UDInput -Title "Enter Host Name: "  -Content {
            $VMhosts = @(Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $dbname -Query "SELECT host_name FROM vmware_hosts")
            New-UDInputField -Type select -Values @($VMhosts.host_name) -Name "VMHost"
            } -Endpoint {
            param($VMhost)
            New-UDInputAction -RedirectUrl "/vmhost/$VMhost"
        }
    }
    New-UDLayout -Columns 2 -Content {
        New-UdChart -Title "CPU Total vs Usage per Host" -Type Bar -Endpoint {
             $VMWareHostData | ForEach-Object {
            [PSCustomObject]@{ Name = $_.host_name;
                "CPU Total" = $_.cpu_total;
                "CPU Usage" = $_.cpu_usage; } } | Out-UDChartData -LabelProperty "Name" -Dataset @(
            New-UdChartDataset -DataProperty "CPU Total" -Label "CPU Total" -BackgroundColor "#80962F23" -HoverBackgroundColor "#80962F23"
            New-UdChartDataset -DataProperty "CPU Usage" -Label "CPU Used" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C"
            )
        }
        New-UdChart -Title "Memory Total vs Usage per Host" -Type Bar -Endpoint {
            $VMWareHostData | ForEach-Object {
            [PSCustomObject]@{ Name = $_.host_name;
                "Memory Total" = $_.mem_totalgb;
                "Memory Usage" = $_.mem_usagegb; } } | Out-UDChartData -LabelProperty "Name" -Dataset @(
            New-UdChartDataset -DataProperty "Memory Total" -Label "Memory Total" -BackgroundColor "#80962F23" -HoverBackgroundColor "#80962F23"
            New-UdChartDataset -DataProperty "Memory Usage" -Label "Memory Usage" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C"
            )
        }
    }
}

$VMpage = New-UDPage -Url "/vm/:VMName" -Endpoint {
    #Dynamic page which provides an overview of the VM.
    param($VMname)
    $VMs = Invoke-SqlCmd -ServerInstance $SQLInstance -Database $DBname -Query "SELECT host_name FROM vmware_guests" 
    New-UDRow -Columns {
        New-UDColumn -Size 4 {
                New-UDCard -Title "$VMname Information (Not Live, from DB)" -Endpoint {
                    $Query = "SELECT * FROM vmware_guests WHERE host_name = '$VMname'"
                    $VMdata = Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $DBname -Query $Query
                    New-UDTable -Headers @(" "," ") -Endpoint {
                        ([ordered]@{
                        power = $VMdata.power.ToString()
                        guest_os = $VMdata.guest.split(":")[1]
                        tools_version = $VMdata.tools_version
                        folder = $VMdata.folder.ToString()
                        num_cpu = $VMdata.num_cpu.ToString()
                        mem_totalgb = $VMdata.mem_totalgb.ToString()
                        provisioned_space = $VMdata.provisioned_space.ToString()
                        space_used = (([math]::Round(([int]$vmdata.used_space / [int]$vmdata.provisioned_space),2))*100).ToString() +"%"
                    }).GetEnumerator() | Out-UDTableData -Property @("Name","Value")
                }
            }
        }
    }
}

$VMHostpage = New-UDPage -Url "/vmhost/:VMhost" -Endpoint {
    #Dynamic page which provides an overview of the host.
    param($VMhost)
    $Hosts = Invoke-SqlCmd -ServerInstance $SQLInstance -Database $DBname -Query "SELECT host_name FROM vmware_hosts" 
    New-UDRow -Columns {
        New-UDColumn -Size 4 {
                New-UDCard -Title "$VMhost Information (Not Live, from DB)" -Endpoint {
                    $Query = "SELECT * FROM vmware_hosts WHERE host_name LIKE '%$VMhost%'"
                    $Hostdata = Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $DBname -Query $Query
                    New-UDTable -Headers @(" "," ") -Endpoint {
                        ([ordered]@{
                        power = $Hostdata.power.ToString()
                        connected = $Hostdata.connected.ToString()
                        cluster = $Hostdata.parent.ToString()
                        network = $Hostdata.net_info.Tostring()
                        Manufacturer = $Hostdata.manufacturer.ToString()
                        Model = $Hostdata.model.tostring()
                        Hyperthreading_enabled = "ESX: " + $Hostdata.hyper_threading.ToString() + " - Build " + $Hostdata.build.ToString()
                        ESX_Version = $Hostdata.version.ToString()
                        proc_type = $Hostdata.proc_type.ToString()
                        num_cpu = $Hostdata.num_cpu.ToString()
                        total_ghz = ([math]::Round(($Hostdata.cpu_total / 1024),2)).ToString() + "Ghz"
                        percent_cpu_used = ([math]::Round(($Hostdata.cpu_usage / $Hostdata.cpu_total),2) * 100).ToString() + "%"
                        total_mem = [math]::Round($Hostdata.mem_totalgb,2).ToString() + "GB"
                        percent_mem_used = ([math]::Round(($Hostdata.mem_usagegb / $Hostdata.mem_totalgb),2) *100).ToString() + "%"
                    }).GetEnumerator() | Out-UDTableData -Property @("Name","Value")
                }
            }
        }
    }
}

$VMwarePage = @($VMWareSummaryPage,$VMpage,$VMHostpage)