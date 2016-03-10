# Things I commonly look up but forget about
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

## Why Windows Update (wuauserv) Takes Up 100% CPU
It's probably the fact that you have not restarted your PC in a while and you have updates waiting to be installed (requiring restart).

How? Using Procmon (Sysinternals' Process Monitor), notice how svchost.exe (netsvcs) constantly queries the value of registry entry "HKLM\SYSTEM\Setup\SystemSetupInProgress".
