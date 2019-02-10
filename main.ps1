#Primary Dashboard

$location = Get-Location
$pagedir = $location.Path + "\pages"

#SQL Template Requirements
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

Get-ChildItem -Path $pagedir -Filter *.ps1 -Recurse | ForEach-Object {
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