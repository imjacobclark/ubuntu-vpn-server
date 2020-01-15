#!/bin/bash 

IPADDR=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)

function configureOpenVPN {
    echo "Configuring OpenVPN"
    gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
    sed -i -e 's/dh dh1024.pem/dh dh2048.pem/' /etc/openvpn/server.conf
    sed -i -e 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/' /etc/openvpn/server.conf
    sed '/;push "dhcp-option DNS 208.67.222.222"/d' /etc/openvpn/server.conf
    sed '/;push "dhcp-option DNS 208.67.220.220"/d' /etc/openvpn/server.conf
    echo "dhcp-option DNS 10.8.0.1" >> /etc/openvpn/server.conf
    sed -i -e 's/;duplicate-cn"/"duplicate-cn"/' /etc/openvpn/server.conf
    sed -i -e 's/;user nobody/user nobody/' /etc/openvpn/server.conf
    sed -i -e 's/;group nogroup/group nogroup/' /etc/openvpn/server.conf
    cp -r /usr/share/easy-rsa/ /etc/openvpn
    mkdir /etc/openvpn/easy-rsa/keys
    sed -i -e 's/KEY_NAME="EasyRSA"/KEY_NAME="server"/' /etc/openvpn/easy-rsa/vars
    openssl dhparam -out /etc/openvpn/dh2048.pem 2048
    cd /etc/openvpn/easy-rsa && ln -s openssl-1.0.0.cnf openssl.cnf
    cd /etc/openvpn/easy-rsa && . ./vars
    cd /etc/openvpn/easy-rsa && ./clean-all
    cd /etc/openvpn/easy-rsa && ./build-ca --batch
    cd /etc/openvpn/easy-rsa && ./build-key-server --batch server
    cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn
    cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn
    cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn
    service openvpn restart
}

function configureDNSMasq {
    echo "Configuring DNSMasq"
    sed -i -e 's/"#listen-address="/"listen-address=127.0.0.1, 10.8.0.1"/' /etc/dnsmasq.conf
    sed -i -e 's/"#bind-interfaces"/"bind-interfaces"/' /etc/dnsmasq.conf
    service dnsmasq restart
}

function configureFirewall {
    echo "Configuring Firewall"
    curl http://winhelp2002.mvps.org/hosts.txt >> /etc/hosts
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    ufw allow ssh
    ufw allow 1194/udp
    sed -i -e 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
    sed -i "1i# START OPENVPN RULES\n# NAT table rules\n*nat\n:POSTROUTING ACCEPT [0:0]\n# Allow traffic from OpenVPN client to eth0\n\n-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE\nCOMMIT\n# END OPENVPN RULES\n" /etc/ufw/before.rules
    ufw --force enable
}

function generateVPNProfile {
    echo "Generating VPN profile"
    cd /etc/openvpn/easy-rsa && ./build-key --batch client1
    cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/keys/client.ovpn
    sed -i -e "s/my-server-1/$IPADDR/" /etc/openvpn/easy-rsa/keys/client.ovpn
    sed -i -e 's/;user nobody/user nobody/' /etc/openvpn/easy-rsa/keys/client.ovpn
    sed -i -e 's/;group nogroup/group nogroup/' /etc/openvpn/easy-rsa/keys/client.ovpn
    sed -i -e 's/ca ca.crt//' /etc/openvpn/easy-rsa/keys/client.ovpn
    sed -i -e 's/cert client.crt//' /etc/openvpn/easy-rsa/keys/client.ovpn
    sed -i -e 's/key client.key//' /etc/openvpn/easy-rsa/keys/client.ovpn
    echo "<ca>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
    cat /etc/openvpn/ca.crt >> /etc/openvpn/easy-rsa/keys/client.ovpn
    echo "</ca>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
    echo "<cert>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
    openssl x509 -outform PEM -in /etc/openvpn/easy-rsa/keys/client1.crt >> /etc/openvpn/easy-rsa/keys/client.ovpn
    echo "</cert>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
    echo "<key>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
    cat /etc/openvpn/easy-rsa/keys/client1.key >> /etc/openvpn/easy-rsa/keys/client.ovpn
    echo "</key>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
    
    cp /etc/openvpn/easy-rsa/keys/client.ovpn /root/
    cp /etc/openvpn/easy-rsa/keys/client1.crt /root/
    cp /etc/openvpn/easy-rsa/keys/client1.key /root/
    cp /etc/openvpn/easy-rsa/keys/ca.crt /root/
}

configureOpenVPN
configureDNSMasq
configureFirewall
generateVPNProfile
reboot
