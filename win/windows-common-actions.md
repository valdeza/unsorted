# Things I commonly look up but forget about

## Little things
* `reg` - Registry Console Tool  
          Allows scripted querying and manipulation of the Windows registry.
* `sc`  - Service Control Manager CLI  
          Can be used to delete service entries with a missing or invalid reference, like when using the Oracle Database uninstaller.
* `certutil` - Certificate Services Utility  
               Can also be used to view cryptographic hashes for any file. See `certutil -hashfile -?` for more information.

## Troubleshooting

### File sharing (Windows-to-Windows)
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
* Just restart the computer, maybe? <!--With each passing year, PC uptime improves. Shut down your computer, they say! It's not a server, they say! Not counting the Patch Tuesday restarts, I probably could have stayed up for about half a year before I broke something.-->

### Network Connectivity Status Indicator (NCSI)
_The network thing in the system tray at the bottom right._

It may claim 'No Internet Access' even though Internet seems to work just fine for almost every application. But applications using Windows API to query network status would also be led to believe there is no Internet access (e.g. Microsoft Store). <!-- I might have overdone the Windows 10 privacy tweaking. Microsoft probably expects us to give in if they keep randomly reverting some of it every feature update. -->

In order of most to least likely resolution/safest to irreversible/least to most difficult (basically, go top-down):
- Are we sure it's connected? Cable plugged in? Router is online?  
	Try pinging the router and everything else between you and your ISP. Try pinging 8.8.8.8 (Google DNS). Next, try pinging google.com&nbsp;. If 8.8.8.8 works but google.com did not, it's a DNS problem. [Try switching to a different DNS.](https://support.microsoft.com/en-us/help/15089/windows-change-tcp-ip-settings)
- DIY NCSI CSI [[ref]](https://en.wikibooks.org/w/index.php?title=Windows_Troubleshooter_Guide/Network_Location_Awareness&oldid=3356444#Method): Let's try going through the NCSI process ourselves.
	1. Check for website connection
		1. Verify if able to perform DNS lookup by running  
			`nslookup.exe www.msftncsi.com %DNS_IP_ADDR%`&nbsp;.  
			Get current DNS server(s) in use by running  
			`ipconfig.exe /all`&nbsp;.
		2. Make HTTP request via _PowerShell_ command  
			`Invoke-WebRequest 'http://www.msftncsi.com/ncsi.txt'`  
			StatusCode should be 200 (HTTP OK) and Content should read "Microsoft NCSI".
	2. Check for DNS connection by running  
		`nslookup.exe dns.msftncsi.com %DNS_IP_ADDR%`&nbsp;.  
		The returned IP address should read `131.107.255.255`&nbsp;.
- Check hosts file at _%SystemRoot%\System32\Drivers\etc\hosts&nbsp;._  
	Suggested search strings: microsoft, msft
- Check network routing table by running `route.exe print`&nbsp;.
- Check NCSI-related system policies:  
	(All group policies below are under 'Machine/Computer Configuration&nbsp;&gt; Administrative Templates')  
	| Group Policy | Registry Entry |
	|-|-|
	| Network&nbsp;&gt; Network Connectivity Status Indicator&nbsp;&gt; ... | HKLM&nbsp;\\ Software&nbsp;\\ Policies&nbsp;\\ Microsoft&nbsp;\\ Windows&nbsp;\\ NetworkConnectivityStatusIndicator\* |
	| System&nbsp;&gt; Internet Communication Management&nbsp;&gt; Internet Communication settings&nbsp;&gt; Turn off Windows Network Connectivity Status Indicator active tests | HKLM&nbsp;\\ Software&nbsp;\\ Policies&nbsp;\\ Microsoft&nbsp;\\ Windows&nbsp;\\ NetworkConnectivityStatusIndicator!NoActiveProbe |
- Try performing a network reset. As of Windows 10 Version 1809, this can be started by going to [Settings&nbsp;&gt; Network & Internet&nbsp;&gt; Status] and scrolling to 'Network reset'.
- Make backups, pull the trigger, and [have Windows reset itself](https://support.microsoft.com/en-us/help/12415).

### Resetting graphics driver
`[Win] + [Ctrl] + [Shift] + [B]`

Supposedly available since Windows Update KB4022716 (June 27, 2017—KB4022716 (OS Build 15063.447), Applies to: Windows 10).  
source: https://www.reddit.com/r/sysadmin/comments/6l7cyk/kb4022716_win_ctrl_shift_b_windows_10/?ref=share&ref_source=link 

## Renaming accounts

	wmic useraccount where name='%TargetUsername%' call rename name='%NewUsername%'

e.g. To rename \\\\LocalWorkstation\Administrator, replace `%TargetUsername%` with Administrator.  
_Speaking of Administrator, don't forget to change the password for that, too.  
(A lot of people unknowingly still have it blank after installing Windows.)_

## Securing page/swap file
So Windows claims to secure it from unauthorised users. But what if you just boot to an alternative OS and try to inspect it?

### Overwrite page/swap file on shutdown
Enable Group Policy setting:  
_Computer Configuration/Windows Settings/Security Settings/Local Policies/Security Options/Shutdown: Clear virtual memory pagefile_  
or apply registry entry [(click here for .reg file)](regedit-entries/MemoryManagement - ClearPageFileAtShutdown.reg):  
`\\HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\ClearPageFileAtShutdown = dword:00000001`

This overwrites the file with zeroes on shutdown **but will greatly increase shutdown time** in direct proportion to the size of the file.

### Encrypt page/swap file
Run the following command as administrator:

	fsutil behavior set EncryptPagingFile 1

_Requires restart to take effect._

## Windows Defender: Configuring Automatic Updating
_To keep anti-virus up-to-date while Windows Update is configured to **not** automatically install updates._

In Windows 10 (and supposedly since Windows 8), anti-virus updates became tied with Windows Update. In this situation, you might have to install virus definition files alongside other Windows updates that require a machine restart.

To have Windows Defender at least keep _itself_ up-to-date, open Task Scheduler and create a new task: have it run program "C:\Program Files\Windows Defender\MpCmdRun.exe" with argument `-SignatureUpdate` . Have the task run as often as you like (suggested: daily frequency).

## Windows Update
### Automatic Restart Prevention Checklist
_Do let me know I have updates available. **Do not forcibly terminate everything I have open, Microsoft.**_

- Restrict task 'Microsoft\Windows\UpdateOrchestrator\Reboot'
	- Disable via Task Scheduler  
	  (and enable tasks history to track future attempts to run this task)
	- Restrict access to task file:
		1. Navigate to '%WINDIR%\System32\Tasks\Microsoft\Windows\UpdateOrchestrator'
		1. Take ownership of 'Reboot' (from SYSTEM) via `takeown`
		1. Rename 'Reboot' to 'Reboot.bak'
		1. Apply DENY ALL permissions:  
		   `icacls Reboot /inheritance:r /deny "Everyone:F" /deny "SYSTEM:F" /deny "Local Service:F" /deny "Administrators:F"`
		1. Create directory 'Reboot'  
		   	> Random fact: You cannot (re)create a file that has the same name as a pre-existing directory.
		1. Apply same ownership and permissions as 'Reboot.bak'
- Inspect group policies at 'Computer Configuration\Administrative Templates\Windows Components\Windows Update'
- Set connection to metered

### Check for updates on demand (without installing)
One of the following, depending on distribution:
```powershell
& wuaclt.exe /detectnow
(New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
& UsoClient.exe startscan
```

### Viewing installed updates/hotfixes
Relevant commands:

	:: "Quick-Fix Engineering"
	wmic qfe | find %KBnumber% [> %SaveOutputFilepath%]
	
	systeminfo [> %SaveOutputFilepath%]

### wuauserv.exe takes up 100% CPU
It's probably the fact that you have not restarted your PC in a while and you have updates waiting to be installed (requiring restart).

How? Using Procmon (Sysinternals' Process Monitor), notice how svchost.exe (netsvcs) constantly queries the value of registry entry "HKLM\SYSTEM\Setup\SystemSetupInProgress".

## Working with COM objects
_yay automation_

To fetch all registered COM objects:
```powershell
#PowerShell
Get-ChildItem HKLM:\SOFTWARE\Classes |
	Where-Object {$_.PSChildName -match '^\w+\.\w+$' -and (Test-Path "$($_.PSPath)\CLSID")} |
	Select-Object -ExpandProperty PSChildName
#source: http://www.powershellmagazine.com/2013/06/27/pstip-get-a-list-of-all-com-objects-available/
```
Working with COM objects:
```powershell
#PowerShell
# Create COM object to manipulate a Microsoft Excel instance
$comExcelApp = New-Object -ComObject "Excel.Application"
# List available properties and methods of COM object
$comExcelApp | Get-Member
# Alternatively, bind to a currently-running Microsoft Word instance
$comWordApp = [System.Runtime.InteropServices.Marshal]::GetActiveObject("Word.Application")
#yeahno as far as I know there's no 'Get-Object' or anything of the sort
```
COM objects are available in a wide variety of flavours, such as VBA <!--VisualBoyAdvance--> (Visual Basic for Applications):
```vb
Dim objExcel
Set objExcel = CreateObject("Excel.Application")
objExcel.Workbooks.Add
objExcel.Range("A1").Select
objExcel.ActiveCell.Value = "[auto-spreadsheet intensifies]"

' Reminder that you can bind to already-running instances
Dim objWord
Set objWord = GetObject(, "Word.Application")
```
