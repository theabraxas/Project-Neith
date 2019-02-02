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

#Create AD User Summary Table
Invoke-Sqlcmd -Query "CREATE TABLE ad_users (
    user_SAM_name varchar(80),
    name varchar(80),
    user_created varchar(80),
    last_logon_date varchar(80),
    user_extension varchar(80),
    enabled varchar(80),
    lockedOut varchar(80),
    email_address varchar(80),
    password_last_set varchar(80)
    );"

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