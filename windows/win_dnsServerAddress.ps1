$ErrorActionPreference = "Stop"

try 
{
    $passedArgs = Parse-Args $args

    $definedParams = @(
        @{ Name = 'Address'; Mandatory = $true }
        @{ Name = 'InterfaceAlias'; Mandatory = $true }
        @{ Name = 'State'; Mandatory = $true }
        @{ Name = 'AddressFamily'; Mandatory = $false }
    )

    $params = @()
    foreach ($param in $definedParams) {
        $getParams = @{
            obj = $passedArgs
            name = $param.Name
            FailIfEmpty = $true
        }
        if ($param.Mandatory)
        {
            $getParams.emptyattributefailmessage = "The required parameter [$($param.Name)] was not used."
        }
        else
        {
            $getParams.emptyattributefailmessage = "The parameter [$($param.Name)] was empty."
        }
        Set-Variable -Name $param.Name -Value (Get-AnsibleParam @getParams)
    }

    $result = [pscustomobject]@{ changed = $false }

    $clientParams = @{
        'AddressFamily' = $AddressFamily
        'InterfaceAlias' = $InterfaceAlias
        'ErrorAction' = 'Ignore'
    }

    ## Ensure we can find the network adapter
    if (-not ($dnsClientServerAddresses = Get-DnsClientServerAddress @clientParams))
    {
        $aliases = (Get-DnsClientServerAddress).InterfaceAlias
        throw "Could not find network adapter with interface alias [$InterfaceAlias]. Possible aliases are [$($aliases -join ',')]"
    }
                
    if (@($dnsClientServerAddresses.ServerAddresses).Count -lt @($Address).Count)
    {
        Write-Verbose -Message 'One or more servers missing on the node.'
        $result.changed = $true
    }
    elseif (@($dnsClientServerAddresses.ServerAddresses).Count -gt @($Address).Count)
    {
        Write-Verbose -Message 'Too many servers defined on the node.'
        $result.changed = $true
    }
    else
    {
        $compParams = @{
            'ReferenceObject' = $dnsClientServerAddresses.ServerAddresses
            'DifferenceObject' = $Address
            'SyncWindow' = 0
        }
        if ($compare = Compare-Object @compParams)
        {
            Write-Verbose -Message 'The DNS server search order does not match.'
            $result.changed = $true
        }
    }
    
    if ($result.Changed)
    {
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $Address    
    }
    else
    {
        Write-Verbose -Message "The DNS server addresses are correct."
    }
}
catch
{
    Fail-Json ([pscustomobject]) $_.Exception.Message
}
finally
{
    Exit-Json $result
}