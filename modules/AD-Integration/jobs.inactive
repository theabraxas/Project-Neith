#Create AD Scheduled Tasks here
$Location = Get-Location
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "$Location\ad_data_sql_importer.ps1"'
$trigger =  New-ScheduledTaskTrigger -Daily -At 9am

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Neith-AD-Importer" -Description "Daily upload of AD data to SQL server"