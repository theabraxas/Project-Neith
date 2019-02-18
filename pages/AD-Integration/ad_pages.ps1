$ADUsers = Invoke-Sqlcmd -Query "select * from ad_users"
$UserCount = $ADUsers.Count
$EnabledUserCount = ($ADUsers | Where-Object -Property Enabled -eq -Value $True).Count
$DisabledUserCount = $UserCount - $EnabledUserCount
$LockedOutUsers = @($ADUsers | Where-Object -Property LockedOut -eq -Value $True)
$LockedOutUserCount = $LockedOutUsers.Count
$UsersWithEmail = ($ADUsers | Where-Object -Property Email_Address -NotLike "").Count
$ADData = @(Invoke-Sqlcmd -Query "Select TOP 1 * from ad_summary ORDER BY date DESC")
$Data = Invoke-Sqlcmd -Query "SELECT * FROM ad_summary"
$Ticks_90days = 864000000000 * 90
$ft_1day = ((Get-Date).AddDays(-1))

$Features = @();
Foreach ($D in $Data) {
    $Features += [PSCustomObject]@{ "Date" = $D.date; "Users" = $D.total_users ; "EnabledUsers" = $D.total_users_enabled ; "Computers" = $D.total_computers ; "EnabledComputers" = $D.total_enabled_computers }
    }

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
                "Bad Logon Count" = ($Username.badlogoncount)
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
            'View Live Data' = New-UDButton -Text "More Info" -OnClick {
                Invoke-UDRedirect -Url "/computer/live/$ComputerName"}
            'Last Patch Date' = ($lastpatch)
            'lastboot' = ($lastboot)
            'LAPS PW' = ($pw) 
            }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
        } 

        New-UDInput -Title "Run Remote Command" -Content {
            New-UDInputField -type textbox -Name Command 
            } -Endpoint {
                param($Command) 
                #Add server-side validation of role/identity to do this. Does UD allow a post to some call which would let this run regardless of auth?
                #if allowed do it, else whatever. log both.
                $scriptblock = [scriptblock]::Create($Command)
                $cmd_result = Invoke-Command -ComputerName $Computername -ScriptBlock $scriptblock 
                New-UDInputAction -Content @(
                    New-UDCard -Title "Command Result" -Text "Command Completed Successfully`n$cmd_result"
                )
            }

        New-UdGrid -Title "Services" -Headers @("DisplayName", "Status","Toggle") -Properties @("DisplayName", "Status","Toggle") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            $Services = Get-Service -ComputerName $ComputerName 
            $Services | Foreach-Object {
                [PSCustomObject]@{
                    DisplayName = $_.DisplayName.ToString().Trim()
                    Status = $_.Status.ToString()
                    Toggle = If ($_.Status.ToString() -eq "Stopped"){
                        New-UDButton -Text "Start Service" -OnClick {
                            Get-Service -ComputerName $ComputerName -DisplayName $_.Displayname | Start-Service
                            Show-UDToast -Message "Tried to start service, it should refresh within a minute"
                            }
                        }
                        Else {
                        New-UDButton -Text "Stop Service" -OnClick {
                            Get-Service -ComputerName $ComputerName -DisplayName $_.DisplayName | Stop-Service
                            Show-UDToast -Message "Tried to stop service, it should refresh within a minute"
                            }
                        }
                }
            } | Out-UDGridData
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
        New-UDMonitor -Title "$ComputerName CPU %" -Type Line -DataPointHistory 70 -RefreshInterval 2 -Endpoint {
            Get-WmiObject -ComputerName $ComputerName win32_processor | select-object -ExpandProperty LoadPercentage | Out-UDMonitorData
        }
        New-UDMonitor -Title "$ComputerName Free Memory %" -Type Line -DataPointHistory 70 -RefreshInterval 2 -Endpoint {
            $OSInfo = Get-WmiObject -ComputerName $ComputerName -Class win32_OperatingSystem
            (($OSInfo.FreePhysicalMemory / $OSInfo.TotalVisibleMemorySize) * 100) | Out-UDMonitorData
        }
        New-UDMonitor -Title "$ComputerName IO Usage" -Type Line -DataPointHistory 70 -RefreshInterval 2 -Endpoint {
            $TotalSystemIO = Invoke-command -computername $ComputerName -ScriptBlock {Get-Counter '\Process(_TOTAL)\IO Data Operations/sec' | Select-Object -ExpandProperty countersamples | Select-Object -expandproperty cookedvalue }
            If (!$TotalSystemIO) {
                $TotalSystemIO = 0 }
            If ($TotalSystemIO -isnot [double]) {
                $TotalSystemIO = 0 }
            [math]::Round($TotalSystemIO)| Out-UDMonitorData
        }
        New-UDMonitor -Title "$ComputerName Network Usage (mbps)" -Type Line -DataPointHistory 70 -RefreshInterval 2 -Endpoint {
            $netIO = Get-wmiobject -ComputerName $ComputerName -Query "Select BytesTotalPersec from Win32_PerfFormattedData_Tcpip_NetworkInterface" | Select -ExpandProperty BytesTotalPersec    
            $totalNetIO = 0
            $NetIO | foreach {$totalNetIO += $_ }
            $totalNetIO = $totalNetIO / (1024 * 1024)
            $totalNetIO | Out-UDMonitorData
            }
        New-UdGrid -Title "Services" -Headers @("Name", "Status") -Properties @("DisplayName", "Status") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Get-Service -ComputerName $ComputerName |select-object DisplayName,Status | Out-UDGridData
        }
        New-UdGrid -Title "Processes" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint { 
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Process} | Out-UDGridData
        }
    }
}

$ADSummary = New-UDLayout -Columns 1 -Content {
    New-UDLayout -Columns 4 -Content {
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
        New-UDInput -Title "Enter any AD Object: " -Endpoint {
            param($adObject)
            New-UDInputAction -RedirectUrl "/ad/$adObject"
        }
    }
    New-UDColumn -Size 12 {
        New-UDTable -Title "AD Data" -Headers @("total_users", "total_users_enabled", "total_computers", "total_enabled_computers", "total_groups", "forest_functional_level") -Endpoint {
            $ADData.GetEnumerator() | Out-UDTableData -Property @("total_users", "total_users_enabled", "total_computers", "total_enabled_computers", "total_groups", "forest_functional_level")
        }
        New-UDChart -Title "AD Features Over Time" -Height 600px -Width 100% -Type Line -Endpoint {
            $Features | Out-UDChartData -LabelProperty Date -Dataset @(
                New-UDChartDataset -DataProperty "Users" -Label "Users" -BackgroundColor "#80962F23" -HoverBackgroundColor "#80962F23"
                New-UDChartDataset -DataProperty "EnabledUsers" -Label "EnabledUsers" -BackgroundColor "#800FF22F" -HoverBackgroundColor "#800FF22F"
                New-UDChartDataset -DataProperty "Computers" -Label "Computers" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C"
                New-UDChartDataset -DataProperty "EnabledComputers" -Label "EnabledComputers" -BackgroundColor "#803AE8CE" -HoverBackgroundColor "#803AE8CE"
            )
        }
    }
}

$UserOverview = New-UDRow -Columns {
        New-UDColumn -Size 4 {
            New-UDCard -Title "UserOverview" -Text "This is a page to view user information"
            }
        New-UDColumn -Size 4 -Endpoint {
            New-UdTable -Title "User Information" -Headers @(" ", " ") -Endpoint {
                $EnabledUsers = ($ADUsers | Where-Object -Property Enabled -eq -Value $True)
                $UsersPWgt90Days = 0
                Foreach ($User in $EnabledUsers) {
                    $pwdlastset = $User.password_last_set
                    $threshold = ((Get-Date).Ticks - $Ticks_90days)
                    If ($pwdlastset -lt $threshold) {$UsersPWgt90Days+=1 }
                }
            @{
                "User Count" = ($UserCount)
                "Enabled Users" = ($EnabledUserCount)
                "Disabled Users" = ($DisabledUserCount)
                "Locked Out Users" = ($LockedOutUserCount)  
                "Users with email" = ($UsersWithEmail)   
                "Users with pws older than 90 days" = ($UsersPwGt90Days)   
                }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
            }
        }
        New-UDColumn -Size 4 -Endpoint {
            New-UDChart -Title "Enabled vs Disabled Users" -Type Doughnut -Endpoint {
                $EnabledDisabledChart = @(
                    @{"type" = "enabled"
                    "Value" = $EnabledUserCount}
                    @{"type" = "Disabled"
                    "Value" = $DisabledUserCount}
                    )
                $EnabledDisabledChart | Out-UDChartData -DataProperty "value" -LabelProperty "Type" -BackgroundColor @("green","red")
            }
        }
        New-UDColumn -Size 4 -Endpoint {
            New-UDTable -Title "All User Security Information" -Headers @(" "," ") -Endpoint {
            $UserDESKeyOnly = $ADUsers | Where-Object -Property USEDESKeyOnly -NotLike "False"
            $UserTrustDelegation = $ADUsers | Where-Object -Property trustedfordelegation -NotLike "False"
            $UserPasswordExpired = $ADUsers | Where-Object -Property passwordexpired -NotLike "False"
            $UserPasswordNotRequired = $ADUsers | Where-Object -Property paswordnotrequired -Notlike "False"
            $UserPasswordNeverExpire = $ADUsers | Where-Object -Property PasswordNeverExpires -Notlike "False"
            $UserPasswordReversible = $ADUsers | Where-Object -Property AllowReversiblePasswordEncryption -Notlike "False"
            $UsersWithBadLogonsNow = $ADUsers | Where-Object -Property BadPasswordCount -GT 0
            $UsersWithRecentBadPasswords = $ADUsers | Where-Object -Property BadPasswordTime -GT $ft_1day.ToFileTime() #checks for bad password over the last day
            $UsersCannotChangePassword = $ADUsers | Where-Object -Property CannotChangePassword -NotLike "False"
                @{
                    "Users with 3DES Key Only" = ($UserDESKeyOnly.Count)
                    "Users Trusted for Delegation" = ($UserTrustDelegation.Count)
                    "Users with expired passwords" = ($UserPasswordExpired.Count)
                    "Users with no password required" = ($UserPasswordNotRequired.Count)
                    "Users with Password Never Expires" = ($UserPasswordNeverExpire.Count)
                    "Users with Reversible Passwords" = ($UserPasswordReversible.Count)
                    "Users with current failed password attempts" = ($UsersWithBadLogonsNow.Count)
                    "Users with recent bad passwords (1 day)" = ($UsersWithRecentBadPasswords.Count)
                    "Users who cannot change password" = ($UsersCannotChangePassword.Count)

            }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
        }
    }
        New-UDColumn -Size 4 -Endpoint {
            New-UDTable -Title "Enabled User Security Information" -Headers @(" "," ") -Endpoint {
            $UserDESKeyOnly = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property USEDESKeyOnly -NotLike "False"
            $UserTrustDelegation = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property trustedfordelegation -NotLike "False"
            $UserPasswordExpired = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property passwordexpired -NotLike "False"
            $UserPasswordNotRequired = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property paswordnotrequired -Notlike "False"
            $UserPasswordNeverExpire = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property PasswordNeverExpires -Notlike "False"
            $UserPasswordReversible = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property AllowReversiblePasswordEncryption -Notlike "False"
            $UsersWithBadLogonsNow = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property BadPasswordCount -GT 0
            $UsersWithRecentBadPasswords = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property BadPasswordTime -GT $ft_1day.ToFileTime() #checks for bad password over the last day
            $UsersCannotChangePassword = $ADUsers | Where-Object -Property Enabled -Like "True" | Where-Object -Property CannotChangePassword -NotLike "False"
                @{
                    "Users with 3DES Key Only" = ($UserDESKeyOnly.Count)
                    "Users Trusted for Delegation" = ($UserTrustDelegation.Count)
                    "Users with expired passwords" = ($UserPasswordExpired.Count)
                    "Users with no password required" = ($UserPasswordNotRequired.Count)
                    "Users with Password Never Expires" = ($UserPasswordNeverExpire.Count)
                    "Users with Reversible Passwords" = ($UserPasswordReversible.Count)
                    "Users with current failed password attempts" = ($UsersWithBadLogonsNow.Count)
                    "Users with recent bad passwords (1 day)" = ($UsersWithRecentBadPasswords.Count)
                    "Users who cannot change password" = ($UsersCannotChangePassword.Count)
                }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
            }
        }
}

$PageSelector = New-UDElement -Tag div -Attributes @{
    style = @{display = 'flex'; flexdirection = 'row';}
    } -Content {
    New-UDButton -Text "AD Summary" -OnClick {
        Set-UDElement -Id page -Content { $ADSummary }
    }
    New-UDButton -Text "User Overview" -OnClick {
        Set-UDElement -Id page -Content { $UserOverview }
    }
    New-UDButton -Text "AD Health (Coming Soon!)"
    New-UDButton -Text "AD Management (Coming Soon!)"
}

$ADDataPage = New-UDPage -Name "ADSummary" -Icon signal -Content {
    $PageSelector
    New-UDRow
    New-UDElement -tag div -id page -Content {
        $ADSummary
    }
}




$ADPage = @($ADDataPage, $UserInfoPage, $ComputerPage, $ComputerLivePage,$ObjectPage)