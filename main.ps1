#Primary Dashboard
##Make sure to run this file directly from it's location so get-location works properly

$location = Get-Location
$pagedir = $location.Path + "\pages"

#SQL Template Requirements
$SQLInstance = "localhost"
$dbname = "ultimateDashboard"
$computername = hostname
Import-Module SqlServer

#DatabaseCreation
Try {
    Invoke-Sqlcmd -ServerInstance $sqlinstance -Database $dbname -Query "CREATE DATABASE ultimatedashboard" -ErrorAction SilentlyContinue
    }
Catch {
    Write-Host "Database $dbname already exists, continuing anyways" #doesn't echo anywhere?
    }

#Make the exclusions cleaner
##Ignores the DB creators and tasks to import new data.
Get-ChildItem -Path $pagedir -Filter *.ps1 -Recurse -Exclude dbconfig*,*sql_importer* | ForEach-Object {
    . $_.FullName
}

#Determine which modules are active
$ActiveIntegrations = Invoke-Sqlcmd -ServerInstance $sqlinstance -Database $dbname -Query "Select template_name,variablename from template_configs where active = 'yes'"

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