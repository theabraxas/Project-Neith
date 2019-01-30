#db setup

#initial vars
$SQLInstance = "localhost"
$dbname = "ultimateDashboard"
$tableNames = {"ad_summary", "security_summary", "ad_daily_computers", "ad_daily_users"}
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
    os_info text
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
#Invoke-Sqlcmd -Query "CREATE TABLE ad_users ()"
#Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $dbname -Query "CREATE TABLE security_summary"
#Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $dbname -Query "CREATE TABLE ad_daily"

