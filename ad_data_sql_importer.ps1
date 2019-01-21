#AD Summary Collector Script

$UserData = Get-ADUser -Filter * -Properties *
$ComputerData = Get-ADUser -Filter * -Properties *
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

Set-Location SQLSERVER:\SQL\$computername\DEFAULT\databases\$dbname 

#Load Data to SQL Table
Invoke-Sqlcmd -Query "INSERT INTO ad_summary (date, success, total_users ,total_users_enabled ,total_groups ,total_computers ,total_enabled_computers, forest_functional_level) 
VALUES('$QueryDate','$Success','$TotalUsers','$EnabledUsers','$TotalGroups','$TotalComputers','$EnabledComputers','$ForestFunctionalLevel')"

$somedata = Invoke-SqlCmd -Query "SELECT * FROM ad_summary"
