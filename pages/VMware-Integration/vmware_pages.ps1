$VMWareSummaryData= @(Invoke-Sqlcmd -Query "Select TOP 1 * from vmware_summary ORDER BY date DESC")
$VMWareHostData = @(Invoke-Sqlcmd -Query "SELECT * FROM vmware_hosts")
$VMWareVMData = @(Invoke-Sqlcmd -Query "SELECT * FROM vmware_guests")
$CPU_Percent = ($VMWareSummaryData.cpu_usage / $VMWareSummaryData.cpu_total) * 100
$Mem_Percent = ($VMWareSummaryData.mem_usagegb / $VMWareSummaryData.mem_totalgb) * 100


$VMWareSummaryPage = New-UDPage -Name "VMWare" -Icon desktop -Endpoint {
    New-UDLayout -Columns 3 -Content {
        New-UdTable -Title "VMware Information" -Headers @("name", "value") -Endpoint {
        ([ordered]@{
            'Number of Hosts' = $VMWareSummaryData.num_hosts
            'Number of VMs' = $VMWareSummaryData.num_vms
            'Number of CPUs' = $VMWareSummaryData.num_cpu
            'Memory Total' =  [math]::Round($VMWareSummaryData.mem_totalgb)
            'Memory Usage' = [math]::Round($VMWareSummaryData.mem_usagegb)
            'Memory Percentage' = [Math]::Round($Mem_Percent,2)
            'CPU Total' = $VMWareSummaryData.cpu_total
            'CPU Usage' = $VMWareSummaryData.cpu_usage
            'CPU Percentage' = [Math]::Round($CPU_Percent,2)
            }).GetEnumerator() | Out-UDTableData -Property @("name","value")
        }
        New-UDInput -Title "Enter Computer Name: " -Endpoint {
            param($ComputerName)
            New-UDInputAction -RedirectUrl "/computer/main/$ComputerName"
        }
        New-UDInput -Title "Enter Host Name"  -Endpoint {
            param($ComputerName)
            New-UDInputAction -RedirectUrl "/computer/main/$ComputerName"
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

$VMwarePage = @($VMWareSummaryPage)