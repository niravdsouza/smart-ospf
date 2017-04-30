bash <<EOF2
#useradd test;passwd test;sudo adduser test sudo
#apt-get update
#apt-get install quagga quagga-doc traceroute
cp /usr/share/doc/quagga/examples/zebra.conf.sample /etc/quagga/zebra.conf
cp /usr/share/doc/quagga/examples/ospfd.conf.sample /etc/quagga/ospfd.conf
chown quagga.quaggavty /etc/quagga/*.conf
chmod 640 /etc/quagga/*.conf
sed -i s'/zebra=no/zebra=yes/' /etc/quagga/daemons
sed -i s'/ospfd=no/ospfd=yes/' /etc/quagga/daemons
echo 'VTYSH_PAGER=more' >>/etc/environment 
echo 'export VTYSH_PAGER=more' >>/etc/bash.bashrc
cat >> /etc/quagga/ospfd.conf << EOF
interface eth1
interface eth2
interface eth3
interface lo
router ospf
 network 192.168.6.0/28 area 0.0.0.0
 network 192.168.3.0/28 area 0.0.0.0
 network 192.168.2.0/28 area 0.0.0.0
line vty
EOF
cat >> /etc/quagga/zebra.conf << EOF
interface eth3
 ip address 192.168.2.2/28
 ipv6 nd suppress-ra
interface eth2
 ip address 192.168.6.1/28
 ipv6 nd suppress-ra
interface eth1
 ip address 192.168.3.1/28
 ipv6 nd suppress-ra
interface lo
ip forwarding
line vty
EOF
/etc/init.d/quagga start
exit
EOF2
