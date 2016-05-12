# Things I commonly look up but forget about

## Little things
* `sc` - Service Control Manager CLI  
         Can be used to delete service entries with a missing or invalid reference, like when using the Oracle Database uninstaller.

## File sharing (Windows-to-Windows)
In order of my most to least common:
* Is the folder shared to begin with?  
  Navigate to `\\%computername%\` and see if your folder appears. It should.
* Is File and Printer Sharing enabled on the network adapter?  
  While you're at it, probably wouldn't hurt to (temporarily) enable other items that could make your PC more discoverable and responsive to inbound connections.
* Is the firewall specifically blocking port 445?  
  Windows says it uses this port for file sharing.
* Give Windows troubleshooter a go?  
  Server: Run `msdt -id NetworkDiagnosticsInbound` (Incoming Connections troubleshooter)  
  Client: Run `msdt -id NetworkDiagnosticsFileShare` (Shared Folders troubleshooter)
  * Reset Windows Sockets?  
    Sometimes the troubleshooter mentions that the "Windows Sockets registry entries required for network connectivity are missing" but does not seem fix it. So it is reset by running `netsh winsock reset` **as administrator**.
* Just restart the computer, maybe? [](With each passing year, PC uptime improves. Shut down your computer, they say! It's not a server, they say! Not counting the Patch Tuesday restarts, I probably could have stayed up for about half a year before I broke something.)

## Renaming accounts

	wmic useraccount where name='%TargetUsername%' call rename name='%NewUsername%'

e.g. To rename \\\\LocalWorkstation\Administrator, replace `%TargetUsername%` with Administrator.  
_Speaking of Administrator, don't forget to change the password for that, too.  
(A lot of people unknowingly still have it blank after installing Windows.)_

## Viewing installed updates/hotfixes
Relevant commands:

	:: "Quick-Fix Engineering"
	wmic qfe | find %KBnumber% [> %SaveOutputFilepath%]
	
	systeminfo [> %SaveOutputFilepath%]

## Why Windows Update (wuauserv) takes up 100% CPU
It's probably the fact that you have not restarted your PC in a while and you have updates waiting to be installed (requiring restart).

How? Using Procmon (Sysinternals' Process Monitor), notice how svchost.exe (netsvcs) constantly queries the value of registry entry "HKLM\SYSTEM\Setup\SystemSetupInProgress".
