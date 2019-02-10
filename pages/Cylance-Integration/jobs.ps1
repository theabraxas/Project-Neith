#Create Cylance Scheduled Tasks here
$Location = Get-Location
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "$Location\cylance_data_sql_importer.ps1"'
$trigger =  New-ScheduledTaskTrigger -Daily -At 9am

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Neith-Cylance-Importer" -Description "Daily upload of Cylance data to SQL server"