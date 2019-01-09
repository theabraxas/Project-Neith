#Install-Module UniversalDashboard
#Install SQL Server Express (Default Instance - MSSQLSERVER) (Mixed mode? Win Auth?)

$HomePage = New-UDPage -Name "Home" -Icon home -Content {
    New-UDLayout -Columns 3 -Content {
        New-UDInput -Title "Unlock User" -Endpoint {
            param($UserName)
            Unlock-ADAccount $UserName
            Sleep -Seconds 1
            $Res = Get-ADUser $Username -Properties LockedOut | Select-Object LockedOut
            If ($Res.LockedOut -eq $false) {
                New-UDInputAction -Toast "$UserName has been unlocked"
            }
            Else {
                New-UDInputAction -Toast "$UserName is still locked"
            }
        }
        New-UDInput -Title "Enter Computer Name: " -Endpoint {
            param($ComputerName)
            New-UDInputAction -RedirectUrl "/computer/main/$ComputerName"
        }
        New-UDInput -Title "Enter User Name: " -Endpoint {
            param($UserName)
            New-UDInputAction -RedirectUrl "/user/$UserName"
        }
        New-UDGrid -Title "AD Computers" -Headers @("Computer Name") -Properties @("Name") -Endpoint {
            get-adcomputer -filter * | select-object Name | Out-UDGridData
        }
        New-UDGrid -Title "AD Users" -Headers @("User Name") -Properties @("Name") -Endpoint {
            Get-ADUser -filter * | Select-Object Name | Out-UDGridData
        }
        New-UDMonitor -Title "Webserver CPU Status" -Type Line -DataPointHistory 50 -RefreshInterval 2 -Endpoint {
            Get-WmiObject win32_processor | select-object -ExpandProperty LoadPercentage | Out-UDMonitorData
        }
    }
    }
$SecurityPage = New-UDPage -Name "Security Dashboard" -Icon _lock -Content {
	#Sample Cylance Pull
    #$CylanceThreats = Invoke-RestMethod -Method GET -URI https://protect.cylance.com/Reports/ThreatDataReportV1/threats/APIKEYGOESHERE | ConvertFrom-CSV
    #Sorted CSV Example by Date:  $CylanceThreats | Sort-Object {[datetime]$_.'Created'} -Descending
    
    New-UDLayout -Columns 3 -Content {
        New-UDCard -Title "Security" -Text "This is a security page"
        }
    }

    $UserInfo = New-UDPage -Url "/user/:UserName" -Endpoint {
    param($UserName)
    $Name = $UserName
    $UserName = (Get-ADUser $UserName -Properties *)
    New-UDRow -Columns {
        New-UDColumn -Size 4 {
            New-UDCard -Title "$Name Information" -Text "$Name Information"
            }
        New-UDColumn -Size 8 {
                New-UDTable -Title "Detailed User Information" -Headers @(" "," ") -Endpoint {
                @{
                "User Name" = ($Username.SamAccountName)
                "Title" = ($UserName.Title)
                "Telephone Number" = ($Username.telephoneNumber)
                "Mobile Number" = ($UserName.MobilePhone)
                "Last Bad Password Attempt" = ($Username.LastBadPasswordAttempt)
                "Home Directory" = ($Username.HomeDirectory)
                "Created On" = ($Username.Created)
                "Country" = ($UserName.Country)
                "City" = ($Username.City)
                "State" = ($Username.State)
                "Expiration Date" = ($Username.AccountExpirationDate)
                "Last Logon Date" = ($Username.LastLogonDate)
                "Primary Group" = ($Username.PrimaryGroup)
                "Group Memberships" = ($Username.MemberOf).Count
                "Locked Out" = ($UserName.LockedOut)
                "Description" = ($Username.Description)
                }.GetEnumerator() |Out-UDTableData -Property @("Name","Value")
            }
        }
    }
}

$UserOverviewPage = New-UDPage -Icon address_book -Name "User Overview" -Content {
    New-UDRow -Columns {
        New-UDColumn -Size 4 {
            New-UDCard -Title "UserOverview" -Text "This is a page to view user information"
            }
        New-UDColumn -Size 4 -Endpoint {
            $ADUsers = Get-ADUser -filter * -properties Enabled, LockedOut, EmailAddress
            $UserCount = $ADUsers.Count
            $EnabledUserCount = ($ADUsers | Where-Object -Property Enabled -eq -Value $True).Count
            $DisabledUserCount = $UserCount - $EnabledUserCount
            $LockedOutUserCount = ($ADUsers | Where-Object -Property LockedOut -eq -Value $True).Count
            $UsersWithEmail = ($ADUsers | Where-Object -Property EmailAddress -NotLike "").Count
            New-UdTable -Title "User Information" -Headers @(" ", " ") -Endpoint {
            @{
                "User Count" = ($UserCount)
                "Enabled Users" = ($EnabledUserCount)
                "Disabled Users" = ($DisabledUserCount)
                "Locked Out Users" = ($LockedOutUserCount)  
                "Users with email" = ($UsersWithEmail)      
                }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
            }
        }
        New-UDColumn -Size 4 -Endpoint {
            New-UDChart -Type Doughnut -Endpoint {
                $ADUsers = Get-ADUser -filter * -properties Enabled, LockedOut, EmailAddress
                $UserCount = $ADUsers.Count
                $EnabledUserCount = ($ADUsers | Where-Object -Property Enabled -eq -Value $True).Count
                $DisabledUserCount = $UserCount - $EnabledUserCount
                $LockedOutUserCount = ($ADUsers | Where-Object -Property LockedOut -eq -Value $True).Count
                $UsersWithEmail = ($ADUsers | Where-Object -Property EmailAddress -NotLike "").Count
                $EnabledDisabledChart = @(
                    @{"type" = "enabled"
                    "Value" = $EnabledUserCount}
                    @{"type" = "Disabled"
                    "Value" = $DisabledUserCount}
                    )
                $EnabledDisabledChart | Out-UDChartData -DataProperty "value" -LabelProperty "Type"
            }
        }        
    }
}

$ComputerPage = New-UDPage -Url "/computer/main/:ComputerName" -Endpoint {
    param($ComputerName)
    $pw = (Get-ADComputer $ComputerName -Properties ms-MCS-AdmPwd | Select -ExpandProperty ms-MCS-AdmPwd) ##Replace 'ms-MCS-AdmPwd' with your LAPS ADSI property name.
    $uptime = Get-CimInstance -ComputerName $ComputerName -ClassName win32_operatingsystem | select-object -ExpandProperty lastbootuptime
    $lastpatch = Get-WmiObject -ComputerName $ComputerName Win32_Quickfixengineering | select @{Name="InstalledOn";Expression={$_.InstalledOn -as [datetime]}} | Sort-Object -Property Installedon | select-object -property installedon -last 1 -ExpandProperty installedon
    $lastboot = Get-WmiObject -ComputerName $ComputerName win32_operatingsystem | select @{Name="LastBootUpTime";Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Select-Object -Property lastbootuptime -ExpandProperty lastbootuptime
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
            'LAPS PW' = ($pw) 
            }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
        } 
        New-UdGrid -Title "Services" -Headers @("Name", "Status") -Properties @("DisplayName", "Status") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Get-Service -ComputerName $ComputerName |select-object DisplayName,Status | Out-UDGridData
        }
        New-UdGrid -Title "Processes" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Process} | Out-UDGridData
        }
    }
}

$ComputerLivePage = New-UDPage -Url "/computer/live/:ComputerName" -Endpoint {
    param($ComputerName)
    New-UDLayout -Columns 3 -Content {
        New-UdTable -Title "Server Information" -Headers @(" ", " ") -Endpoint {
        @{
            'Computer Name' = $ComputerName
            'Operating System' = Get-WmiObject -class Win32_OperatingSystem -computername $ComputerName | select-object -ExpandProperty Caption
            'Total Disk Space (C:)' = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB | ForEach-Object { "$([Math]::Round($_, 2)) GBs " }
            'Free Disk Space (C:)' = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB | ForEach-Object { "$([Math]::Round($_, 2)) GBs " }
        }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
        }
        New-UDMonitor -Title "$ComputerName CPU %" -Type Line -DataPointHistory 100 -RefreshInterval 2 -Endpoint {
            Get-WmiObject -ComputerName $ComputerName win32_processor | select-object -ExpandProperty LoadPercentage | Out-UDMonitorData
        }
        New-UDMonitor -Title "$ComputerName Memory %" -Type Line -DataPointHistory 100 -RefreshInterval 2 -Endpoint {
            Get-WmiObject -ComputerName $ComputerName -Class win32_operatingsystem | Select-Object @{Name = "MemoryUsage"; Expression = { “{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }} | select-object -ExpandProperty "MemoryUsage" | Out-UDMonitorData
        }      
        New-UdGrid -Title "Services" -Headers @("Name", "Status") -Properties @("DisplayName", "Status") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Get-Service -ComputerName $ComputerName |select-object DisplayName,Status | Out-UDGridData
        }
        New-UdGrid -Title "Processes" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Process} | Out-UDGridData
        }
    }
}

$MyDashboard = New-UDDashboard -Pages @($HomePage, $ComputerPage, $ComputerLivePage, $SecurityPage, $UserOverviewPage, $UserInfo) #Make list of pages to dynamically load here

Start-UDDashboard -Port 1000 -Dashboard $MyDashboard
