#AD Summary Collector Script
$UserData = Get-ADUser -Filter * -Properties *
$ComputerData = Get-ADComputer -Filter * -Properties *
$GroupData = Get-ADGroup -Filter * -Properties * 
$ForestData = Get-ADForest
$DomainData = Get-ADDomain
$QueryDate = Get-Date
$TotalUsers = $UserData.Count
$EnabledUsers = ($UserData | Where-Object -Property "enabled" -eq "True").Count
$TotalComputers = $ComputerData.Count
$EnabledComputers = ($ComputerData | Where-Object -Property "enabled" -eq "True").Count
$TotalGroups = $GroupData.Count
$ForestFunctionalLevel = $ForestData.ForestMode
$DomainMode = $DomainData.DomainMode
$DomainName = $DomainData.forest
$Success = 1
$UsersNoPwdExpire = ($userdata | where-object -Property "PasswordNeverExpires" -eq "True").count
$OSData = $ComputerData | Where-Object -Property "Enabled" -eq "True" | Group-Object OperatingSystem -NoElement

Set-Location SQLSERVER:\SQL\$computername\DEFAULT\databases\$dbname 

#Load Data to SQL Table
Invoke-Sqlcmd -Query "INSERT INTO ad_summary (date, success, total_users ,total_users_enabled ,total_groups ,total_computers ,total_enabled_computers, forest_functional_level, os_info) 
VALUES('$QueryDate','$Success','$TotalUsers','$EnabledUsers','$TotalGroups','$TotalComputers','$EnabledComputers','$ForestFunctionalLevel','$OSData')"
$os_columns= Invoke-Sqlcmd -Query "Select * from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ad_summary'"
Foreach ($OS in $OSData) { 
    $osname = $os.name
    $oscount = $os.count
    If ($oscount -eq "") {
        $oscount = 0
    }
    If ($OS.Name -inotin $os_columns.column_name) {
        Invoke-Sqlcmd -Query "ALTER TABLE ad_summary ADD ""$osname"" int;"
        }
    Write-Host "UPDATE ad_summary SET ""$osname""=$oscount WHERE date = (select max(date) from ad_summary)"
    Invoke-Sqlcmd -Query "UPDATE ad_summary SET ""$osname""=$oscount WHERE date = (select max(date) from ad_summary)"
}

Foreach ($Computer in $ComputerData) {
    $Name = $Computer.Name
    $OS = $Computer.OperatingSystem
    $LastLogonTime = $Computer.lastLogonTimestamp
    $BadKerbPlaceholder = $Computer.KerberosEncryptionType
    $Enabled = $Computer.Enabled
    $DNSName = $Computer.DNSHostName
    $Query = "INSERT INTO ad_computers (comp_name,operating_system,last_logon_time,bad_kerb_method,enabled,dns_name) VALUES 
    ('$Name','$OS','$LastLogonTime','$BadKerbPlaceholder','$Enabled','$DNSName')"
    Invoke-Sqlcmd -Query $Query
}
