
configuration 'MSFT_GroupPolicyObject_config'
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $GPOName
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
            # Ensure = 'Absent'
            Name  = $GPOName
            BackupPath = "$PSScriptRoot/data/gpo"
            BackupId = "AB1A03CA-A251-4FDC-9C95-3BFE14EF9A54"
        }
        
        GroupPolicyAssignment OUAssignment
        {
            # Ensure = 'Absent'
            GPOName  = $GPOName
            OUPath = "OU=Servers,OU=dev,OU=Sharepoint,DC=testdomain,DC=com"
            DependsOn = @(
                "[GroupPolicyObject]Integration_Test"
            )
        }
    }
}
