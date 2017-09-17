# Linux Common Actions
*A compilation of things I might find myself doing often*

## Disabling ping response
\>\>/etc/sysctl.conf *(if existent)*

	net.ipv4.conf.icmp_echo_ignore_all = 1
*(if above file non-existent)*  

	$ echo 1 >/proc/sys/net/ipv4/icmp_echo_ignore_all

## Toggle saving bash history
_It's kinda like incognito mode!_

To disable history saving: `$ set +o history`  
To enable history saving: `$ set -o history`  
To view the current setting: `$ set -o` (and all the other options)

## Querying public IP address
_Particularly useful if your Internet traffic goes through a router or proxy_

	$ curl ipinfo.io/ip
