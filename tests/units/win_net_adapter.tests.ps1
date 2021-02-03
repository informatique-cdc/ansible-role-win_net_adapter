# Set $ErrorActionPreference to what's set during Ansible execution
$ErrorActionPreference = "Stop"

#Get Current Directory
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

.$(Join-Path -Path $Here -ChildPath 'test_utils.ps1')

# Update Pester if needed
Update-Pester

#Get Function Name
$moduleName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

#Resolve Path to Module path
$ansibleModulePath = "$Here\..\..\library\$moduleName.ps1"

Function Invoke-AnsibleModule {
    [CmdletBinding()]
    Param(
        [hashtable]$params
    )

    begin {
        $global:complex_args = @{
            "_ansible_check_mode" = $false
            "_ansible_diff"       = $true
        } + $params
        Invoke-TestSetup
    }
    Process {
        . $ansibleModulePath
        return $result
    }
}

try {

    Describe 'win_net_adapter' -Tag 'Set' {

        Context 'Configure network adapters' {

            BeforeAll {

                Mock -CommandName Get-DnsClient -MockWith {
                    param (
                        [Parameter(ValueFromPipeline = $true)]
                        [int[]] $InterfaceIndex,
                        [Parameter(ValueFromPipeline = $false)]
                        [Alias('suffix')]
                        [string[]] $ConnectionSpecificSuffix
                    )
                    begin {

                        $result = @(
                            [PSCustomObject]@{
                                InterfaceAlias                 = 'Ethernet'
                                InterfaceIndex                 = 12
                                ConnectionSpecificSuffix       = 'consoto.com'
                                RegisterThisConnectionsAddress = $True
                            },
                            [PSCustomObject]@{
                                InterfaceAlias                 = 'isatap.{8DEAF26E-1FCB-4456-94A2-D05CBAA72D20}'
                                InterfaceIndex                 = 16
                                ConnectionSpecificSuffix       = $null
                                RegisterThisConnectionsAddress = $False
                            },
                            [PSCustomObject]@{
                                InterfaceAlias                 = 'Ethernet 2'
                                InterfaceIndex                 = 14
                                ConnectionSpecificSuffix       = 'backup.local'
                                RegisterThisConnectionsAddress = $true
                            },
                            [PSCustomObject]@{
                                InterfaceAlias                 = 'isatap.backup.local'
                                InterfaceIndex                 = 13
                                ConnectionSpecificSuffix       = 'backup.local'
                                RegisterThisConnectionsAddress = $False
                            },
                            [PSCustomObject]@{
                                InterfaceAlias                 = 'Ethernet 3'
                                InterfaceIndex                 = 15
                                ConnectionSpecificSuffix       = 'oob.local'
                                RegisterThisConnectionsAddress = $true
                            },
                            [PSCustomObject]@{
                                InterfaceAlias                 = 'isatap.oob.local'
                                InterfaceIndex                 = 17
                                ConnectionSpecificSuffix       = 'oob.local'
                                RegisterThisConnectionsAddress = $false
                            },
                            [PSCustomObject]@{
                                InterfaceAlias                 = 'Loopback Pseudo-Interface 1'
                                InterfaceIndex                 = 1
                                ConnectionSpecificSuffix       = @{}
                                RegisterThisConnectionsAddress = $false
                            }
                        )
                    }
                    process {
                        foreach ($key in $PSBoundParameters.Keys) {
                            $result = $result | ForEach-Object {
                                if ($_.psobject.properties.Name.Contains($key)) {
                                    $value = $PSBoundParameters[$key]
                                    if ($null -eq $value) {
                                        $_
                                    }
                                    elseif ($value -is [array]) {
                                        foreach ($val in $value) {
                                            if ($_.$key -like $val) { $_ }
                                        }
                                    }
                                    else {
                                        if ($_.$key -like $value) { $_ }
                                    }
                                }
                                else { $_ }
                            }
                        }
                    }
                    end {
                        return $result
                    }

                }

                Mock -CommandName Get-DnsClientServerAddress -MockWith {
                    param (
                        [Parameter(ValueFromPipeline = $true)]
                        [int[]] $InterfaceIndex,
                        [Parameter(ValueFromPipeline = $false)]
                        [string[]] $InterfaceAlias,
                        [Parameter(ValueFromPipeline = $false)]
                        [Alias('Family')]
                        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPAddress.AddressFamily[]] $AddressFamily
                    )
                    begin {
                        $result = @(
                            [PSCustomObject]@{
                                InterfaceAlias  = 'Ethernet'
                                InterfaceIndex  = 12
                                AddressFamily   = "IPv4"
                                ServerAddresses = @('192.168.3.33', '192.168.10.25', '192.168.3.34')
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'Ethernet'
                                InterfaceIndex  = 12
                                AddressFamily   = "IPv6"
                                ServerAddresses = @()
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'isatap.{8DEAF26E-1FCB-4456-94A2-D05CBAA72D20}'
                                InterfaceIndex  = 16
                                AddressFamily   = "IPv4"
                                ServerAddresses = { '192.168.3.33', '192.168.10.25', '192.168.3.34' }
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'isatap.{8DEAF26E-1FCB-4456-94A2-D05CBAA72D20}'
                                InterfaceIndex  = 16
                                AddressFamily   = "IPv6"
                                ServerAddresses = @()
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'Ethernet 2'
                                InterfaceIndex  = 14
                                AddressFamily   = "IPv4"
                                ServerAddresses = @()
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'isatap.backup.local'
                                InterfaceIndex  = 13
                                AddressFamily   = "IPv4"
                                ServerAddresses = @()
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'isatap.backup.local'
                                InterfaceIndex  = 13
                                AddressFamily   = "IPv6"
                                ServerAddresses = @()
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'Ethernet 3'
                                InterfaceIndex  = 15
                                AddressFamily   = "IPv4"
                                ServerAddresses = @()
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'isatap.oob.local'
                                InterfaceIndex  = 17
                                AddressFamily   = "IPv4"
                                ServerAddresses = @()
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'Loopback Pseudo-Interface 1'
                                InterfaceIndex  = 1
                                AddressFamily   = "IPv4"
                                ServerAddresses = @()
                            },
                            [PSCustomObject]@{
                                InterfaceAlias  = 'Loopback Pseudo-Interface 1'
                                InterfaceIndex  = 1
                                AddressFamily   = "IPv6"
                                ServerAddresses = @('fec0:0:0:ffff::1', 'fec0:0:0:ffff::2', 'fec0:0:0:ffff::3')
                            }
                        )
                    }
                    process {
                        foreach ($key in $PSBoundParameters.Keys) {
                            $result = $result | ForEach-Object {
                                if ($_.psobject.properties.Name.Contains($key)) {
                                    $value = $PSBoundParameters[$key]
                                    if ($null -eq $value) {
                                        $_
                                    }
                                    elseif ($value -is [array]) {
                                        foreach ($val in $value) {
                                            if ($_.$key -like $val) { $_ }
                                        }
                                    }
                                    else {
                                        if ($_.$key -like $value) { $_ }
                                    }
                                }
                                else { $_ }
                            }
                        }
                    }
                    end {
                        return $result
                    }

                }

                Mock -CommandName Get-NetAdapter -MockWith {
                    [OutputType([PSCustomObject])]
                    param (
                        [Parameter(ValueFromPipeline = $false)]
                        [string[]] $Name,
                        [Parameter(ValueFromPipeline = $true)]
                        [int[]] $InterfaceIndex
                    )
                    begin {
                        $result = @(
                            [PSCustomObject]@{
                                Name           = 'Ethernet'
                                InterfaceIndex = 12
                            },
                            [PSCustomObject]@{
                                Name           = 'Ethernet 2'
                                InterfaceIndex = 14
                            },
                            [PSCustomObject]@{
                                Name           = 'Ethernet 3'
                                InterfaceIndex = 15
                            }
                        )
                    }
                    process {
                        foreach ($key in $PSBoundParameters.Keys) {
                            $result = $result | ForEach-Object {
                                if ($_.psobject.properties.Name.Contains($key)) {
                                    $value = $PSBoundParameters[$key]
                                    if ($null -eq $value) {
                                        $_
                                    }
                                    elseif ($value -is [array]) {
                                        foreach ($val in $value) {
                                            if ($_.$key -like $val) { $_ }
                                        }
                                    }
                                    else {
                                        if ($_.$key -like $value) { $_ }
                                    }
                                }
                                else { $_ }
                            }
                        }
                    }
                    end {
                        return [PSCustomObject]$result
                    }
                }

                Mock -CommandName Get-Netadapterbinding -MockWith {
                    param (
                        [Alias('ifAlias', 'InterfaceAlias')]
                        [String] $Name,
                        [String[]] $ComponentID
                    )
                    begin {

                        $result = @(
                            [PSCustomObject]@{
                                Name        = 'Ethernet'
                                ComponentID = 'ms_tcpip6'
                                Enabled     = $true
                            },
                            [PSCustomObject]@{
                                Name        = 'Ethernet 2'
                                ComponentID = 'ms_tcpip6'
                                Enabled     = $true
                            },
                            [PSCustomObject]@{
                                Name        = 'Ethernet 3'
                                ComponentID = 'ms_tcpip6'
                                Enabled     = $true
                            }
                        )
                    }
                    process {
                        foreach ($key in $PSBoundParameters.Keys) {
                            $result = $result | ForEach-Object {
                                if ($_.psobject.properties.Name.Contains($key)) {
                                    $value = $PSBoundParameters[$key]
                                    if ($null -eq $value) {
                                        $_
                                    }
                                    elseif ($value -is [array]) {
                                        foreach ($val in $value) {
                                            if ($_.$key -like $val) { $_ }
                                        }
                                    }
                                    else {
                                        if ($_.$key -like $value) { $_ }
                                    }
                                }
                                else { $_ }
                            }
                        }
                    }
                    end {
                        return $result
                    }
                }

                Mock -CommandName Get-NetIPconfiguration -MockWith {
                    param (
                        [Parameter(ValueFromPipeline = $true)]
                        [Alias('ifIndex')]
                        [int]$InterfaceIndex,
                        [Parameter(ValueFromPipeline = $true)]
                        [Alias('ifAlias')]
                        [string]$InterfaceAlias
                    )
                    begin {
                        $result = @(
                            [PSCustomObject]@{
                                InterfaceAlias = 'Ethernet'
                                InterfaceIndex = 12
                                NetProfile     = [PSCustomObject]@{ Name = 'domain.local' }
                            },
                            [PSCustomObject]@{
                                InterfaceAlias = 'Ethernet 2'
                                InterfaceIndex = 14
                                NetProfile     = [PSCustomObject]@{ Name = 'Unidentified network' }
                            },
                            [PSCustomObject]@{
                                InterfaceAlias = 'Ethernet 3'
                                InterfaceIndex = 15
                                NetProfile     = [PSCustomObject]@{ Name = 'Unidentified network' }
                            }
                        )
                    }
                    process {
                        foreach ($key in $PSBoundParameters.Keys) {
                            $result = $result | ForEach-Object {
                                if ($_.psobject.properties.Name.Contains($key)) {
                                    $value = $PSBoundParameters[$key]
                                    if ($null -eq $value) {
                                        $_
                                    }
                                    elseif ($value -is [array]) {
                                        foreach ($val in $value) {
                                            if ($_.$key -like $val) { $_ }
                                        }
                                    }
                                    else {
                                        if ($_.$key -like $value) { $_ }
                                    }
                                }
                                else { $_ }
                            }
                        }
                    }
                    end {
                        return $result
                    }
                }
                Mock -CommandName Disable-NetAdapterBinding -MockWith { }

                Mock -CommandName Enable-NetAdapterBinding -MockWith { }

                Mock -CommandName Set-DnsClient -MockWith { }

                Mock -CommandName Set-DnsClientServerAddress -MockWith { }

                Mock -CommandName Register-DnsClient -MockWith { }

                Mock -CommandName Rename-NetAdapter -MockWith { }
            }

            It 'Should return the configuration only' {

                $params = @{
                    suffix_filter = 'oob*'
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeFalse
            }

            It 'Should renames a netcard' {

                $params = @{
                    suffix_filter = 'oob*'
                    new_Name      = 'OOB'
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
                $result.diff.after."Ethernet 3".name | Should -Be 'OOB'
            }

            It 'Should disable the tcp ipv6 protocole' {

                $params = @{
                    suffix_filter = 'oob*'
                    tcpip6        = $false
                }
                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -Be $true
                $result.diff.after."Ethernet 3".tcpip6 | Should -BeFalse
            }

            It 'Should return the register_ip_address state' {

                $params = @{
                    suffix_filter       = 'oob*'
                    register_ip_address = $false
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -Be $true
                $result.diff.after."Ethernet 3".register_ip_address | Should -BeFalse
            }

            It 'Should reset the server addresses' {

                $params = @{
                    suffix_filter          = 'consoto.com'
                    reset_server_addresses = $true
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
                $result.diff.after."Ethernet".server_addresses | Should -HaveCount 0
            }


            It 'Should change the server addresses' {

                $params = @{
                    suffix_filter    = 'consoto.com'
                    server_addresses = '8.8.8.8', '8.8.8.4'
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
                $result.diff.after."Ethernet".server_addresses | Should -Be @('8.8.8.8', '8.8.8.4')
            }

            It 'Should renames and configure multiple netcards' {

                $params = @{
                    suffix_filter          = 'consoto.com,*.local'
                    new_name               = 'OOB'
                    reset_server_addresses = $true
                    register_ip_address    = $false
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
                $result.diff.after."Ethernet".name | Should -Be "OOB"
                $result.diff.after."Ethernet 2".name | Should -Be "OOB_1"
                $result.diff.after."Ethernet 3".name | Should -Be "OOB_2"
                $result.diff.after."Ethernet".register_ip_address | Should -BeFalse
                $result.diff.after."Ethernet 2".register_ip_address | Should -BeFalse
                $result.diff.after."Ethernet 3".register_ip_address | Should -BeFalse
                $result.diff.after."Ethernet".server_addresses | Should -HaveCount 0
            }

            It 'Should disable the tcp ipv6 protocole on all cards' {

                $params = @{
                    suffix_filter = '*'
                    tcpip6        = $false
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
                $result.diff.after."Ethernet".tcpip6 | Should -BeFalse
                $result.diff.after."Ethernet 2".tcpip6 | Should -BeFalse
                $result.diff.after."Ethernet 3".tcpip6 | Should -BeFalse
                $result.diff.after."Loopback Pseudo-Interface 1".tcpip6 | Should -BeFalse
            }
        }
    }
}
finally {
    Invoke-TestCleanup
}