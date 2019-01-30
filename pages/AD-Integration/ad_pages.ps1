$UserInfoPage = New-UDPage -Url "/user/:UserName" -Endpoint {
    #Dynamic page which provides an overview of the users attributes.
    param($UserName)
    $UserName = (Get-ADUser $UserName -Properties *)
    New-UDRow -Columns {
        New-UDColumn -Size 4 {
            New-UDCard -Title "$UserName.Name Information" -Text "$UserName.SAMAccountName Information"
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

$ADUsers = Invoke-Sqlcmd -Query "select * from ad_users"
$UserCount = $ADUsers.Count
$EnabledUserCount = ($ADUsers | Where-Object -Property Enabled -eq -Value $True).Count
$DisabledUserCount = $UserCount - $EnabledUserCount
$LockedOutUsers = @($ADUsers | Where-Object -Property LockedOut -eq -Value $True)
$LockedOutUserCount = $LockedOutUsers.Count
$UsersWithEmail = ($ADUsers | Where-Object -Property EmailAddress -NotLike "").Count

$UserOverviewPage = New-UDPage -Icon address_book -Name "User Overview" -Content {
    New-UDRow -Columns {
        New-UDColumn -Size 4 {
            New-UDCard -Title "UserOverview" -Text "This is a page to view user information"
            }
        New-UDColumn -Size 4 -Endpoint {

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
	#It would be really great to add some default color scheme to this chart...
            New-UDChart -Type Doughnut -Endpoint {
                $EnabledDisabledChart = @(
                    @{"type" = "enabled"
                    "Value" = $EnabledUserCount}
                    @{"type" = "Disabled"
                    "Value" = $DisabledUserCount}
                    )
                $EnabledDisabledChart | Out-UDChartData -DataProperty "value" -LabelProperty "Type" -BackgroundColor @("green","red")
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
            Get-WmiObject -ComputerName $ComputerName -Class win32_operatingsystem | Select-Object @{Name = "MemoryUsage"; Expression = { â€œ{0:N2}â€ -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }} | select-object -ExpandProperty "MemoryUsage" | Out-UDMonitorData
        }      
        New-UdGrid -Title "Services" -Headers @("Name", "Status") -Properties @("DisplayName", "Status") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Get-Service -ComputerName $ComputerName |select-object DisplayName,Status | Out-UDGridData
        }
        New-UdGrid -Title "Processes" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Process} | Out-UDGridData
        }
    }
}

$ADData = @(Invoke-Sqlcmd -Query "Select TOP 1 * from ad_summary ORDER BY date DESC")
$ADSummaryPage = New-UDPage -Name "ADSummary" -Icon address_book -Content {
    New-UDLayout -Columns 3 -Content {
    	#AD User Unlock
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
	#Enter Computer Name to view a dynamic page with core computer information
        New-UDInput -Title "Enter Computer Name: " -Endpoint {
            param($ComputerName)
            New-UDInputAction -RedirectUrl "/computer/main/$ComputerName"
        }
	#Enter a user name to view a dynamic page with core user information
        New-UDInput -Title "Enter User Name: " -Endpoint {
            param($UserName)
            New-UDInputAction -RedirectUrl "/user/$UserName"
        }
    }
    New-UDLayout -Columns 1 -Content {
         New-UDTable -Title "AD Data" -Headers @("total_users", "total_users_enabled", "total_computers", "total_enabled_computers", "total_groups", "forest_functional_level") -Endpoint {
            $ADData.GetEnumerator() | Out-UDTableData -Property @("total_users", "total_users_enabled", "total_computers", "total_enabled_computers", "total_groups", "forest_functional_level")
        }
    }
}

$ADPage = @($ADSummaryPage, $UserInfoPage, $UserOverviewPage, $ComputerPage, $ComputerLivePage)