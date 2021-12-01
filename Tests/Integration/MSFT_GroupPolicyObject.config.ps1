
configuration 'MSFT_GroupPolicyObject_config'
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Import-DscResource -ModuleName 'GroupPolicyDSC'

    node localhost
    {    
        LocalConfigurationManager
        {
            DebugMode = 'All'
        }
        GroupPolicyObject Integration_Test
        {
            Name  = $Name
            GpoPath = "$PSScriptRoot/data/gpo"
            BackupId = "AB1A03CA-A251-4FDC-9C95-3BFE14EF9A54"
        }
        
        GroupPolicyObject Integration_Test2
        {
            Name  = "$($Name)2"
            GpoPath = "$PSScriptRoot/data/gpo"
            BackupId = "631572F1-2CE9-481D-8FAB-A1553A4DBD56"
        }
    }
}
