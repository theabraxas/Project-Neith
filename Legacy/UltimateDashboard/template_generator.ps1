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

$Integrations= @{AD=@('integration for active directory domain');Cylance=@('integration for cylance tenant');VMWare=@('Integration for VMware technology.')}

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


$templateArray = $Integrations.keys
$pageArray = @{AD=$ADCard;Cylance=$CylanceCard;VMware=$VMwareCard}


$TemplateLoader = New-UDDashboard -Content {
    New-UDInput -Title "Template Selector" -Content {
        New-UDInputField -type select -Name TemplateType -Values @($Integrations.keys) -DefaultValue "AD"
    } -Endpoint {
        param($TemplateType) 
        New-UDInputAction -Content @(
            $pageArray.item($TemplateType)
        )
    }
}

Start-UDDashboard -Dashboard $TemplateLoader
