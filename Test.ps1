. ./Tests/Integration/MSFT_GroupPolicyObject.config.ps1
MSFT_GroupPolicyObject_config -Name StanIntegrationTest
Update-DscConfiguration
Start-DscConfiguration -Wait -Verbose -Debug -Force -Path .\MSFT_GroupPolicyObject_config