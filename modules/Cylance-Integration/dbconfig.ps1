#Cylance Device Data
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "CREATE TABLE cylance_device_data (
    serial_number varchar(250) PRIMARY KEY,
    device_name varchar(250),
    os_version varchar(250),
    agent_version varchar(250),
    policy varchar(250),
    zones varchar(250),
    mac_addresses varchar(250),
    ip_addresses varchar(250),
    last_reported_user varchar(250),
    background_detection varchar(250),
    created datetime,
    files_analyzed int,
    is_online varchar(80),
    online_date datetime,
    offline_date datetime,
    )"

#Cylance Threat Data Table
Invoke-SqlCmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "CREATE TABLE cylance_threat_data (
    file_name varchar(250),
    file_status varchar(250),
    cylance_score int,
    signature_status varchar(250),
    av_industry varchar(250),
    global_quarantined varchar(250),
    safelisted varchar(250),
    signed varchar(250),
    cert_timestamp varchar(250),
    cert_issuer varchar(250),
    cert_publisher varchar(250),
    cert_subject varchar(250),
    product_name varchar(250),
    description varchar(250),
    file_version varchar(250),
    company_name varchar(250),
    copyright varchar(250),
    sha256 varchar(250),
    md5 varchar(250),
    classification varchar(250),
    device_name varchar(250),
    serial_number varchar(250),
    file_size int,
    file_path varchar(500),
    drive_type varchar(250),
    file_owner varchar(250),
    create_time datetime,
    modification_time datetime,
    access_time datetime,
    running varchar(250),
    auto_run varchar(250),
    ever_run varchar(250),
    first_found datetime,
    last_found datetime, 
    detected_by varchar(250)
    );"
    
#Cylance Event Data Table
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "CREATE TABLE cylance_event_data(
    sha256 varchar(250),
    md5 varchar(250),
    device_name varchar(250),
    date datetime,
    file_path varchar(500),
    event_status varchar(250),
    cylance_score varchar(250),
    classification varchar(250),
    running varchar(250),
    ever_run varchar(250),
    detected_by varchar(250),
    serial_number varchar(250)
);"

#Cylance Cleared Data Table
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "CREATE TABLE cylance_cleared_data(
    sha256 varchar(250),
    md5 varchar(250),
    device_name varchar(250),
    date_removed datetime,
    file_path varchar(500),
    cylance_score varchar(250),
    classification varchar(250),
    running varchar(250),
    ever_run varchar(250),
    detected_by varchar(250)
);"

#Cylance Memory Protect Data Table
Invoke-Sqlcmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "CREATE TABLE cylance_memprotect_data(
    device_name varchar(160),
    serial_number varchar(160),
    process_name varchar(160),
    added datetime,
    process_id varchar(160),
    type varchar(160),
    action varchar(160),
    user_name varchar(160)
);"
