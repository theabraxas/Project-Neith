#Create AD tables in Database
$computername = 'localhost'
$dbname = 'ultimatedashboard'

#Create AD summary table
Invoke-Sqlcmd -ServerInstance $sqlinstance -Database $dbname -Query "CREATE TABLE ad_summary (
    date datetime PRIMARY KEY,
    success bit,
    total_users int,
    total_users_enabled int,
    total_groups int,
    total_computers int,
    total_enabled_computers int,
    forest_functional_level text,
    );"

#Create AD Computer Summary Table
Invoke-Sqlcmd -ServerInstance $sqlinstance -Database $dbname -Query "CREATE TABLE ad_computers (
    comp_name text,
    operating_system text,
    last_logon_time bigint,
    bad_kerb_method text,
    enabled text,
    dns_name text
    );"

#Create OS Summary Table
Invoke-Sqlcmd -ServerInstance $sqlinstance -Database $dbname -Query "CREATE TABLE ad_os_summary (
    date datetime
    )"

#Create AD User Summary Table
Invoke-Sqlcmd -ServerInstance $sqlinstance -Database $dbname -Query "CREATE TABLE ad_users (
    user_SAM_name varchar(80),
    name varchar(80),
    user_created bigint,
    last_logon_date bigint,
    user_extension varchar(80),
    enabled varchar(80),
    lockedOut varchar(80),
    email_address varchar(80),
    password_last_set bigint,
    passwordnotrequired varchar(250),
    Passwordneverexpires varchar(250),
    passwordexpired varchar(250),
    Allowreversiblepasswordencryption varchar(250),
    badlogoncount varchar(250),
    badpasswordtime varchar(250),
    badpwdcount varchar(250),
    cannotchangepassword varchar(250),
    city varchar(250),
    department varchar(250),
    homedirectory varchar(250),
    lockouttime varchar(250),
    logoncount varchar(250),
    mobilephone varchar(250),
    scriptpath varchar(250),
    smartcardlogonrequired varchar(250),
    trustedfordelegation varchar(250),
    UseDESKeyOnly varchar(250),
    WhenChanged varchar(250)
    );"

#Create AD Group Summary Table
Invoke-Sqlcmd -ServerInstance $sqlinstance -Database $dbname -Query "CREATE TABLE ad_groups (
    objectsid varchar(250) PRIMARY KEY,
    samaccountname varchar(250),
    members text,
    member_count int,
    memberof text,
    memberof_count int,
    created bigint,
    modified bigint,
    description varchar(250),
    groupcategory varchar(80),
    groupscope varchar(80),
    protect_from_deletion varchar(80),
    managedby varchar(2500),
    )"
