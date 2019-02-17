#db setup

#initial vars
$SQLInstance = "localhost"
$dbname = "ultimateDashboard"
$computername = hostname

#DatabaseCreation
Try {
    Invoke-Sqlcmd -ServerInstance localhost -Query "CREATE DATABASE ultimatedashboard" -ErrorAction SilentlyContinue
    }
Catch {
    Write-Host "Database $dbname already exists, continuing anyways"
    }

#Set location to db location for shorter cmds
Set-Location SQLSERVER:\SQL\$computername\DEFAULT\databases\$dbname 

#Create AD summary table
Invoke-Sqlcmd -Query "CREATE TABLE ad_summary (
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
Invoke-Sqlcmd -Query "CREATE TABLE ad_computers (
    comp_name text,
    operating_system text,
    last_logon_time bigint,
    bad_kerb_method text,
    enabled text,
    dns_name text
    );"

#Create OS Summary Table
Invoke-Sqlcmd -Query "CREATE TABLE ad_os_summary (
    date datetime
    )"

#Create AD User Summary Table
Invoke-Sqlcmd -Query "CREATE TABLE ad_users (
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
Invoke-Sqlcmd -Query "CREATE TABLE ad_groups (
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

#VMWare Hosts
Invoke-Sqlcmd -Query "CREATE TABLE vmware_hosts (
    host_name varchar(80) PRIMARY KEY,
    power varchar(80),
    connected varchar(80),
    manufacturer varchar(80),
    model varchar(80),
    num_cpu int,
    cpu_total int,
    cpu_usage int,
    mem_totalgb varchar(80),
    mem_usagegb varchar(80),
    proc_type varchar(80),
    hyper_threading varchar(80),
    version varchar(80),
    build varchar(80),
    parent varchar(80),
    net_info varchar(80),
    datastore_count varchar(80)
    );"

#VMware VMs
Invoke-Sqlcmd -Query "CREATE TABLE vmware_guests (
    host_name varchar(80) PRIMARY KEY,
    power varchar(80),
    notes varchar(200),
    guest varchar(80),
    num_cpu int,
    mem_totalgb int,
    vm_host varchar(80),
    folder varchar(80),
    version varchar(80),
    datastore_count varchar(80),
    provisioned_space varchar(80),
    used_space varchar(80),
    tools_version varchar(80),
    );"

#VMware Summary Table
Invoke-Sqlcmd -Query "CREATE TABLE vmware_summary (
    date datetime PRIMARY KEY,
    num_hosts varchar(80),
    num_vms varchar(80),
    num_cpu varchar(80),
    cpu_total varchar(80),
    cpu_usage varchar(80),
    mem_usagegb varchar(80),
    mem_totalgb varchar(80),
    datastore_count int
    );"

#Cylance Device Data
Invoke-Sqlcmd -Query "CREATE TABLE cylance_device_data (
    serial_number varchar(250) PRIMARY KEY,
    device_name varchar(250),
    os_version varchar(250),
    agent_version varchar(250),
    policy varchar(250),
    zones varchar(250),
    mac_addresses varchar(250),
    ip_addresses varchar(250),
    last_reported_user varchar(250),
    background_detection varchar(250),
    created datetime,
    files_analyzed int,
    is_online varchar(80),
    online_date datetime,
    offline_date datetime,
    )"

#Cylance Threat Data Table
Invoke-SqlCmd -Query "CREATE TABLE cylance_threat_data (
    file_name varchar(250),
    file_status varchar(250),
    cylance_score int,
    signature_status varchar(250),
    av_industry varchar(250),
    global_quarantined varchar(250),
    safelisted varchar(250),
    signed varchar(250),
    cert_timestamp varchar(250),
    cert_issuer varchar(250),
    cert_publisher varchar(250),
    cert_subject varchar(250),
    product_name varchar(250),
    description varchar(250),
    file_version varchar(250),
    company_name varchar(250),
    copyright varchar(250),
    sha256 varchar(250),
    md5 varchar(250),
    classification varchar(250),
    device_name varchar(250),
    serial_number varchar(250),
    file_size int,
    file_path varchar(500),
    drive_type varchar(250),
    file_owner varchar(250),
    create_time datetime,
    modification_time datetime,
    access_time datetime,
    running varchar(250),
    auto_run varchar(250),
    ever_run varchar(250),
    first_found datetime,
    last_found datetime, 
    detected_by varchar(250)
    );"
    
#Cylance Event Data Table
Invoke-Sqlcmd -Query "CREATE TABLE cylance_event_data(
    sha256 varchar(250),
    md5 varchar(250),
    device_name varchar(250),
    date datetime,
    file_path varchar(500),
    event_status varchar(250),
    cylance_score varchar(250),
    classification varchar(250),
    running varchar(250),
    ever_run varchar(250),
    detected_by varchar(250),
    serial_number varchar(250)
);"

#Cylance Cleared Data Table
Invoke-Sqlcmd -Query "CREATE TABLE cylance_cleared_data(
    sha256 varchar(250),
    md5 varchar(250),
    device_name varchar(250),
    date_removed datetime,
    file_path varchar(500),
    cylance_score varchar(250),
    classification varchar(250),
    running varchar(250),
    ever_run varchar(250),
    detected_by varchar(250)
);"

#Cylance Memory Protect Data Table
Invoke-Sqlcmd -Query "CREATE TABLE cylance_memprotect_data(
    device_name varchar(160),
    serial_number varchar(160),
    process_name varchar(160),
    added datetime,
    process_id varchar(160),
    type varchar(160),
    action varchar(160),
    user_name varchar(160)
);"


#Technology Template Table
Invoke-Sqlcmd -Query "CREATE TABLE template_configs (
    template_name varchar(24) PRIMARY KEY,
    description text,
    active varchar(24),
    variablename varchar(24),
    username varchar(24),
    password text,
    apisecret text,
    apikey text,
    ipaddr text,
    clustername text,
    hostname text,
    domainname text
    );"

$Integrations= @{AD=@('integration for active directory domain');Cylance=@('integration for cylance tenant');VMWare=@('Integration for VMware technology.')}

Foreach ($Integration in $Integrations.keys) {
    $Description = $Integrations[$Integration]
    Invoke-SqlCmd -Query "INSERT INTO template_configs (template_name, description) VALUES('$Integration','$Description');"
    }

#Invoke-Sqlcmd -Query "CREATE TABLE ad_users ()"
#Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $dbname -Query "CREATE TABLE security_summary"
#Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $dbname -Query "CREATE TABLE ad_daily"