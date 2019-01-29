$HomePage = New-UDPage -Name "Home" -Icon home -Content {
    New-UDLayout -Columns 3 -Content {
	    #DB Stats
        $RecordsPerTable = @(Invoke-Sqlcmd -Query "select t.name TableName, i.rows Records
            from sysobjects t, sysindexes i
            where t.xtype = 'U' and i.id = t.id and i.indid in (0,1)
            order by TableName;")
        
        New-UDTable -Title "Table Statistics" -Headers @("TableName", "Records") -Endpoint {
            $RecordsPerTable.GetEnumerator() | Out-UDTableData -Property @("TableName", "Records")
    }
    #Monitor of CPU status where UniversalDashboard is running.
        New-UDMonitor -Title "Webserver CPU Usage" -Type Line -DataPointHistory 50 -RefreshInterval 5 -Endpoint {
            Get-WmiObject win32_processor | select-object -ExpandProperty LoadPercentage | Out-UDMonitorData
        }
    #Monitor of CPU status where UniversalDashboard is running.
        New-UDChart -Title "Webserver Memory Usage" -Type Bar -RefreshInterval 5 -Endpoint {
            $TotalMem = Get-WmiObject CCM_LogicalMemoryConfiguration | select @{Name="GB";Expression={$_.TotalPhysicalMemory/1mb}}
            $TotalMem = $TotalMem | Select -ExpandProperty GB
            $AvailMem = Get-WmiObject CCM_LogicalMemoryConfiguration | select @{Name="GB";Expression={$_.AvailableVirtualMemory/1mb}}
            $AvailMem = $AvailMem | Select -ExpandProperty GB
            $UsedMem = $TotalMem - $AvailMem
            [PSCustomObject]@{ 
                        Name = "System Memory"
                        TotalMemory = $TotalMem;
                        UsedMemory = $UsedMem} | Out-UDChartData -LabelProperty "Name" -Dataset @(
                            New-UdChartDataset -DataProperty "TotalMemory" -Label "TotalMemory" -BackgroundColor "#80962F23" -HoverBackgroundColor "#80962F23"
                            New-UdChartDataset -DataProperty "UsedMemory" -Label "UsedMemory" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C"
                        )
                   }
    }
}