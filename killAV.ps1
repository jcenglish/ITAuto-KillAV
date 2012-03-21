<# 
.SYNOPSIS 
    Stop all Anti-Virus processes and services, optionally disable the services.
.DESCRIPTION 
    For those times when you need to temporarily stop Anti-Virus programs in order
	to complete other tasks, such as installing software. This script filters
	running processes and services using a master list of Anti-Virus products path names.
	Optionally, you can choose to disable the filtered services as well.
.NOTES 
    File Name  : killAV.ps1 
    Author     : Jasmine English - jengl003@fiu.edu 
    Requires   : PowerShell V2, AVListMaster.txt
.LINK 
    https://github.com/theRedmage/ITAuto-KillAV
#>

#--------------------------------------------------------------------------------------------
# SOURCES:
#--------------------------------------------------------------------------------------------
# Microsoft TechNet Library <technet.microsoft.com>
# Hey, Scripting Guy! <http://blogs.technet.com/b/heyscriptingguy/>
#--------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------
# Variables - Please redefine them as needed, or use the defaults
#--------------------------------------------------------------------------------------------

$ErrorActionPreference = "SilentlyContinue"

$WorkDir = "F:\Documents\School\IT Automation\KillAV\"				# Directory of script
$AVListExclude = "*Program Files*\PowerGUI\*"							# List of AV paths to exclude
$DisableAVService = $false											# Disable AV services to stop them
																	# from loading on reboot

$AVListMaster = Get-Content -Path ($WorkDir+"AVListMaster_a.txt")	# Master list of AV paths
$AVServs = @()
$AVProcs = @()

#--------------------------------------------------------------------------------------------
# Functions...
#--------------------------------------------------------------------------------------------

Write-Host -ForegroundColor Blue "Starting KillAV script..."

##Get AV processes and services
#
ForEach($line in $AVListMaster)
{
	$tempProcs += Get-WmiObject -Class Win32_Process |
	Where-Object {$_.Path -like $line}
}

ForEach($line in $AVListMaster)
{
	$tempServs += Get-WmiObject -Class Win32_Service |
	Where-Object {$_.PathName -like $line}
}
#
##

##Remove exclusions
#
if ($AVListExclude -ne "")
{
	ForEach($line in $AVListExclude)
	{
		$AVProcs = @($tempProcs | Where-Object {$_.Path -notlike $line})
	}

	ForEach($line in $AVListExclude)
	{
		$AVServs = @($tempServs | Where-Object {$_.Path -notlike $line})
	}
}
#
##

##Stop AV service (Modified from Source (1))
#
foreach ($Service in $AVServs)
{	
	$ServName = $Service.Name
	$ServStatus = $Service.Status
	Write-Host -ForegroundColor DarkBlue "Service $ServName status is $ServStatus"
	
	if ($Service.AcceptStop)
	{
		Write-Host -ForegroundColor DarkBlue "Stopping the $ServName service now ..." 
		$rtn = $Service.StopService()
		Switch ($rtn.Returnvalue) 
		{ 
		   0 {Write-Host -foregroundcolor green "Service $ServName stopped"}
		   2 {Write-Host -foregroundcolor red "Service $ServName reports access denied"}
		   5 {Write-Host -ForegroundColor red "Service $ServName cannot accept control at this time"}
		   10 {Write-Host -ForegroundColor red "Service $ServName is already stopped"}
		   DEFAULT {Write-Host -ForegroundColor red "Service $ServName service reports ERROR $($rtn.ReturnValue)"}
		}
	}
	else
	{ 
		Write-Host -ForegroundColor magenta "$ServName will not accept a stop request"
	}
}
#
##

##Stop AV process (Modified from Sources (2), (3))
#
foreach ($Process in $AVProcs)
{
	$Process | ForEach-Object {
		$ProcName = $Process.Name
		
		$rtn = $Process.Terminate()
		switch ($rtn.ReturnValue)
		{
			0 {Write-Host -foregroundcolor green "Process $ProcName stopped"}
			2 {Write-Host -foregroundcolor red "Process $ProcName reports access denied"}
			3 {Write-Host -foregroundcolor red "Process $ProcName reports insufficient privilege"}
			8 {Write-Host -foregroundcolor red "Process $ProcName reports unknown failure"}
			9 {Write-Host -foregroundcolor red "Path not found for $ProcName"}
			21 {Write-Host -foregroundcolor red "Invalid WMI parameter"}
		}
	}
}
#
##

##Prevent stopped AV service from starting up again after system restart
#
if ($DisableAVService)
{
	foreach ($Service in $AVServs)
	{
		$Service.ChangeStartMode("Disabled")
		Write-Host -foregroundcolor green "Service $ServName disabled."
	}
}
#
##

Write-Host -ForegroundColor Blue "Finished!"