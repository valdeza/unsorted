# Linux Common Actions
*A compilation of things I might find myself doing often*

## Disabling ping response
\>\>/etc/sysctl.conf *(if existent)*

	net.ipv4.conf.icmp_echo_ignore_all = 1
*(if above file non-existent)*  

	$ echo 1 >/proc/sys/net/ipv4/icmp_echo_ignore_all

## _jq:_ Print each path per line
_Makes keys & values more easily greppable._

```sh
jq -r 'path(..)|map(tostring)|join(".")' < $INPUT_JSON_PATH
# also show value:
jq -r 'paths(scalars) as $p | "\($p|map(tostring)|join(".")) = \(.|getpath($p))"' < $INPUT_JSON_PATH
```

## Setting terminal title (in _gnome-terminal_)
_I have too many terminal windows and I start to forget which is which._

```sh
# usage: chtermtitle 'your new terminal title'
# suggestion: add to bash aliases
chtermtitle () 
{ 
  if [[ -z "$PS1_ORIG" ]]; then
    echo 'Original PS1 saved to $PS1_ORIG';
    PS1_ORIG="$PS1";
  fi;
  PS1="$(echo "$PS1_ORIG" | sed 's/\\\[\\e\]0;\\u@\\h: \\w\\a\\]//')";
  printf "\033]0;($*)\007"
}
```

## SOCKS5 proxied downloads by console
Since _wget_ does not seem to natively support SOCKS5 proxies, we can use _curl_ :
```
$ curl -x 'socks5://127.0.0.1:1080' -C - -O "$URL"

EXPLAINED OPTIONS
-C, --continue-at <offset>
   An offset of '-' tells curl to automatically find out where/how to resume
   a previously-interrupted transfer using the given output/input files.

-O, --remote-name
   In current working directory,
   write output to local file named like the remote file we get.

-x, --proxy [protocol://]host[:port]
   If protocol:// prefix omitted, http:// will be used.
```

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

## _netstat_ without _netstat_
Original source: https://staaldraad.github.io/2017/12/20/netstat-without-netstat/  
Copied here for easy personal reference.

```sh
awk 'function hextodec(str,ret,n,i,k,c){
  ret = 0
  n = length(str)
  for (i = 1; i <= n; i++) {
    c = tolower(substr(str, i, 1))
    k = index("123456789abcdef", c)
    ret = ret * 16 + k
  }
  return ret
}
function getIP(str,ret){
  ret=hextodec(substr(str,index(str,":")-2,2)); 
  for (i=5; i>0; i-=2) {
    ret = ret"."hextodec(substr(str,i,2))
  }
  ret = ret":"hextodec(substr(str,index(str,":")+1,4))
  return ret
} 
NR > 1 {{if(NR==2)print "Local - Remote";local=getIP($2);remote=getIP($3)}{print local" - "remote}}' /proc/net/tcp
```

## Network upload throttling
_Simulating poor/restrictive ISP service_

```sh
#apply:
# define target network interface
netif=enx4cd71725e3ce  # fetched from `ip`
tc qdisc add dev $netif root handle 44: htb default 442  # numbers are arbitrary 16-bit ids
tc class add dev $netif parent 44:441 classid 44:442 htb rate 300mbit
#undo:
tc qdisc delete dev $netif root handle 44:
```

## Toggle saving bash history
_It's kinda like incognito mode!_

To disable history saving: `$ set +o history`  
To enable history saving: `$ set -o history`  
To view the current setting: `$ set -o` (and all the other options)

The default shell usually does not append commands prefixed with a '` `' space.  
To not run shell exit functions (which include updating command history file), kill the current shell session with `kill -9 $$`.

## Querying public IP address
_Particularly useful if your Internet traffic goes through a router or proxy_

	$ curl ipinfo.io/ip

## _vim:_ Indent with spaces
```
:set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
:set autoindent
```
