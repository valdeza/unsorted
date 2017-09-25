# Linux Common Actions
*A compilation of things I might find myself doing often*

## Disabling ping response
\>\>/etc/sysctl.conf *(if existent)*

	net.ipv4.conf.icmp_echo_ignore_all = 1
*(if above file non-existent)*  

	$ echo 1 >/proc/sys/net/ipv4/icmp_echo_ignore_all

<!--
## Metasploit Framework quick start
`msfdb init` - Initialise database for first time use.  
`msfupdate` - Update Metasploit Framework (MSF) at the start of almost all operations _if safe to do so_.  
`msfconsole` - Begin application.

#### In MSF Console:  
_Context-sensitive help is available by running `help`. Run `help $command` for command-specific help._  
`grep`/`search` - Identify exploit to use.  
`use $exploitName` - Select exploit.  
`show`:
- `show payloads` - List available payloads. _Meterpreter recommended._ Set via `set payload $payloadName`.
- `show options` - List available exploit settings. Set via `set $optionName $value`.
- `show missing` - List missing required settings.
- `show post` - List all post-exploitation modules. After finding a working exploit, useful for making your life easier.
- Module-specific listings are available via `help show`.  
  Of note: `evasion`, `targets`, `actions`
> Avoid running `show exploits`. This takes a long time listing all exploits.

`run`/`exploit` - Attempt exploit.

#### _post/multi/manage/shell_to_meterpreter_
This particular post-exploitation module can be used to upgrade an obtained shell into a meterpreter. Useful for easier file exfiltration.

1. If you are currently in the shell session, background the session via Ctrl+Z.
1. Enter `use multi/manage/shell_to_meterpreter`.
1. Use `sessions` to determine session number of shell.  
   `set SESSION $shellSessionNumber` as appropriate.
1. `run` to spawn meterpreter. Sometimes takes more than one try.
1. Switch to the meterpreter via `sessions -i $meterpreterSessionNumber`.
-->

## Toggle saving bash history
_It's kinda like incognito mode!_

To disable history saving: `$ set +o history`  
To enable history saving: `$ set -o history`  
To view the current setting: `$ set -o` (and all the other options)

## Querying public IP address
_Particularly useful if your Internet traffic goes through a router or proxy_

	$ curl ipinfo.io/ip
