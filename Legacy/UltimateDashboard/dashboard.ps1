#Install-Module UniversalDashboard
#Install SQL Server Express (Default Instance - MSSQLSERVER) (Mixed mode? Win Auth?)

#Each var ending with "Page" represents a page which should have a separate URI associated with it. Dynamic ones specify the URL 
#parameter, static ones (like Home) are given a URL matching the title.
. .\pages.ps1

$HomePage = New-UDPage -Name "Home" -Icon home -Content {
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
	#List of AD Computers
        New-UDGrid -Title "AD Computers" -Headers @("Computer Name") -Properties @("Name") -Endpoint {
            get-adcomputer -filter * | select-object Name | Out-UDGridData
        }
	#List of users by 'Name' ** should switch this to SAMAccountName
        New-UDGrid -Title "AD Users" -Headers @("User Name") -Properties @("Name") -Endpoint {
            Get-ADUser -filter * | Select-Object Name | Out-UDGridData
        }
	#Monitor of CPU status where UniversalDashboard is running.
        New-UDMonitor -Title "Webserver CPU Status" -Type Line -DataPointHistory 50 -RefreshInterval 2 -Endpoint {
            Get-WmiObject win32_processor | select-object -ExpandProperty LoadPercentage | Out-UDMonitorData
        }
    }
}



#SQL Template Requirements

$SQLInstance = "localhost"
$dbname = "ultimateDashboard"
$computername = hostname
$QueryDate = Get-Date

Set-Location SQLSERVER:\SQL\$computername\DEFAULT\databases\$dbname 

Invoke-SqlCmd -Query "DROP TABLE template_configs"

Invoke-Sqlcmd -Query "CREATE TABLE template_configs (
    template_name varchar(24),
    description text,
    active text,
    username varchar(24),
    password text,
    apisecret text,
    apikey text,
    ipaddr text,
    clustername text,
    hostname text,
    domainname text
    );"

Invoke-Sqlcmd -Query "UPDATE template_configs SET username = 'asdf' WHERE template_name = 'AD'"

#Use csv and load to db (opt)
$Integrations= @{AD=@('integration for active directory domain');Cylance=@('integration for cylance tenant');VMWare=@('Integration for VMware technology.')} #Select integration_names from integrations

Foreach ($Integration in $Integrations.keys) {
    $Description = $Integrations[$Integration]
    Invoke-SqlCmd -Query "INSERT INTO template_configs (template_name, description) VALUES('$Integration','$Description');"
    }

$ADCard =  New-UDInput -Title "AD Info" -Content {
                New-UDInputField -type textbox -Name DomainName -Placeholder "Domain Name"
                New-UDInputField -type textbox -Name Username -Placeholder "Username"
                New-UDInputField -type textbox -Name Password -Placeholder "Password"
    } -Endpoint {
            param($DomainName,$Username,$Password)
            $TemplateType = "AD"
            New-UDInputAction -Content @(
                Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'ultimateDashboard' -Query "update template_configs set active = 'yes', username = '$Username', password = '$Password', domainname = '$Domainname' where template_name = '$TemplateType'"
                New-UDCard -Title "New Pages Generated" -Text "$DomainName, $Username, $Password"
     )}

$CylanceCard =  New-UDInput -Title "Cylance Info" -Content {
                New-UDInputField -type textbox -Name APIkey -Placeholder "API Key"
                New-UDInputField -type textbox -Name Secretkey -Placeholder "Secret Key"
    } -Endpoint {
            param($apikey,$secretkey)
            $TemplateType = "Cylance"
            New-UDInputAction -Content @(
                Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'ultimateDashboard' -Query "update template_configs set active = 'yes', apikey = '$apikey', apisecret = '$secretkey' where template_name = '$TemplateType'"
                New-UDCard -Title "New Pages Generated" -Text "$apikey, $secretkey, CylanceCard"
     )}

$VMwareCard =  New-UDInput -Title "VMWare Info" -Content {
                New-UDInputField -type textbox -Name UserName -Placeholder "Username"
                New-UDInputField -type textbox -Name Password -Placeholder "Password"
                New-UDInputField -type textbox -Name ClusterName -Placeholder "ClusterName"
    } -Endpoint {
            param($UserName,$Password,$ClusterName)
            $TemplateType = "VMware"
            New-UDInputAction -Content @(
                Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'ultimateDashboard' -Query "update template_configs set active = 'yes', username = '$Username', password = '$Password', clustername = '$Clustername' where template_name = '$TemplateType'"
                New-UDCard -Title "New Pages Generated" -Text "$UserName, $Password, $ClusterName"
     )}

#Enter New Card for your integration here

$templateArray = $Integrations.keys
$pageArray = @{AD=$ADCard;Cylance=$CylanceCard;VMware=$VMwareCard}
#Add a 'click to restart service' once done

$TemplateLoader = New-UDPage -Name "Configure" -Content {
    New-UDInput -Title "Template Selector" -Content {
        New-UDInputField -type select -Name TemplateType -Values @($Integrations.keys) -DefaultValue "AD"
    } -Endpoint {
        param($TemplateType) 
        New-UDInputAction -Content @(
            $pageArray.item($TemplateType)
        )
    }
}




$MyDashboard = New-UDDashboard -Pages @($HomePage, $ComputerPage, $ComputerLivePage, $SecurityPage, $UserOverviewPage, $UserInfo, $TemplateLoader) #Make list of pages to dynamically load here

Start-UDDashboard -Port 1000 -Dashboard $MyDashboard


