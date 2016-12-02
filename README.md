# Ubuntu 16.04 VPN Server
Quickly bootstrap a disposable VPN with DNS masking. 

### Features

* Secure VPN
* DNS Masking
* Basic Ad Blocking

### Stack

* OpenVPN
* dnsmasq
* ufw

This cloud-config will configure a fully functional and secure OpenVPN server with full DNS masking capabilities. It works out the box and requires no additional config. Once the machine has booted a ready to use `.ovpn` is available in the root users home directory.

The OpenVPN config generated may be used by multiple machines/connections at the same time.

Tested on Ubuntu 16.04 on Digital Ocean, will work anywhere where cloud-config can be loaded up when spinning up instances (AWS, Digital Ocean, Linode, etc.). See [How To Use Cloud-Config For Your Initial Server Setup | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-cloud-config-for-your-initial-server-setup).

Recomended to not assign an IPv6 address when spinning up your cloud instance and disabling IPv6 traffic at the client VPN also.

With thanks to [do_user_scripts](https://github.com/digitalocean/do_user_scripts).
