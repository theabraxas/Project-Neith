#Primary Dashboard
##Make sure to run this file directly from it's location so get-location works properly
Import-Module UniversalDashboard.Community

$location = Get-Location
$pagedir = $location.Path + "\modules"

#SQL Template Requirements
$cache:sql_instance = "localhost"
$cache:db_name= "ultimateDashboard"

Import-Module SqlServer

#DatabaseCreation
Try {
    Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "CREATE DATABASE ultimatedashboard" -ErrorAction SilentlyContinue
    }
Catch {
    Write-Host "Database already exists, continuing anyways"
    }

#Make the exclusions cleaner
##Ignores the DB creators and tasks to import new data.
Get-ChildItem -Path $pagedir -Filter *.ps1 -Recurse -Exclude dbconfig*,*sql_importer* | ForEach-Object {
    . $_.FullName
    write-host $_.fullname
    sleep -Seconds 2
}

#Determine which modules are active
$ActiveIntegrations = Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "Select template_name,variablename from template_configs where active = 'yes'"

$pages = @()
$pages += $HomePage

#create list of pages
Foreach ($int in $ActiveIntegrations) {
    $pagevar = Get-Variable $int.variablename -ValueOnly
    if ($pagevar -is [array]) {
        Foreach ($var in $pagevar) {
            $pages += $var
            }
        }
    else {
        $pages += $pagevar
    }
}

$Pages += $TemplatePage
$MyDashboard = New-UDDashboard -Pages $pages -Title "Project Neith" 

Start-UDDashboard -Port 1000 -Dashboard $MyDashboard
