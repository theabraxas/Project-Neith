#AD Summary Collector Script
$UserData = Get-ADUser -Filter * -Properties * -ResultPageSize 100
$ComputerData = Get-ADComputer -Filter * -Properties * -ResultPageSize 100
$GroupData = Get-ADGroup -Filter * -Properties * -ResultPageSize 100
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

#Update Summary Data Table
Invoke-Sqlcmd -Query "INSERT INTO ad_summary (date, success, total_users ,total_users_enabled ,total_groups ,total_computers ,total_enabled_computers, forest_functional_level) 
VALUES('$QueryDate','$Success','$TotalUsers','$EnabledUsers','$TotalGroups','$TotalComputers','$EnabledComputers','$ForestFunctionalLevel')"
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

#Update Computer Date Table
Invoke-Sqlcmd -Query "DELETE FROM ad_computers"
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

#Update User Data Table
Invoke-Sqlcmd -Query "DELETE FROM ad_users"
Foreach ($User in $UserData) {
    $Name = $User.Name
    $SAMName = $User.SamAccountName
    $LockedOut = $User.LockedOut
    $LastLogonDate = $User.LastLogonDate.Ticks
    $PhoneNumber = $User.OfficePhone
    $Enabled = $User.Enabled
    $PasswordLastSet = $User.PasswordLastSet.Ticks
    $CreatedOn = $User.whenCreated.Ticks
    $EmailAddress = $User.EmailAddress
    $Query = "INSERT INTO ad_users (user_SAM_name,name,user_created,last_logon_date,user_extension,enabled,LockedOut,password_last_set,email_address) VALUES 
    ('$SAMName','$Name','$CreatedOn','$LastLogonDate','$PhoneNumber','$Enabled','$LockedOut','$PasswordLastSet','$EmailAddress')"
    Try {
        Invoke-Sqlcmd -Query $Query
        }
    Catch {
        Invoke-Sqlcmd -Query "INSERT INTO ad_users (user_SAM_name,name) VALUES ('$SAMName','$Name')"
        }
}

#Update AD Group Data Table
Invoke-Sqlcmd -Query "DELETE FROM ad_groups;"
Foreach ($Group in $GroupData) {
    $objectsid = $Group.objectsid.value
    $samaccountname = $Group.SamAccountName
    $members = $Group.Members.value
    $member_count = $Group.members.count
    $memberof = $Group.memberof.Value
    $memberof_count = $Group.memberof.Count
    $created = $Group.created.Ticks
    $modified = $Group.Modified
    $description = $Group.Description
    $groupcategory = $Group.GroupCategory
    $groupscope = $Group.GroupScope
    $protect_from_deletion = $Group.ProtectedFromAccidentalDeletion
    $managedby = $Group.ManagedBy
    Try {
        Invoke-Sqlcmd -Query "INSERT INTO ad_groups (objectsid,samaccountname,members,member_count,memberof,memberof_count,created,modified,description,groupcategory,groupscope,protect_from_deletion,managedby)
            VALUES ('$objectsid','$samaccountname','$members','$member_count','$memberof','$memberof_count','$created','$modified','$description','$groupcategory','$groupscope','$protect_from_deletion','$managedby')"
        }
    Catch {
        Invoke-Sqlcmd -Query "INSERT INTO ad_groups(objectsid,samaccountname,member_count) VALUES ('$objectsid','$samaccountname','$member_count')"
    }
}