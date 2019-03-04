Foreach ($Integration in $Integrations.keys) {
    $Description = $Integrations[$Integration]
    Invoke-SqlCmd -ServerInstance $cache:sql_instance -Database $cache:db_name -Query "INSERT INTO template_configs (template_name, description) VALUES('$Integration','$Description');"
    }
