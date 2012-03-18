#--------------------------------------------------------------------------------------------
# STOP ANTI-VIRUS PROCESSES & SERVICES
#--------------------------------------------------------------------------------------------
# AUTHOR: Jasmine English
# CONTACT: jengl003@fiu.edu
# DATE CREATED: Dec. 5, 2011
# DATE MODIFIED: March 18, 2012
# ATTACHED: AVListMaster.txt, Instructions.txt
# SOURCES:
# 1 - Ed Wilson and Craig Liebendorfer, Scripting Guys
# 	http://blogs.technet.com/b/heyscriptingguy/archive/2009/10/01/hey-scripting-guy-october-1-2009.aspx
# 2 - Brian Wahoff
#	http://poshcode.org/1944
# 3 - Microsoft's TechNet, Powershell API
#--------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------
# Variables - Please redefine them as needed, or use the defaults
#--------------------------------------------------------------------------------------------
Write-Host -ForegroundColor Blue "Starting Kill AV Script..."

$ErrorActionPreference = "SilentlyContinue"

$WorkDir = "C:\edu.fiu.jengl003\monitorAV\"					# Directory of script
$AVListExclude = "Microsoft Corporation"					# List of AV companies to exclude
$DisableAVService = $false									# Disable AV services to stop them
															# from loading on reboot

$AVListMaster = Get-Content ($WorkDir+"AVListMaster.txt")	# Master list of AV companies
$AVProcs = @()
$AVServices = @()

#--------------------------------------------------------------------------------------------
# Functions...
#--------------------------------------------------------------------------------------------

#Get running processes and filter out AV processes
#function Get_AVProcess
#{
	#If process's company name matches a name in AVListMaster...
	Get-Process | `
	Where-Object {
		($AVListMaster -contains $_.Company) -or `
		($_.Path -like "C:\Program Files\Microsoft Security Client\*")
	} | `
	ForEach-Object {
		#...add process to AVList unless it is in exlusion list
		if ($AVListExclude -notcontains $_.Company) 
		{
			$AVProcs += $_.Name
		}
	}
#}

#Get AV service
#function Get_AVService
#{
	$temp0 = @()
	$temp1 = @()
	$temp2 = @()
	
	#Get services with same name as process
	Get-Service -Name $AVProcs | `
	ForEach-Object {
		$temp0 += $_.Name
	}
	
	#Get modules associated with a process, assuming some are services
	foreach ($AVProc in $AVProcs) 
	{
		(Get-Process $AVProc).modules | Select-Object -Property modulename |`
		Out-String -Stream | Select-String ".dll" -OutVariable temp1
	}
	
	#Format module name so that it can be called
	foreach ($t1 in $temp1)
	{
		$t1.toString().trim() | Out-String -OutVariable t2 		 #Remove whitespace
		$t2 -replace ".dll", "" | Out-String -OutVariable +temp2 #Remove extensions
	}
	
	$AVServices = $temp0 + $temp2
#}

#Stop AV service (Modified from Source (1))
#function Stop_AVService
#{
	foreach ($Service in $AVServices)
	{
		#Check if a service, else, go to next item in list
		if ( !(Get-Service $Service) ) {continue}
		
		$Status = $Service.Status
		
		Write-Host "Service $Service status is: $Status"
		$objWmiService = Get-Wmiobject -Class Win32_Service -Filter "name='$Service'"
		
		if ($objWMIService.Acceptstop)
 		{
			Write-Host "Stopping the $Service service now ..." 
			$rtn = $objWMIService.stopService()
			Switch ($rtn.returnvalue) 
  			{ 
			   0 {Write-Host -foregroundcolor green "Service $Service stopped"}
			   2 {Write-Host -foregroundcolor red "Service $Service reports access denied"}
			   5 {Write-Host -ForegroundColor red "Service $Service cannot accept control at this time"}
			   10 {Write-Host -ForegroundColor red "Service $Service is already stopped"}
			   DEFAULT {Write-Host -ForegroundColor red "Service $Service service reports ERROR $($rtn.returnValue)"}
  			}
 		}
		else
 		{ 
  			Write-Host -ForegroundColor magenta "$Service will not accept a stop request"
 		}
 	}
#}

#Stop AV process (Modified from Sources (2), (3))
#function Stop_AVProcess 
#{
	foreach ($Process in $AVProcs)
	{
		$WMIProc = Get-WMIObject Win32_Process -Filter "name='$Process.exe'"
		#$Name = $WMIProc.Name
		$ID = $WMIProc.ProcessID
		
		$WMIProc | ForEach-Object {
			$rtn = $WMIProc.Terminate()
			switch ($rtn.ReturnValue)
			{
				0 {Write-Host -foregroundcolor green "Process $Process stopped"}
				2 {Write-Host -foregroundcolor red "Process $Process reports access denied"}
				3 {Write-Host -foregroundcolor red "Process $Process reports insufficient privilege"}
				8 {Write-Host -foregroundcolor red "Process $Process reports unknown failure"}
				9 {Write-Host -foregroundcolor red "Path not found for $Process"}
				21 {Write-Host -foregroundcolor red "Invalid WMI parameter"}
			}
		}
	}
#}

#--------------------------------------------------------------------------------------------
# Optional Functions
#--------------------------------------------------------------------------------------------

#Prevent stopped AV service from starting up again after system restart
#function Disable_AVService
#{
if ($DisableAVService)
{
		foreach ($Service in $AVServices)
		{
			#Check if a service, else, go to next item in list
			if ( !(Get-Service $Service) ) {continue}
			
			Set-Service -Name $Service -StartupType Disabled
			
			Write-Host -foregroundcolor green "Service $Service disabled."
		}
}
#}

Write-Host -ForegroundColor Blue "Finished!"
#--------------------------------------------------------------------------------------------
# Super Function
#--------------------------------------------------------------------------------------------

#Put it all together for easy calling
#function Super_Function
#{
#	
#	Get_AVProcess
#	Get_AVService
#	Stop_AVService
#	Stop_AVProcess
#	if ($DisableAVService)
#	{
#		Disable_AVService
#	}
#	
#}

#--------------------------------------------------------------------------------------------
# Script
#--------------------------------------------------------------------------------------------
#Super_Function #That's it!