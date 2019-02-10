#VMWare Hosts
Invoke-Sqlcmd -Query "CREATE TABLE vmware_hosts (
    host_name varchar(80) PRIMARY KEY,
    power varchar(80),
    connected varchar(80),
    manufacturer varchar(80),
    model varchar(80),
    num_cpu int,
    cpu_total int,
    cpu_usage int,
    mem_totalgb varchar(80),
    mem_usagegb varchar(80),
    proc_type varchar(80),
    hyper_threading varchar(80),
    version varchar(80),
    build varchar(80),
    parent varchar(80),
    net_info varchar(80),
    datastore_count varchar(80)
    );"

#VMware VMs
Invoke-Sqlcmd -Query "CREATE TABLE vmware_guests (
    host_name varchar(80) PRIMARY KEY,
    power varchar(80),
    notes varchar(200),
    guest varchar(80),
    num_cpu int,
    mem_totalgb int,
    vm_host varchar(80),
    folder varchar(80),
    version varchar(80),
    datastore_count varchar(80),
    provisioned_space varchar(80),
    used_space varchar(80),
    tools_version varchar(80),
    );"

#VMware Summary Table
Invoke-Sqlcmd -Query "CREATE TABLE vmware_summary (
    date datetime PRIMARY KEY,
    num_hosts varchar(80),
    num_vms varchar(80),
    num_cpu varchar(80),
    cpu_total varchar(80),
    cpu_usage varchar(80),
    mem_usagegb varchar(80),
    mem_totalgb varchar(80),
    datastore_count int
    );"