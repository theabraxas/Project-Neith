Foreach ($Integration in $Integrations.keys) {
    $Description = $Integrations[$Integration]
    Invoke-SqlCmd -Query "INSERT INTO template_configs (template_name, description) VALUES('$Integration','$Description');"
    }
