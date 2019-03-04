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
$PrivilegedGroups = @("Domain Admins","Enterprise Admins","Schema Admins","Account Operators","Administrators","Server Operators","Server Management","Backup Operators","Remote Desktop Users")


#Update Summary Data Table
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "INSERT INTO ad_summary (date, success, total_users ,total_users_enabled ,total_groups ,total_computers ,total_enabled_computers, forest_functional_level) 
VALUES('$QueryDate','$Success','$TotalUsers','$EnabledUsers','$TotalGroups','$TotalComputers','$EnabledComputers','$ForestFunctionalLevel')"

#Update AD OS Summary Table
$os_columns= Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "Select * from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ad_os_summary'"
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "INSERT INTO ad_os_summary (date) Values ('$QueryDate')"
Foreach ($OS in $OSData) { 
    $osname = $os.name
    $oscount = $os.count
    If ($oscount -eq "") {
        $oscount = 0
    }
    If ($OS.Name -inotin $os_columns.column_name) {
        Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "ALTER TABLE ad_os_summary ADD ""$osname"" int;"
        }
    Write-Host "UPDATE ad_os_summary SET ""$osname""=$oscount WHERE date = (select max(date) from ad_os_summary)"
    Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "UPDATE ad_os_summary SET ""$osname""=$oscount WHERE date = (select max(date) from ad_os_summary)"
}

#Update Computer Date Table
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "DELETE FROM ad_computers"
Foreach ($Computer in $ComputerData) {
    $Name = $Computer.Name
    $OS = $Computer.OperatingSystem
    $LastLogonTime = $Computer.lastLogonTimestamp
    $BadKerbPlaceholder = $Computer.KerberosEncryptionType
    $Enabled = $Computer.Enabled
    $DNSName = $Computer.DNSHostName
    $Query = "INSERT INTO ad_computers (comp_name,operating_system,last_logon_time,bad_kerb_method,enabled,dns_name) VALUES 
    ('$Name','$OS','$LastLogonTime','$BadKerbPlaceholder','$Enabled','$DNSName')"
    Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query $Query
}

#Update User Data Table
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "DELETE FROM ad_users"
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
    $passwordnotrequired = $User.passwordnotrequired
    $Passwordneverexpires = $User.passwordneverexpires
    $passwordexpired = $User.passwordexpired
    $Allowreversiblepasswordencryption = $User.allowreversiblepasswordencryption
    $badlogoncount = $User.badlogoncount
    $badpasswordtime = $User.badpasswordtime
    $badpwdcount = $User.badpwdcount
    $cannotchangepassword = $User.cannotchangepassword
    $city = $User.city
    $department = $User.department
    $homedirectory = $User.homedirectory
    $lockouttime = $User.lockouttime
    $logoncount = $User.logoncount
    $mobilephone = $User.mobilephone
    $scriptpath = $User.scriptpath
    $smartcardlogonrequired = $User.smartcardlogonrequired
    $trustedfordelegation = $User.trustedfordelegation
    $UseDESKeyOnly = $User.usedeskeyonly
    $WhenChanged = $User.whenchanged
    #Add to insert - passwordnotrequired,Passwordneverexpires,passwordexpired,Allowreversiblepasswordencryption,badlogoncount,badpasswordtime,badpwdcount,cannotchangepassword,city,department,homedirectory,lockouttime,logoncount,mobilephone,scriptpath,smartcardlogonrequired,trustedfordelegation,UseDESKeyOnly,WhenChanged
    #$passwordnotrequired,$Passwordneverexpires,$passwordexpired,$Allowreversiblepasswordencryption,$badlogoncount,$badpasswordtime,$badpwdcount,$cannotchangepassword,$city,$department,$homedirectory,$lockouttime,$logoncount,$mobilephone,$scriptpath,$smartcardlogonrequired,$trustedfordelegation,$UseDESKeyOnly,$WhenChanged
    $Query = "INSERT INTO ad_users (user_SAM_name,name,user_created,last_logon_date,user_extension,enabled,LockedOut,password_last_set,email_address,passwordnotrequired,Passwordneverexpires,passwordexpired,Allowreversiblepasswordencryption,badlogoncount,badpasswordtime,badpwdcount,cannotchangepassword,city,department,homedirectory,lockouttime,logoncount,mobilephone,scriptpath,smartcardlogonrequired,trustedfordelegation,UseDESKeyOnly,WhenChanged) VALUES 
    ('$SAMName','$Name','$CreatedOn','$LastLogonDate','$PhoneNumber','$Enabled','$LockedOut','$PasswordLastSet','$EmailAddress','$passwordnotrequired','$Passwordneverexpires','$passwordexpired','$Allowreversiblepasswordencryption','$badlogoncount','$badpasswordtime','$badpwdcount','$cannotchangepassword','$city','$department','$homedirectory','$lockouttime','$logoncount','$mobilephone','$scriptpath','$smartcardlogonrequired','$trustedfordelegation','$UseDESKeyOnly','$WhenChanged')"
    Try {
        Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query $Query
        }
    Catch {
        Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "INSERT INTO ad_users (user_SAM_name,name) VALUES ('$SAMName','$Name')"
        }
}

#Update AD Group Data Table
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "DELETE FROM ad_groups;"
Foreach ($Group in $GroupData) {
    $objectsid = $Group.objectsid.value
    $samaccountname = $Group.SamAccountName
    $members = $Group.Members.value
    $member_count = $Group.members.count
    $memberof = $Group.memberof.Value
    $memberof_count = $Group.memberof.Count
    $created = $Group.created.Ticks
    $modified = $Group.Modified.Ticks
    $description = $Group.Description
    $groupcategory = $Group.GroupCategory
    $groupscope = $Group.GroupScope
    $protect_from_deletion = $Group.ProtectedFromAccidentalDeletion
    $managedby = $Group.ManagedBy
    Try {
        Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "INSERT INTO ad_groups (objectsid,samaccountname,members,member_count,memberof,memberof_count,created,modified,description,groupcategory,groupscope,protect_from_deletion,managedby)
            VALUES ('$objectsid','$samaccountname','$members','$member_count','$memberof','$memberof_count','$created','$modified','$description','$groupcategory','$groupscope','$protect_from_deletion','$managedby')"
        }
    Catch {
        Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "INSERT INTO ad_groups(objectsid,samaccountname,member_count) VALUES ('$objectsid','$samaccountname','$member_count')"
    }
}

#Update AD Privileged Groups Table