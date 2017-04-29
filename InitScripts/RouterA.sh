bash <<EOF2
#useradd test;passwd test;sudo adduser test sudo
#sleep(1)
#apt-get update
#sleep(1)
#apt-get install quagga quagga-doc traceroute
#sleep(5)
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
 network 192.168.0.0/28 area 0.0.0.0
 network 192.168.1.0/28 area 0.0.0.0
 network 192.168.2.0/28 area 0.0.0.0
line vty
EOF
cat >> /etc/quagga/zebra.conf << EOF
interface eth1
 ip address 192.168.1.1/28
 ipv6 nd suppress-ra
interface eth2
 ip address 192.168.0.2/28
interface eth3
 ip address 192.168.2.1/28
 ipv6 nd suppress-ra
interface lo
ip forwarding
line vty
EOF
/etc/init.d/quagga start
exit
EOF2
