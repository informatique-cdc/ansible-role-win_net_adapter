#!powershell

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"
#requires -Version 2.0

# Localized messages
data LocalizedData {
    # culture="en-US"
    ConvertFrom-StringData @'
    ErrorGetNetAdapter  = "Failed to get the basic network adaptater properties: InterfaceIndex={0} Message={1}"
    ErrorRenameNetAdapter = "Failed to rename the network adapter: InterfaceIndex={0} NewName={1} Message={2}"
    ErrorGetDnsClientServerAddress = "Failed to get DNS server IP addresses from the TCP/IP properties on the interface: InterfaceIndex={0} Message={1}"
    ErrorSetDnsClientServerAddress = "Failed to set DNS server addresses associated with the TCP/IP properties on the interface: InterfaceIndex={0} Message={1}"
    ErrorResetServerAddresses = "Failed to reset the DNS server IP addresses to the default value: InterfaceIndex={0} Message={1}"
    ErrorNetAdapterIPv6Binding = "Failed to set the binding status of the IPv6 component: InterfaceIndex={0} Ipv6={1} Message={2}"
    ErrorRegisterThisConnectionsAddress = "Failed to indicate whether the IP address for this connection is to be registered: InterfaceIndex={0} RegisterThisConnectionsAddress={1} Message={2}"
    ErrorGetDnsClient = "Failed to get details of the network interface: ConnectionSpecificSuffix={0} Message={1}"
    ErrorGetNetadapterbinding = "Failed to get the basic network adaptater binding: InterfaceIndex={0} Message={1}"
'@
}

function Get-TargetResource {
    [OutputType([object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]]
        $Suffix,
        ## Catch all to enable splatted $PSBoundParameters
        [Parameter(mandatory = $false, ValueFromRemainingArguments = $true)]
        $RemainingArguments
    )

    $dnsClients = @()

    foreach ($connectionSuffix in $Suffix) {
        try {
            $tmp = Get-DnsClient -ConnectionSpecificSuffix $connectionSuffix -ErrorAction SilentlyContinue | Where-Object -Property InterfaceAlias -NotLike -Value "*isatap*"
        }
        catch {
            $result = @{
                command           = 'Get-DnsClient -ConnectionSpecificSuffix'
                suffix_filter     = $connectionSuffix
                exception_message = $_.exception.Message
            }
            Fail-Json -obj $result -Message ($LocalizedData.ErrorGetDnsClient -f $connectionSuffix, $_.exception.Message);
        }
        if ($tmp) {
            $dnsClients += $tmp
        }
        else {
            $tmp = Get-NetIPconfiguration | Where-Object { $_.NetProfile.Name -eq $connectionSuffix } | Select-Object -Property InterfaceIndex | Get-DnsClient
            if ($tmp) {
                $dnsClients += $tmp
            }
        }
    }

    $dnsClients = $dnsClients | Sort-Object -Property InterfaceAlias
    $targetResource = @()

    foreach ($dnsClient in $dnsClients) {

        $interfaceIndex = $dnsClient.InterfaceIndex
        $interfaceAlias = $dnsClient.InterfaceAlias

        try {
            $dnsClientServerAddress = Get-DnsClientServerAddress -InterfaceAlias $interfaceAlias -Family IPv4
        }
        catch {
            $result = @{
                command           = 'Get-DnsClientServerAddress -Family IPv4'
                interface_index   = $interfaceIndex
                interface_alias   = $interfaceAlias
                exception_message = $_.exception.Message
            }
            Fail-Json -obj $result -Message ($LocalizedData.ErrorGetDnsClientServerAddress -f $interfaceIndex, $_.exception.Message);
        }
        try {
            $netAdapter = Get-NetAdapter -InterfaceAlias $interfaceAlias
        }
        catch {
            $result = @{
                command           = 'Get-NetAdapter'
                interface_index   = $interfaceIndex
                interface_alias   = $interfaceAlias
                exception_message = $_.exception.Message
            }
            Fail-Json -obj $result -Message ($LocalizedData.ErrorGetNetAdapter -f $interfaceIndex, $_.exception.Message);
        }
        $serverAddresses = $($dnsClientServerAddress | select-object -ExpandProperty ServerAddresses)
        try {
            $ipv6 = Get-Netadapterbinding -Name "$($netAdapter.Name)" -ComponentID "ms_tcpip6"
        }
        catch {
            $result = @{
                command           = 'Get-Netadapterbinding'
                exception_message = $_.exception.Message
            }
            Fail-Json -obj $result -Message ($LocalizedData.ErrorGetNetadapterbinding -f $netAdapter.InterfaceIndex, $_.exception.Message);
        }
        $ipv6State = $ipv6 | select-object -ExpandProperty Enabled

        $data = [PSCustomObject]@{
            InterfaceIndex                 = $interfaceIndex
            InterfaceAlias                 = $interfaceAlias
            RegisterThisConnectionsAddress = $dnsClient.RegisterThisConnectionsAddress
            ServerAddresses                = $serverAddresses
            Suffix                         = $($dnsClient | Select-Object -ExpandProperty ConnectionSpecificSuffix)
            Ipv6                           = $ipv6State
        }
        $targetResource += $data
    }
    return $targetResource
}

function Test-TargetResource {
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]]
        $Suffix,
        [string]
        $NewName,
        [boolean]
        $RegisterThisConnectionsAddress,
        [boolean]
        $ResetServerAddresses,
        [string[]]
        $ServerAddresses,
        [boolean]
        $Ipv6
    )

    $isCompliant = $true;

    $resources = Get-TargetResource @PSBoundParameters;

    if (-not ($resources -is [array])) {
        $resources = @($resources)
    }

    if ($resources.Length -eq 0) {
        return $isCompliant
    }

    if ($PSBoundParameters.ContainsKey('NewName') -and (-not ([string]::IsNullOrEmpty($NewName)))) {
        $patternNewNameOnly = "^$NewName$"
        $patternNewNameIndexed = "^$($NewName)_(\d*)$"

        $compliantResource = $resources | Where-Object { $_.InterfaceAlias -Match $patternNewNameOnly }
        if (-not $compliantResource) {
            $compliantResources = $resources | Where-Object { $_.InterfaceAlias -Match $patternNewNameIndexed }
            if ($compliantResources) {
                if ((-not ($compliantResources -is [array])) -or ($compliantResources.Length -eq 1)) {
                    $isCompliant = $false;
                }
            }
            else {
                $isCompliant = $false;
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('RegisterThisConnectionsAddress')) {
        $select = $resources | Where-Object { $_.RegisterThisConnectionsAddress -ne $RegisterThisConnectionsAddress }
        if ($select) {
            $isCompliant = $false;
        }
    }

    if ($PSBoundParameters.ContainsKey('ResetServerAddresses')) {
        if ($ResetServerAddresses) {
            $select = $resources | Where-Object { ($null -ne $_.ServerAddresses) -and ($_.ServerAddresses.Length -gt 0) }
            if ($select) {
                $isCompliant = $false;
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('ServerAddresses')) {
        if ($ServerAddresses) {
            $select = $resources | Where-Object { ($null -eq $_.ServerAddresses) -or (($ServerAddresses -join ',') -ne ($_.ServerAddresses -join ',')) }
            if ($select) {
                $isCompliant = $false;
            }
        }
        else {
            $select = $resources | Where-Object { ($null -ne $_.ServerAddresses) }
            if ($select) {
                $isCompliant = $false;
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('Ipv6')) {
        $select = $resources | Where-Object { $_.Ipv6 -ne $Ipv6 }
        if ($select) {
            $isCompliant = $false;
        }
    }

    return $isCompliant
}

function Set-TargetResource {
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]]
        $Suffix,
        [string]
        $NewName,
        [boolean]
        $RegisterThisConnectionsAddress,
        [boolean]
        $ResetServerAddresses,
        [string[]]
        $ServerAddresses,
        [boolean]
        $Ipv6
    )

    $changed = $false
    $isCompliant = Test-TargetResource @PSBoundParameters;
    if ($isCompliant) {
        return $changed
    }

    $resources = Get-TargetResource @PSBoundParameters;

    if (-not ($resources -is [array])) {
        $resources = @($resources)
    }

    if ($diff_mode) {
        foreach ($res in $resources) {
            $result.diff.after.$($res.InterfaceAlias) = @{}
            $result.diff.before.$($res.InterfaceAlias) = @{}
        }
    }

    $changed = $false

    if ($PSBoundParameters.ContainsKey('ResetServerAddresses')) {
        if ($ResetServerAddresses) {
            $select = $resources | Where-Object { ($null -ne $_.ServerAddresses) -and ($_.ServerAddresses.Length -gt 0) }
            if ($select) {
                foreach ($res in $select) {
                    try {
                        if (-not $check_mode) {
                            Set-DnsClientServerAddress -InterfaceAlias $res.InterfaceAlias -ResetServerAddresses
                        }
                        if ($diff_mode) {
                            $result.diff.before.$($res.InterfaceAlias).server_addresses = $res.ServerAddresses
                            $result.diff.after.$($res.InterfaceAlias).server_addresses = @()
                        }
                    }
                    catch {
                        $result = @{
                            command                = 'Set-DnsClientServerAddress -ResetServerAddresses'
                            changed                = $changed
                            interface_index        = $res.InterfaceIndex
                            interface_alias        = $res.InterfaceAlias
                            reset_server_addresses = $true
                            exception_message      = $_.exception.Message
                        }
                        Fail-Json -obj $result -Message ($LocalizedData.ErrorResetServerAddresses -f $res.InterfaceIndex, $_.exception.Message);
                    }
                }
                $changed = $true
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('ServerAddresses')) {
        if ($ServerAddresses) {
            $select = $resources | Where-Object { ($null -eq $_.ServerAddresses) -or (($ServerAddresses -join ',') -ne ($_.ServerAddresses -join ',')) }
            if ($select) {
                foreach ($res in $select) {
                    try {
                        if (-not $check_mode) {
                            Set-DnsClientServerAddress -InterfaceAlias $res.InterfaceAlias -ServerAddresses $ServerAddresses
                        }
                        if ($diff_mode) {
                            $result.diff.before.$($res.InterfaceAlias).server_addresses = $res.ServerAddresses
                            $result.diff.after.$($res.InterfaceAlias).server_addresses = $ServerAddresses
                        }
                    }
                    catch {
                        $result = @{
                            command           = 'Set-DnsClientServerAddress -ServerAddresses'
                            changed           = $changed
                            interface_index   = $res.InterfaceIndex
                            interface_alias   = $res.InterfaceAlias
                            exception_message = $_.exception.Message
                            server_addresses  = $ServerAddresses
                        }
                        Fail-Json -obj $result -Message ($LocalizedData.SetDnsClientServerAddress -f $res.InterfaceIndex, $_.exception.Message);
                    }
                }
                $changed = $true
            }
        }
        else {
            $select = $resources | Where-Object { ($null -ne $_.ServerAddresses) }
            if ($select) {
                foreach ($res in $select) {
                    try {
                        if (-not $check_mode) {
                            Set-DnsClientServerAddress -InterfaceAlias $res.InterfaceAlias -ResetServerAddresses
                        }
                        if ($diff_mode) {
                            $result.diff.before.$($res.InterfaceAlias).server_addresses = $res.ServerAddresses
                            $result.diff.after.$($res.InterfaceAlias).server_addresses = @{}
                        }
                    }
                    catch {
                        $result = @{
                            command                = 'Set-DnsClientServerAddress -ResetServerAddresses'
                            changed                = $changed
                            interface_index        = $res.InterfaceIndex
                            interface_alias        = $res.InterfaceAlias
                            exception_message      = $_.exception.Message
                            reset_server_addresses = $true
                        }
                        Fail-Json -obj $result -Message ($LocalizedData.ErrorResetServerAddresses -f $res.InterfaceIndex, $_.exception.Message);
                    }
                }
                $changed = $true
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('IPv6')) {
        $select = $resources | Where-Object { $_.IPv6 -ne $IPv6 }
        if ($select) {
            foreach ($res in $select) {
                try {
                    if ($IPv6) {
                        if (-not $check_mode) {
                            Get-NetAdapter -InterfaceAlias $res.InterfaceAlias | Enable-NetAdapterBinding -ComponentID "ms_tcpip6"
                        }
                    }
                    else {
                        if (-not $check_mode) {
                            Get-NetAdapter -InterfaceAlias $res.InterfaceAlias | Disable-NetAdapterBinding -ComponentID "ms_tcpip6"
                        }
                        if ($diff_mode) {
                            $result.diff.before.$($res.InterfaceAlias).tcpip6 = $res.Ipv6
                            $result.diff.after.$($res.InterfaceAlias).tcpip6 = $IPv6
                        }
                    }
                }
                catch {
                    $result = @{
                        command           = 'Enable-NetAdapterBinding/Disable-NetAdapterBinding -ComponentID ms_tcpip6'
                        changed           = $changed
                        interface_index   = $res.InterfaceIndex
                        interface_alias   = $res.InterfaceAlias
                        exception_message = $_.exception.Message
                        tcpip6            = $IPv6
                    }
                    Fail-Json -obj $result -Message ($LocalizedData.ErrorNetAdapterIPv6Binding -f $res.InterfaceIndex, $IPv6, $_.exception.Message);
                }
                $changed = $true
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('RegisterThisConnectionsAddress')) {
        $select = $resources | Where-Object { $_.RegisterThisConnectionsAddress -ne $RegisterThisConnectionsAddress }
        if ($select) {
            foreach ($res in $select) {
                try {
                    if (-not $check_mode) {
                        Set-DnsClient -InterfaceAlias $res.InterfaceAlias -RegisterThisConnectionsAddress $RegisterThisConnectionsAddress
                    }
                    if ($diff_mode) {
                        $result.diff.before.$($res.InterfaceAlias).register_ip_address = $res.RegisterThisConnectionsAddress
                        $result.diff.after.$($res.InterfaceAlias).register_ip_address = $RegisterThisConnectionsAddress
                    }
                }
                catch {
                    $result = @{
                        command                           = 'Set-DnsClient -RegisterThisConnectionsAddress'
                        changed                           = $changed
                        interface_index                   = $res.InterfaceIndex
                        interface_alias                   = $res.InterfaceAlias
                        register_this_connections_address = $RegisterThisConnectionsAddress
                        exception_message                 = $_.exception.Message
                    }
                    Fail-Json -obj $result -Message ($LocalizedData.ErrorRegisterThisConnectionsAddress -f $res.InterfaceIndex, $RegisterThisConnectionsAddress, $_.exception.Message);
                }

            }
            if (($RegisterThisConnectionsAddress) -and (-not $check_mode)) {
                Register-DnsClient
            }
            $changed = $true
        }
    }

    if ($PSBoundParameters.ContainsKey('NewName') -and (-not ([string]::IsNullOrEmpty($NewName)))) {
        $patternNewNameOnly = "^$NewName$"
        $patternNewNameIndexed = "^$($NewName)_(\d*)$"
        $pattern = "^$NewName($|_(\d*))$"
        $notCompliantResources = $null

        # looking netcard with the new name
        $compliantResource = $resources | Where-Object { $_.InterfaceAlias -Match $patternNewNameOnly }

        if (-not $compliantResource) {
            $compliantResources = $resources | Where-Object { $_.InterfaceAlias -Match $patternNewNameIndexed }
            # Rename if there is one netcard exists only
            if ($compliantResources) {
                if ((-not ($compliantResources -is [array])) -or ($compliantResources.Length -eq 1)) {
                    $changed = Rename-NetCard -InputObject $compliantResources[0] -NewName $NewName
                }
            }
            else {
                $notCompliantResources = $resources | Where-Object { $_.InterfaceAlias -NotMatch $pattern }
            }
        }

        if ($notCompliantresources) {
            $compliantResources = $resources | Where-Object { $_.InterfaceAlias -Match $pattern }
            $highest = $compliantResources |
            Select-Object -Property @{ name = "IntVal"; expression = { [int]([regex]::replace($_.InterfaceAlias, $pattern, '$2')) } } |
            Sort-Object -Property IntVal |
            Select-Object -Last 1

            if ($null -eq $highest) {
                $highest = -1
            }
            else {
                $highest = $highest.IntVal
            }

            foreach ($res in $notCompliantResources) {
                do {
                    $highest++

                    if ($highest -gt 0) {
                        $Name = $NewName + '_' + [string]$highest
                    }
                    else {
                        $Name = $NewName
                    }
                    $net = Get-NetAdapter -InterfaceAlias $Name -ErrorAction SilentlyContinue
                }
                until ($null -eq $net)

                $changed = Rename-NetCard -InputObject $res -NewName $name
            }
        }
    }
    return $changed
}

function Rename-NetCard {
    param (
        $InputObject,
        [string]
        $NewName
    )

    try {
        $netAdapter = Get-NetAdapter -InterfaceAlias $InputObject.InterfaceAlias
        if (-not $check_mode) {
            Rename-NetAdapter -Name $netAdapter.Name -NewName $NewName
        }
        if ($diff_mode) {
            $result.diff.before.$($InputObject.InterfaceAlias).name = $netAdapter.Name
            $result.diff.after.$($InputObject.InterfaceAlias).name = $NewName
        }
        return $true
    }
    catch {
        $result = @{
            command           = 'Rename-NetCard'
            changed           = $false
            interface_index   = $InputObject.InterfaceIndex
            interface_alias   = $InputObject.InterfaceAlias
            new_name          = $NewName
            exception_message = $_.exception.Message
        }
        Fail-Json -obj $result -Message ($LocalizedData.ErrorRenameNetAdapter -f $NewName, $InputObject.InterfaceIndex, $_.exception.Message);
        return $false
    }
}


<#
.SYNOPSIS
Sets one or more interface specific DNS client or Network Adaptateur configurations on the computer by using the connection specific suffix as filter.

.DESCRIPTION
The Set-Net​Adapter​BySuffix sets one or more the interface specific DNS client or Network Adaptateur configurations on the computer by using the connection specific suffix as filter.

.PARAMETER Suffix
Specifie the DNS suffixes or the network profile names which will be used to filter the network adapter to configure.

.PARAMETER NewName
Specifies the new name and interface alias of the network adapter.

.PARAMETER RegisterThisConnectionsAddress
Indicates whether the IP address for this connection is to be registered. (Option 'Register this connection's addresses in DNS' in DNS client properties).

.PARAMETER ResetServerAddresses
Resets the DNS server IP addresses to the default value.

.PARAMETER ServerAddresses
Specifies a list of DNS server IP addresses to set for the interface.

.PARAMETER IPv6
Specifies to enable or to disable the IPv6 binding to the network adapter.

.EXAMPLE
Set-Net​Adapter​BySuffix -suffix "consoto.com" -NewName "CONSO"

.EXAMPLE
Set-Net​Adapter​BySuffix -suffix "consoto.com","*.microsoft.com" -NewName "CORPO" -UnregisterThisConnectionsAddress

.EXAMPLE
Set-Net​Adapter​BySuffix -suffix "oob.consoto.local","*.oob.consoto.local" -NewName "OOB" -RegisterThisConnectionsAddress $true -ResetServerAddresses $true

.EXAMPLE
Set-Net​Adapter​BySuffix -suffix "consoto.com" -NewName "CONSO" -ServerAddresses "10.10.10.10","10.10.10.20"

.NOTES
You need to run this function as a member of the local Administrators group; doing so is the only way to ensure you have permission to update the settings.

#>
function Set-Net​Adapter​BySuffix {
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]]
        $Suffix,
        [string]
        $NewName,
        [boolean]
        $RegisterThisConnectionsAddress,
        [boolean]
        $ResetServerAddresses,
        [string[]]
        $ServerAddresses,
        [boolean]
        $IPv6
    )
    $changed = Set-TargetResource @PSBoundParameters;
    return $changed
}


$params = Parse-Args -arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false
$diff_mode = Get-AnsibleParam -obj $params -name "_ansible_diff" -type "bool" -default $false

$Suffix = Get-AnsibleParam -obj $params -name "suffix_filter" -type "list" -failifempty $true
$NewName = Get-AnsibleParam -obj $params -name "new_name" -type "str" -failifempty $false
$RegisterThisConnectionsAddress = Get-AnsibleParam -obj $params -name "register_ip_address" -type "bool" -failifempty $false
$ResetServerAddresses = Get-AnsibleParam -obj $params -name "reset_server_addresses" -type "bool" -failifempty $false
$ServerAddresses = Get-AnsibleParam -obj $params -name "server_addresses" -type "list" -failifempty $false
$IPv6 = Get-AnsibleParam -obj $params -name "tcpip6" -type "bool" -failifempty $false

$result = @{
    changed = $false
}

if ($diff_mode) {
    $result.diff = @{}
    $result.diff.after = @{}
    $result.diff.before = @{}
}

$set_args = @{
    Suffix      = $Suffix
    ErrorAction = "Stop"
}

if ($NewName) {
    $set_args += @{ NewName = $NewName }
}

if ($null -ne $RegisterThisConnectionsAddress) {
    $set_args += @{ RegisterThisConnectionsAddress = $RegisterThisConnectionsAddress }
}

if ($null -ne $ResetServerAddresses) {
    $set_args += @{ ResetServerAddresses = $ResetServerAddresses }
}

if ($null -ne $ServerAddresses) {
    $set_args += @{ ServerAddresses = $ServerAddresses }
}

if ($null -ne $Ipv6) {
    $set_args += @{ IPv6 = $Ipv6 }
}

$module_result = Set-Net​Adapter​BySuffix @set_args

$result.changed = $module_result

Exit-Json -obj $result