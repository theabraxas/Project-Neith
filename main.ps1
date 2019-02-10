#Primary Dashboard
##Make sure to run this file directly from it's location so get-location works properly

$location = Get-Location
$pagedir = $location.Path + "\pages"

#SQL Template Requirements
$SQLInstance = "localhost"
$dbname = "ultimateDashboard"
$computername = hostname
Import-Module SqlServer

#Set location to db location for shorter cmds
Set-Location SQLSERVER:\SQL\$computername\DEFAULT\databases\$dbname 

#DatabaseCreation
Try {
    Invoke-Sqlcmd -ServerInstance localhost -Query "CREATE DATABASE ultimatedashboard" -ErrorAction SilentlyContinue
    }
Catch {
    Write-Host "Database $dbname already exists, continuing anyways"
    }

#Make the exclusions cleaner
Get-ChildItem -Path $pagedir -Filter *.ps1 -Recurse -Exclude dbconfig*,*sql_importer* | ForEach-Object {
    . $_.FullName
}

$ActiveIntegrations = Invoke-Sqlcmd -Query "Select template_name,variablename from template_configs where active = 'yes'"

$pages = @()
$pages += $HomePage

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