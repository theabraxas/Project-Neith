$VMwareData= @(Invoke-Sqlcmd -Query "Select TOP 1 * from ad_summary ORDER BY date DESC")
$VMWareSummaryPage = New-UDPage -Name "VMWare" -Icon desktop -Content {
    New-UDLayout -Columns 3 -Content {
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
}

$VMwarePage = @($VMWareSummaryPage)