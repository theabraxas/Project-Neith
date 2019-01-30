$VMwareData= @(Invoke-Sqlcmd -Query "Select TOP 1 * from ad_summary ORDER BY date DESC")
$VMWareSummaryPage = New-UDPage -Name "ADSummary" -Icon address_book -Content {
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

$VMwarePage = @($VMWareSummaryPage)