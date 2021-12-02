$RegistryPath = "HKLM:\Software\Microsoft\DSC"
$RegistryProperty = "ConfigurationMD5"

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $BackupPath,

        [Parameter()]
        [String]
        $BackupId,
        
        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    return @{
        Name             = $Name
        BackupPath          = $BackupPath
        BackupId         = $BackupId
        ConfigurationMd5 = (Get-ItemPropertyValue $RegistryPath -Name "${RegistryProperty}_${Name}")
    }
}

function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $BackupPath,

        [Parameter()]
        [String]
        $BackupId,
        
        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    if ($Ensure -eq 'Present') {
        $gpo = Get-GPO -Name $Name -ErrorAction SilentlyContinue
        if ($null -eq $gpo) {
            $gpo = New-GPO -Name $Name 
        }

        Write-Verbose "Checking if Gpo needs to be imported: $BackupPath ($($null -eq $BackupPath) $($BackupPath.GetType()))"
        if (![string]::IsNullOrEmpty($BackupPath)) {
            Import-GPO -TargetName $gpo.DisplayName -Path $BackupPath -BackupId $BackupId
            $md5 = Get-FileHash -Algorithm MD5 -Path "${BackupPath}/{${BackupId}}/Backup.xml"
            Set-ItemProperty -Path $RegistryPath -Name "${RegistryProperty}_${Name}" -Value $md5.Hash
        }
    }
    else {
        Remove-GPO -Name $Name
        Remove-ItemProperty -Path $RegistryPath -Name "${RegistryProperty}_${Name}"
    }
}

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $BackupPath,

        [Parameter()]
        [String]
        $BackupId,
        
        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    if (!(Get-Item $RegistryPath -ErrorAction SilentlyContinue)) {
        New-Item $RegistryPath | Out-Null
    }
    
    $gpo = Get-GPO -Name $Name -ErrorAction SilentlyContinue

    if ($Ensure -eq 'Present') {
        if (!(Get-ItemProperty $RegistryPath -Name "${RegistryProperty}_${Name}" -ErrorAction SilentlyContinue)) {
            New-ItemProperty $RegistryPath -Name "${RegistryProperty}_${Name}" -Value $null | Out-Null
        }
    
        if ($null -eq $gpo) {
            return $False
        }
    
        Write-Verbose "Test path: $BackupPath $BackupId $(Test-Path "${BackupPath}/{${BackupId}}") --"
        if (Test-Path "$BackupPath/{$BackupId}") {
            $md5 = Get-FileHash -Algorithm MD5 -Path "${BackupPath}/{$BackupId}/Backup.xml"
            return $md5.Hash -eq (Get-ItemPropertyValue $RegistryPath -Name "${RegistryProperty}_${Name}")
        }
    } else {
        Write-Verbose "GPO: $gpo (Test: $($null -eq $gpo))"
        return $null -eq $gpo
    }


    return $true
}
