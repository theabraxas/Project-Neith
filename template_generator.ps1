$thing_of_reqs = @{AD=@('acct','pw','domain');Cylance=@('Api_key','Api_secret')}
$pageArray = @{AD=$ADCard;Cylance=$CylanceCard}



$ADCard =  New-UDInput -Title "AD Info" -Content {
                New-UDInputField -type textbox -Name APIkey -Placeholder "API Key"
                New-UDInputField -type textbox -Name Secretkey -Placeholder "Secret Key"
    } -Endpoint {
            param($apikey,$secretkey)
            New-UDInputAction -Content @(
                New-UDCard -Title "New Pages Generated" -Text "$apikey, $secretkey, ADCard"
                )
    }

$CylanceCard =  New-UDInput -Title "Cylance Info" -Content {
                New-UDInputField -type textbox -Name APIkey -Placeholder "API Key"
                New-UDInputField -type textbox -Name Secretkey -Placeholder "Secret Key"
    } -Endpoint {
            param($apikey,$secretkey)
            New-UDInputAction -Content @(
                New-UDCard -Title "New Pages Generated" -Text "$apikey, $secretkey, CylanceCard"
                )
}

$pageArray = @{AD=$ADCard;Cylance=$CylanceCard}


$Dash = New-UDDashboard -Content {
    New-UDInput -Title "Template Selector" -Content {
        New-UDInputField -type select -Name TemplateType -Values @($thing_of_reqs.keys) -DefaultValue "AD"
    } -Endpoint {
        param($TemplateType) 
        New-UDInputAction -Content @(
            $pageArray.item($TemplateType)
        )
    }
}
    
Start-UDDashboard -Dashboard $Dash
