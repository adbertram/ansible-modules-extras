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

try {

    $result = [pscustomobject]@{ changed = $false }

    $allPassedArgs = Parse-Args $args

    $definedParams = @(
        @{ Name = 'enabled'; Mandatory = $false; }
        @{ Name = 'accept_trusted_publisher_certs'; Mandatory = $false }
		@{ Name = 'elevate_non_admins'; Mandatory = $false }
		@{ Name = 'target_group'; Mandatory = $false }
		@{ Name = 'windows_update_server_url'; Mandatory = $false }
		@{ Name = 'windows_update_status_server_url'; Mandatory = $false }
		@{ Name = 'automatic_update_options'; Mandatory = $false; ValidateSet = 'notify_before_download', 'auto_download_and_notify', 'auto_download_and_schedule', 'user_configurable' }
		@{ Name = 'auto_install_minor_updates'; Mandatory = $false }
		@{ Name = 'detection_frequency'; Mandatory = $false }
		@{ Name = 'no_auto_reboot_with_logged_on_users'; Mandatory = $false }
		@{ Name = 'no_auto_update'; Mandatory = $false }
		@{ Name = 'reboot_launch_timeout'; Mandatory = $false }
		@{ Name = 'reboot_warning_timeout'; Mandatory = $false }
		@{ Name = 'reschedule_wait_time'; Mandatory = $false }
		@{ Name = 'scheduled_install_day'; Mandatory = $false; ValidateSet = 'every_day', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday' }
		@{ Name = 'scheduled_install_time'; Mandatory = $false }
		@{ Name = 'update_source'; Mandatory = $false }
    )

	foreach ($param in $definedParams) {
		$getParams = @{
			obj = $allPassedArgs
			name = $param.Name
		}
		if ($param['Mandatory'] -eq $true) {
			$getParams.emptyattributefailmessage = "The required parameter [$($param.Name)] was not used."
			$getParams.FailIfEmpty = $true
		}
		elseif ($param['DefaultValue']) {
			$getParams.default = $param.DefaultValue
		}
		if ($param['ValidateSet']) {
			$getParams.ValidateSet = $param.ValidateSet
		}
		Set-Variable -Name $param.Name -Value (Get-AnsibleParam @getParams)
	}

	if ($windows_update_server_url -and (-not $windows_update_status_server_url))
	{
		$windows_update_status_server_url = $windows_update_server_url
	}
	if ($windows_update_status_server_url -and (-not $windows_update_server_url))
	{
		$windows_update_server_url = $windows_update_status_server_url
	}

	$regKeyValuesToUpdate = @{}
			
	$wuRegKeyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
	$wuParamToRegKeyMap = @{
		'enabled' = 'DisableWindowsUpdateAccess'
		'accept_trusted_publisher_certs' = 'AcceptTrustedPublisherCerts'
		'elevate_non_admins' = 'ElevateNonAdmins'
		'target_group' = 'TargetGroup'
		'windows_update_server_url' = 'WUServer'
		'windows_update_status_server_url' = 'WUStatusServer'
	}
	
	$auRegKeyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
	$auParamToRegKeyMap = @{
		'automatic_update_options' = 'AUOptions'
		'auto_install_minor_updates' = 'AutoInstallMinorUpdates'
		'detection_frequency' = 'DetectionFrequency'
		'no_auto_reboot_with_logged_on_users' = 'NoAutoRebootWithLoggedOnUsers'
		'no_auto_update' = 'NoAutoUpdate'
		'reboot_relaunch_timeout' = 'RebootRelaunchTimeout'
		'reboot_warning_timeout' = 'RebootWarningTimeout'
		'reschedule+wait_time' = 'RescheduleWaitTime'
		'scheduled_install_day' = 'ScheduledInstallDay'
		'scheduled_install_time' = 'ScheduledInstallTime'
		'update_source' = 'UseWUServer'
	}

	$wuRegPropNames = (Get-ItemProperty -Path $wuRegKeyPath | Get-Member -MemberType NoteProperty).Name
	$wuRegKeys = (Get-ItemProperty -Path $wuRegKeyPath).PSObject.Properties | Where-Object { $_.Name -in $wuRegPropNames } | Select-Object Name, Value
	
	$auRegPropNames = (Get-ItemProperty -Path $auRegKeyPath | Get-Member -MemberType NoteProperty).Name
	$auRegKeys = (Get-ItemProperty -Path $auRegKeyPath).PSObject.Properties | Where-Object { $_.Name -in $auRegPropNames } | Select-Object Name, Value

	$userDefinedArgs = $allPassedArgs.PSObject.Properties | Where-Object { $_.Name -in $definedParams.Name } | Select-Object Name,Value
	@($userDefinedArgs) | ForEach-Object {
			$paramName = $_.Name
			$paramValue = $_.Value
Add-Content -Path c:\debug.txt -Value "$paramName - [$paramValue]"
			if ($paramName -in $wuParamToRegKeyMap.Keys)
			{
				$mapTable = $wuParamToRegKeyMap
				$keyPath = $wuRegKeyPath
				$regKeys = $wuRegKeys
			}
			elseif ($paramName -in $auParamToRegKeyMap.Keys)
			{
				$mapTable = $auParamToRegKeyMap
				$keyPath = $auRegKeyPath
				$regKeys = $auRegKeys
			}
			else
			{
				throw "Could not find a registry name match for parameter [$($paramName)]."
			}
			
			if (-not ($regKeyName = $mapTable[$paramName]))
			{
				throw "Could not registry key that matches up to parameter [$($paramName)]"
			}
			
			$currentRegKeyValue = @($regKeys).where({ $_.Name -eq $regKeyName }) | Select-Object -ExpandProperty Value

			switch ($regKeyName) {
				'DisableWindowsUpdateAccess' {
					$currentConvertedRegKeyValue = -not [bool]$currentRegKeyValue
					$expectedRegKeyValue = [int](-not $paramValue)
				}
				'AUOptions' {
					$auOptionMap = @{
						2 = 'NotifyBeforeDownload'
						3 = 'AutoDownloadAndNotify'
						4 = 'AutoDownloadAndSchedule'
						5 = 'UserConfigurable'
					}
					$currentConvertedRegKeyValue = $auOptionMap[$currentRegKeyValue]
					$expectedRegKeyValue = ($auOptionMap.GetEnumerator() | Where-Object { $_.Value -eq $paramValue}).Key
				}
				'ScheduledInstallDay' {
					$dayMap = @{
						0 = 'EveryDay'
						1 = 'Monday'
						2 = 'Tuesday'
						3 = 'Wednesday'
						4 = 'Thursday'
						5 = 'Friday'
					}
					$currentConvertedRegKeyValue = $dayMap[$currentRegKeyValue]
					$expectedRegKeyValue = ($dayMap.GetEnumerator() | Where-Object { $_.Value -eq $paramValue}).Key
				}
				'UseWUServer' {
					$updateSourceMap = @{
						0 = 'MicrosoftUpdate'
						1 = 'WSUS'
					}
					$currentConvertedRegKeyValue = $updateSourceMap[$paramValue]
				}
				default
				{
					if ($paramValue.GetType().FullName -eq 'System.Boolean')
					{
						$currentConvertedRegKeyValue = [bool]$currentRegKeyValue
						$expectedRegKeyValue = [int]($paramValue)
					}
					else
					{
						$currentConvertedRegKeyValue = $currentRegKeyValue
						$expectedRegKeyValue = $paramValue
					}
				}
			}
			
			if ($paramValue -ne $currentConvertedRegKeyValue)
			{
				$regKeyValuesToUpdate += @{
					'KeyPath' = $keyPath
					'Name' = $regKeyName
					'KeyValue' = $expectedRegKeyValue
				} 
			}
		}
	
	if ($regKeyValuesToUpdate.Keys.Count -gt 0)
	{
		## Attempt to change all registry values
		$regKeyValuesToUpdate | ForEach-Object {
			Set-ItemProperty -Path $_.KeyPath -Name $_.Name -Value $_.KeyValue
		}
		
		## Verify all reg values were changed.
		$regKeyValuesToUpdate | ForEach-Object {
			if (((Get-ItemProperty -Path $_.KeyPath -Name $_.Name).($_.Name)) -ne $_.KeyValue) {
				throw "Failed to set reg key [$($_.KeyPath)]:[$($_.Name)] to value: [$($_.KeyValue)]"
			}
		}
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