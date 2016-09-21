#!powershell

# (c) 2016, Adam Bertram <@adbertram>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

$ErrorActionPreference = "Stop"

function New-DnsRecord
{
	[OutputType([void])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Server,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ZoneName,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Type,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Target,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	begin
	{
		$ErrorActionPreference = 'Stop'
	}
	process
	{
		try
		{
			$fqdnName = $Name,$ZoneName -join '.'
			$wmiClass = 'MicrosoftDNS_{0}Type' -f $Type
			
			$invokeParams = @{
				Name = 'CreateInstanceFromPropertyData'
				Class = $wmiClass
				Namespace = 'root\MicrosoftDNS'
				ArgumentList = $ZoneName,$Server,$Target,$fqdnName
				ComputerName = $Server
			}
			if ($PSBoundParameters.ContainsKey('Credential'))
			{
				$invokeParams.Credential = $Credential
			}
			$null = Invoke-WmiMethod @invokeParams 
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}

function Get-DnsRecord
{
	[OutputType()]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Server,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ZoneName,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Type,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	begin
	{
		$ErrorActionPreference = 'Stop'
	}
	process
	{
		try
		{
			$wmiParams = @{
				ComputerName = $Server
				Namespace = 'root\MicrosoftDns'
				Class = ('MicrosoftDNS_{0}Type' -f $Type)
				Filter = "ContainerName = '$ZoneName' AND OwnerName = '$Name.$ZoneName'"  
			}
			if ($PSBoundParameters.ContainsKey('Credential'))
			{
				$wmiParams.Credential = $Credential
			}
			Get-WmiObject @wmiParams
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}

function New-Credential
{
	[OutputType([pscredential])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Password
	)
	begin
	{
		$ErrorActionPreference = 'Stop'
	}
	process
	{
		try
		{
			$sPass = ConvertTo-SecureString $Password -AsPlainText -Force
			New-Object System.Management.Automation.PSCredential ($Username, $sPass)
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}

try {

    $result = [pscustomobject]@{ changed = $false }

    $passedArgs = Parse-Args $args

    $definedParams = @(
        @{ Name = 'name'; Mandatory = $true }
        @{ Name = 'target'; Mandatory = $true }
        @{ Name = 'zone_name'; Mandatory = $true }
		@{ Name = 'user_name'; Mandatory = $false }
		@{ Name = 'password'; Mandatory = $false }
		@{ Name = 'type'; Mandatory = $false; DefaultValue = 'A'; ValidateSet = @('A','CNAME') }
    )

    foreach ($param in $definedParams) {
        $getParams = @{
            obj = $passedArgs
            name = $param.Name
        }
        if ($param['Mandatory']) {
            $getParams.emptyattributefailmessage = "The required parameter [$($param.Name)] was not used."
            $getParams.FailIfEmpty = $true
        }
        elseif ($param['DefaultValue']) {
            $getParams.default = $param.DefaultValue
        } else {
            $getParams.FailIfEmpty = $true
            $getParams.emptyattributefailmessage = "The parameter [$($param.Name)] was empty."
        }
		if ($param['ValidateSet']) {
			$getParams.ValidateSet = $param.ValidateSet
		}
        Set-Variable -Name $param.Name -Value (Get-AnsibleParam @getParams)
    }

	if (($type -eq 'CNAME') -and ($target -notmatch '^(.*)\.(.*)\.(.*)$')) {
		throw 'When creating a CNAME record, Target must be a FQDN.'
	} elseif (($type -eq 'A') -and ($target -notmatch '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')) {
		throw 'When creating an A record, Target must be an IP address.'
	}
	if ($user_name -and (-not $password)) {
		throw "user_name and password must be used together."
	}
	if ((-not $user_name) -and $password) {
		throw "user_name and password must be used together."
	}

	$sharedParams = @{
		Name = $name.Trim('.') ## Ansible facts have a trailing period. WTF? oh well.
		Server = $zone_name
		ZoneName = $zone_name
		Type = $type
	}
	if ($user_name -and $password) {
		$sharedParams.Credential = New-Credential -Username $user_name -Password $password
	}
	
	if (-not ($existingRecord = Get-DnsRecord @sharedParams)) {
		Add-Content -Path c:\debug.txt -Value "no dns record: [$($sharedParams | Out-String)]"
		New-DnsRecord @sharedParams -Target $target
		if (-not (Get-DnsRecord @sharedParams)) {
			throw "Attempted to create DNS record but failed."
		}
		$result.Changed = $true
	}## TODO: What if the record exists but has a different IP address?
}
catch
{
    Fail-Json ([pscustomobject]) $_.Exception.Message
}
finally
{
    Exit-Json $result
}