$computername = "localhost"
$dbname = "ultimatedashboard"
Set-Location SQLSERVER:\SQL\$computername\DEFAULT\databases\$dbname 

function sanitizeCylanceData {
    [string]$URI, [string]$Target, [string]$ApiToken
    $Result = Invoke-RestMethod -Method Get -Uri "$URI/$Target/$ApiToken"
    $SanitizedResult = $Result -Replace 'ï»¿','' | ConvertFrom-CSV
    New-Variable -Name $Target"Data" -Value $SanitizedResult -Scope Global
}

$URI = "https://protect.cylance.com/Reports/ThreatDataReportV1"
$APIToken = (Invoke-SqlCmd -Query "SELECT apikey FROM template_configs WHERE template_name = 'Cylance'").apikey
$APIEndpoints = ("threats","devices","events","indicators","cleared","policies","externaldevices","memoryprotection")

Foreach ($Target in  $APIEndpoints) {
    SanitizeCylanceData($URI,$Target,$APIToken)
}

#Insert DeviceData to Table
ForEach ($Device in $DevicesData) {
    $SN = $Device.'Serial Number'
    $DN = $Device.'Device Name'
    $OSV = $Device.'OS Version'
    $AgentV = $Device.'Agent Version'
    $DP = $Device.policy
    $DZ = $Device.zones
    $MACs = $Device.'Mac Addresses'
    $IPs = $Device.'IP Addresses'
    $LRU = $Device.'Last Reported User'
    $BGD = $Device.'Background Detection'
    $Crt = $Device.Created
    $FA = $Device.'Files Analyzed'
    $OL = $Device.'Is Online'
    $OLD = $Device.'Online Date'
    $OFLD = $Device.'Offline Date'
    Invoke-SqlCmd -Query "INSERT INTO cylance_device_data (
        serial_number,device_name,os_version,agent_version,policy,zones,mac_addresses,ip_addresses,last_reported_user,background_detection,created,files_analyzed,is_online,online_date,offline_date)
        VALUES ('$SN','$DN','$OSV','$AgentV','$DP','$DZ','$MACs','$IPs','$LRU','$BGD','$Crt','$FA','$OL','$OLD','$OFLD')"
}

#Insert ThreatData to Table
Foreach ($Threat in $ThreatsData) {
    $FN = $Threat.'file name'
    $FS = $Threat.'file status'
    $CyS = $Threat.'cylance score'
    $sigs = $Threat.'signature status'
    $AVI = $Threat.'av industry'
    $GlQ = $Threat.'global quarantined'
    $Safe = $Threat.'safelisted'
    $Signed = $Threat.'signed'
    $cts = $Threat.'cert timestamp'
    $cis = $Threat.'cert issuer'
    $cpub = $Threat.'cert publisher'
    $csub = $Threat.'cert subject'
    $prodN = $Threat.'product name'
    $desc = $Threat.'description'
    $fv = $Threat.'file version'
    $comp_name = $Threat.'company name'
    $copy = $Threat.'copyright'
    $sha = $Threat.'sha256'
    $md5 = $Threat.'md5'
    $class = $Threat.'classification'
    $dn = $Threat.'devicename'
    $sn = $Threat.'serial number'
    $fis = $Threat.'file size'
    $fip = $Threat.'file path'
    $drt = $Threat.'drive type'
    $fio = $Threat.'file owner'
    $crt = $Threat.'create time'
    $modt = $Threat.'modification time'
    $acct = $Threat.'access time'
    $running = $Threat.'running'
    $arun = $Threat.'auto run'
    $erun = $Threat.'ever run'
    $ffound = $Threat.'first found'
    $lfound = $Threat.'last found'
    $dby = $Threat.'detected by'
    Invoke-Sqlcmd -Query "INSERT INTO cylance_threat_data (file_name,file_status,cylance_score,signature_status,av_industry,global_quarantined,safelisted,signed,cert_timestamp,cert_issuer,cert_publisher,cert_subject,product_name,description,file_version,company_name,copyright,sha256,md5,classification,device_name,serial_number,file_size,file_path ,drive_type,file_owner,create_time,modification_time,access_time,running,auto_run,ever_run,first_found,last_found, detected_by)
    VALUES ('$FN','$FS','$CyS','$sigs','$AVI','$GlQ','$Safe','$Signed','$cts','$cis','$cpub','$csub','$prodN','$desc','$fv','$comp_name','$copy','$sha','$md5','$class','$dn','$sn','$fis','$fip','$drt','$fio','$crt','$modt','$acct','$running','$arun','$erun','$ffound','$lfound','$dby');"
    }

#Insert EventData to Table
Foreach ($Event in $EventsData) {
    $sha256 = $Event.sha256
    $md5 = $Event.md5
    $device_name = $Event.'device name'
    $date = $Event.date
    $file_path = $Event.'file path'
    $event_status = $Event.'event status'
    $cylance_score = $Event.'cylance score'
    $classification = $Event.classification
    $running = $Event.running
    $ever_run = $Event.'ever run'
    $detected_by = $Event.'detected by'
    $serial_number = $Event.'serial number'
    Invoke-Sqlcmd -Query "INSERT INTO cylance_event_data (sha256,md5,device_name,date,file_path,event_status,cylance_score,classification,running,ever_run,detected_by,serial_number)
    VALUES ('$sha256','$md5','$device_name','$date','$file_path','$event_status','$cylance_score','$classification','$running','$ever_run','$detected_by','$serial_number');"
    }

#Insert ClearedData to Table
Foreach ($ClearedEvent in $ClearedData) {
    $sha256 = $ClearedEvent.sha256
    $md5 = $ClearedEvent.md5
    $device_name = $ClearedEvent.'device name'
    $date_removed = $ClearedEvent.'date removed'
    $file_path = $ClearedEvent.'file path'
    $cylance_score = $ClearedEvent.'cylance score'
    $classification = $ClearedEvent.classification
    $running = $ClearedEvent.running
    $ever_run = $ClearedEvent.'ever run'
    $detected_by = $ClearedEvent.'detected by'
    Invoke-Sqlcmd -Query "INSERT INTO cylance_cleared_data (sha256,md5,device_name,date_removed,file_path,cylance_score,classification,running,ever_run,detected_by)
    VALUES ('$sha256','$md5','$device_name','$date_removed','$file_path','$cylance_score','$classification','$running','$ever_run','$detected_by');"
    }

#Insert MemprotectData to Table
Foreach ($MemEvent in $MemoryprotectionData) {
    $device_name = $MemEvent.'Device Name'
    $serial_number = $MemEvent.'Serial Number'
    $process_name = $MemEvent.'PROCESS NAME'
    $added = $MemEvent.'Added'
    $process_id = $MemEvent.'PROCESS ID'
    $type = $MemEvent.'TYPE'
    $acton = $MemEvent.'ACTION'
    $user_name = $MemEvent.'USER NAME'
    Invoke-Sqlcmd -Query "INSERT INTO cylance_memprotect_data(device_name,serial_number,process_name,added,process_id,type,action,user_name)
    VALUES('$device_name','$serial_number','$process_name','$added','$process_id','$type','$action','$user_name')"
}
