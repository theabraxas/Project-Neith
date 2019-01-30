$Integrations= @{AD=@('integration for active directory domain');Cylance=@('integration for cylance tenant');VMWare=@('Integration for VMware technology.')} #Select integration_names from integrations

Foreach ($i in $Integrations.keys) {
    $IntegrationList = Invoke-Sqlcmd -Query "SELECT * FROM template_configs"
    $Description = $Integrations[$I]
    if ($i -inotin $IntegrationList.template_name) {
        Invoke-Sqlcmd -Query "INSERT INTO template_configs (template_name, description) VALUES ('$I','$Description');"}
    }

$ADCard =  New-UDInput -Title "AD Info" -Content {
                New-UDInputField -type textbox -Name DomainName -Placeholder "Domain Name"
                New-UDInputField -type textbox -Name Username -Placeholder "Username"
                New-UDInputField -type textbox -Name Password -Placeholder "Password"
    } -Endpoint {
            param($DomainName,$Username,$Password)
            $TemplateType = "AD"
            $Varname = "ADPage"
            New-UDInputAction -Content @(
                Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'ultimateDashboard' -Query "update template_configs set active = 'yes', variablename = '$Varname', username = '$Username', password = '$Password', domainname = '$Domainname' where template_name = '$TemplateType'"
                New-UDCard -Title "New Pages Generated" -Text "$DomainName, $Username, $Password"
     )}

$VMwareCard = ""

$CylanceCard =  New-UDInput -Title "Cylance Info" -Content {
                New-UDInputField -type textbox -Name APIkey -Placeholder "API Key"
                New-UDInputField -type textbox -Name Secretkey -Placeholder "Secret Key"
    } -Endpoint {
            param($apikey,$secretkey)
            $TemplateType = "Cylance"
            $Varname = "CylancePage"
            New-UDInputAction -Content @(
                Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'ultimateDashboard' -Query "update template_configs set active = 'yes', variablename = '$Varname', apikey = '$apikey', apisecret = '$secretkey' where template_name = '$TemplateType'"
                New-UDCard -Title "New Pages Generated" -Text "$apikey, $secretkey, CylanceCard"
     )}

$VMwareCard =  New-UDInput -Title "VMWare Info" -Content {
                New-UDInputField -type textbox -Name UserName -Placeholder "Username"
                New-UDInputField -type textbox -Name Password -Placeholder "Password"
                New-UDInputField -type textbox -Name ClusterName -Placeholder "ClusterName"
    } -Endpoint {
            param($UserName,$Password,$ClusterName)
            $TemplateType = "VMware"
            $Varname = "VMwarePage"
            New-UDInputAction -Content @(
                Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'ultimateDashboard' -Query "update template_configs set active = 'yes', username = '$Username', variablename = '$Varname', password = '$Password', clustername = '$Clustername' where template_name = '$TemplateType'"
                New-UDCard -Title "New Pages Generated" -Text "$UserName, $Password, $ClusterName"
     )}


$templateArray = $Integrations.keys
$pageArray = @{AD=$ADCard;Cylance=$CylanceCard;VMware=$VMwareCard}


$TemplatePage = New-UDPage -Name "Configure New Integration" -Content {
    New-UDInput -Title "Template Selector" -Content {
        New-UDInputField -type select -Name TemplateType -Values @($Integrations.keys) -DefaultValue "AD"
    } -Endpoint {
        param($TemplateType) 
        New-UDInputAction -Content @(
            $pageArray.item($TemplateType)
        )
    }
}

