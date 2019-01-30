#Dynamic page to generate data about a domain joined windows computer. This can be expanded to do enumerations of linux systems by
#either requiring that they are domain joined, using alternative technologies like SNMP or other options. 

$ComputerPage = New-UDPage -Url "/computer/main/:ComputerName" -Endpoint {
    param($ComputerName)
    $uptime = Get-CimInstance -ComputerName $ComputerName -ClassName win32_operatingsystem | select-object -ExpandProperty lastbootuptime
    $lastpatch = Get-WmiObject -ComputerName $ComputerName Win32_Quickfixengineering | select @{Name="InstalledOn";Expression={$_.InstalledOn -as [datetime]}} | Sort-Object -Property Installedon | select-object -property installedon -last 1 -ExpandProperty installedon
    $LAPS_PW = (Get-ADComputer $ComputerName -Properties ms-MCS-AdmPwd | Select -ExpandProperty ms-MCS-AdmPwd) ##Replace 'ms-MCS-AdmPwd' with your LAPS ADSI property name.
    $Disks = Get-WMIObject -Class Win32_LogicalDisk
    New-UDLayout -Columns 3 -Content {
        New-UdTable -Title "Server Information" -Headers @(" ", " ") -Endpoint {
        @{
            'Computer Name' = ($ComputerName)
            'Operating System' = (Get-WmiObject -class Win32_OperatingSystem -computername $ComputerName | select-object -ExpandProperty Caption)
            'Total Disk Space (C:)' = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB | ForEach-Object { "$([Math]::Round($_, 2)) GBs " }
            'Free Disk Space (C:)' = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB | ForEach-Object { "$([Math]::Round($_, 2)) GBs " }
            'Last Boot Time' = ($uptime)
            'View Live Data' = (New-UDLink -Text "Click Here" -Url "/computer/live/$ComputerName")
            'Last Patch Date' = ($lastpatch)
            'lastboot' = ($lastboot)
            'LAPS PW' = ($LAPS_PW) 
            }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
        }
        foreach($disk in $disks) {
            New-UDElement -Tag "row" -Content {
                New-UDProgressMetric -Value ($Disk.FreeSpace /1GB) -Total ($Disk.Size / 1GB) -Metric "GBs" -Label "$($Disk.DeviceID) - Free Space" -HighIsGood}
        }
        New-UdGrid -Title "Services" -Headers @("Name", "Status") -Properties @("DisplayName", "Status") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Get-Service -ComputerName $ComputerName |select-object DisplayName,Status | Out-UDGridData
        }
        New-UdGrid -Title "Processes" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Process} | Out-UDGridData
        }
    }
}

function New-StorageCard {
    

    New-UDCard -Title 'Storage' -Content {
        foreach($disk in $disks) {
            New-UDElement -Tag "row" -Content {
                New-UDProgressMetric -Value ($Disk.FreeSpace /1GB) -Total ($Disk.Size / 1GB) -Metric "GBs" -Label "$($Disk.DeviceID) - Free Space" -HighIsGood
            }
        }
    }
}
