function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $GPOName,

        [Parameter(Mandatory = $true)]
        [String]
        $OUPath,

        [String] $Enforced = "No",

        [String] $LinkEnabled = "Yes",
        
        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    return @{
        Name = $GPOName
        OUPath = $OUPath
        Enforced = $Enforced
        LinkEnabled = $LinkEnabled
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $GPOName,

        [Parameter(Mandatory = $true)]
        [String]
        $OUPath,

        [String] $Enforced = "No",

        [String] $LinkEnabled = "Yes",
        
        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $gpo = Get-GPO -Name $GPOName
    $ou = Get-ADOrganizationalUnit -Identity $OUPath
    $gpoLinks = $OU.LinkedGroupPolicyObjects -join ","

    if ($Ensure -eq 'Present') {
        Write-Verbose "Associating $OUPath with GPO $($gpo.DisplayName)"
    
        New-GPLink -Name $gpo.DisplayName -Target $OUPath -LinkEnabled $LinkEnabled -Enforced $Enforced
    } else {
        Remove-GPLink -Name $gpo.DisplayName -Target $OUPath
    }

}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $GPOName,

        [Parameter(Mandatory = $true)]
        [String]
        $OUPath,

        [String] $Enforced = "No",

        [String] $LinkEnabled = "Yes",
        
        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $gpo = Get-GPO -Name $GPOName
    $ou = Get-ADOrganizationalUnit -Identity $OUPath
    $gpoLinks = $OU.LinkedGroupPolicyObjects -join ","

    if ($Ensure -eq 'Present') {
        return $gpoLinks -match "cn={$($gpo.Id)}"
    }

    # Absent
    return $gpoLinks -notmatch "cn={$($gpo.Id)}"
    



}
