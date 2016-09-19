#!powershell

# (c) 2015, Adam Bertram <@adbertram>
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

try 
{
    $passedArgs = Parse-Args $args

    $definedParams = @(
        @{ Name = 'idle_timeout'; Mandatory = $false }
        @{ Name = 'log_event_on_recycle'; Mandatory = $false }
        @{ Name = 'start_mode'; Mandatory = $false }
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

    #region Functions
    function Get-Value 
    {
        param(
            [string]$Path,
            [string]$Name
        )
		$defaultsPath = 'system.applicationHost/applicationPools/applicationPoolDefaults'
		if ($Path) {
			$filter = "$defaultsPath/$Path"
		} 
		else 
		{
			$filter = $defaultsPath
		}
		$params = @{
			'PSPath' = 'MACHINE/WEBROOT/APPHOST'
			'Filter' = $filter
			'Name' = $Name
		}
		$result = Get-WebConfigurationProperty @params
		if ($result -isnot [string]) {
			$output = $result.Value
		} else {
			$output = $result
		}
		return $output
	}

    function Set-Value {
        param(
            [string]$Path, 
            [string]$Name, 
            [string]$Value
        )
		$defaultsPath = 'system.applicationHost/applicationPools/applicationPoolDefaults'
		if ($Path) 
		{
			$filter = "$defaultsPath/$Path"
		} 
		else 
		{
			$filter = $defaultsPath
		}
		$params = @{
			'PSPath' = 'MACHINE/WEBROOT/APPHOST'
			'Filter' = $filter
			'Name' = $Name
			'Value' = $Value
		}
		
		Set-WebConfigurationProperty @params
	}
    #endregion

    foreach ($p in $definedParams) {
        if ($val = Get-Variable -Name $p.Name -ErrorAction SilentlyContinue) {
            $paramName = $p.Name -replace '_'
            $valParams = @{ Name = $paramName }
            switch ($p.Name) {
                'log_event_on_recycle' {  
                    $valParams.Path = 'recycling'
                }
                'idle_timeout' {  
                    $valParams.Path = 'processModel'
                }
                'start_mode' {  
                    $valParams.Path = $null
                }
                default {
                    throw "Unhandled parameter: [$($p.Name)]"
                }
            }
            if ((Get-Value @valParams) -ne $val.Value) {
                Set-Value @valParams -Value $val.Value
                $result.Changed = $true
            }
        }
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