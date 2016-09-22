$ErrorActionPreference = "Stop"

try 
{
    $passedArgs = Parse-Args $args

    $definedParams = @(
        @{ Name = 'IdleTimeout'; Mandatory = $false }
        @{ Name = 'LogEventOnRecycle'; Mandatory = $false }
        @{ Name = 'StartMode'; Mandatory = $false }
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

    if ($LogEventOnRecycle -and ((Get-Value -Path 'recycling' -Name 'logEventOnRecycle') -ne ($LogEventOnRecycle -replace ' '))) {
        Set-Value -Path 'recycling' -Name 'logEventOnRecycle' -Value $LogEventOnRecycle
        $result.Changed = $true
    }

    if ($IdleTimeout -and ((Get-Value -Path 'processModel' -Name 'idleTimeout') -ne $IdleTimeout)) {
        Set-Value -Path 'processModel' -Name 'idleTimeout' -Value $IdleTimeout
        $result.Changed = $true
    }

    if ($StartMode -and ((Get-Value -Path $null -Name 'startMode') -ne $StartMode)) {
        Set-Value -Path $null -Name 'startmode' -Value $StartMode
        $result.Changed = $true
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