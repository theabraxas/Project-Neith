$VMWareSummaryData= @(Invoke-Sqlcmd -Query "Select TOP 1 * from vmware_summary ORDER BY date DESC")
$VMWareHostData = @(Invoke-Sqlcmd -Query "SELECT * FROM vmware_hosts")
$VMWareVMData = @(Invoke-Sqlcmd -Query "SELECT * FROM vmware_guests")


$VMWareSummaryPage = New-UDPage -Name "VMWare" -Icon desktop -Endpoint {
    New-UDLayout -Columns 3 -Content {
        New-UdTable -Title "VMware Information" -Headers @("name", "value") -Endpoint {
        @{
            'Number of Hosts' = $VMWareSummaryData.num_hosts
            'Number of CPUs' = $VMWareSummaryData.num_cpu
            'Number of VMs' = $VMWareSummaryData.num_vms
            'RAM' =  [math]::Round($VMWareSummaryData.mem_totalgb)
        }.GetEnumerator() | Out-UDTableData -Property @("name","value")
        }
        New-UDInput -Title "Enter Computer Name: " -Endpoint {
            param($ComputerName)
            New-UDInputAction -RedirectUrl "/computer/main/$ComputerName"
        }
        New-UDInput -Title "Enter Host Name"  -Endpoint {
            param($ComputerName)
            New-UDInputAction -RedirectUrl "/computer/main/$ComputerName"
        }
        New-UdChart -Title "Memory Total vs Usage per Host" -Type Bar -AutoRefresh -Endpoint {
            Get-CimInstance -ClassName Win32_LogicalDisk | ForEach-Object {
            [PSCustomObject]@{ DeviceId = $_.DeviceID;
                Size = [Math]::Round($_.Size / 1GB, 2);
                FreeSpace = [Math]::Round($_.FreeSpace / 1GB, 2); } } | Out-UDChartData -LabelProperty "DeviceID" -Dataset @(
            New-UdChartDataset -DataProperty "Size" -Label "Size" -BackgroundColor "#80962F23" -HoverBackgroundColor "#80962F23"
            New-UdChartDataset -DataProperty "FreeSpace" -Label "Free Space" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C"
            )
            }
        New-UdChart -Title "CPU Total vs Usage per Host" -Type Bar -AutoRefresh -Endpoint {
            Get-CimInstance -ClassName Win32_LogicalDisk | ForEach-Object {
            [PSCustomObject]@{ DeviceId = $_.DeviceID;
                Size = [Math]::Round($_.Size / 1GB, 2);
                FreeSpace = [Math]::Round($_.FreeSpace / 1GB, 2); } } | Out-UDChartData -LabelProperty "DeviceID" -Dataset @(
            New-UdChartDataset -DataProperty "Size" -Label "Size" -BackgroundColor "#80962F23" -HoverBackgroundColor "#80962F23"
            New-UdChartDataset -DataProperty "FreeSpace" -Label "Free Space" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C"
            )
            }
        }
    }
$VMwarePage = @($VMWareSummaryPage)