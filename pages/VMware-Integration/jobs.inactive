#Create VMware Scheduled Tasks here
$Location = Get-Location
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "$Location\vmware_data_sql_importer.ps1"'
$trigger =  New-ScheduledTaskTrigger -Daily -At 9am

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Neith-VMware-Importer" -Description "Daily upload of VMware data to SQL server"