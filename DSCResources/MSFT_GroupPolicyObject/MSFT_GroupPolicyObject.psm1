$RegistryPath = "HKLM:\Software\Microsoft\DSC"
$RegistryProperty = "ConfigurationMD5"

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $GpoPath,

        [Parameter()]
        [String]
        $BackupId
    )

    return @{
        Name = $Name
        GpoPath = $GpoPath
        BackupId = $BackupId
        ConfigurationMd5 = (Get-ItemPropertyValue $RegistryPath -Name "${RegistryProperty}_${Name}")
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $GpoPath,

        [Parameter()]
        [String]
        $BackupId
    )

    $gpo = Get-GPO -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $gpo) {
        $gpo = New-GPO -Name $Name 
    }

    Write-Verbose "Checking if Gpo needs to be imported: $GpoPath ($($null -eq $GpoPath) $($GpoPath.GetType()))"
    if (![string]::IsNullOrEmpty($GpoPath)) {
        Import-GPO -TargetName $gpo.DisplayName -Path $GpoPath -BackupId $BackupId
        $md5 = Get-FileHash -Algorithm MD5 -Path "${GpoPath}/{${BackupId}}/Backup.xml"
        Set-ItemProperty -Path $RegistryPath -Name "${RegistryProperty}_${Name}" -Value $md5.Hash
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
        $Name,

        [Parameter()]
        [String]
        $GpoPath,

        [Parameter()]
        [String]
        $BackupId
    )

    if (!(Get-Item $RegistryPath -ErrorAction SilentlyContinue)) {
        New-Item $RegistryPath | Out-Null
    }

    if (!(Get-ItemProperty $RegistryPath -Name "${RegistryProperty}_${Name}" -ErrorAction SilentlyContinue)) {
        New-ItemProperty $RegistryPath -Name "${RegistryProperty}_${Name}" -Value $null | Out-Null
    }

    $gpo = Get-GPO -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $gpo) {
        return $null -ne $gpo
    }

    Write-Verbose "Test path: $GpoPath $BackupId $(Test-Path "${GpoPath}/{${BackupId}}") --"
    if (Test-Path "$GpoPath/{$BackupId}") {
        $md5 = Get-FileHash -Algorithm MD5 -Path "${GpoPath}/{$BackupId}/Backup.xml"
        Write-Verbose "MD5: $($md5.Hash)"
        Write-Verbose "NEW MD5: $((Get-ItemPropertyValue $RegistryPath -Name "${RegistryProperty}_${Name}"))"
        
        return $md5.Hash -eq (Get-ItemPropertyValue $RegistryPath -Name "${RegistryProperty}_${Name}")
    }

    return $true
}
