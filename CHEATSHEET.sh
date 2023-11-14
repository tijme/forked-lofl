# ===================
#        Setup
# ===================
### General ###
# - All commands in the configuration section, except for the git and tun2socks-linux-amd64 commands need to be executed as root
# - IP range 10.0.0.0/16 is the IP range for victim.local
# - 10.0.10.10 is the domain controller of victim.local

### Network interfaces ###
# Find/replace in case names are different in your setup
# - ens33: Interface to the Internet
# - ens36: Interface between Linux routing VM and Offensive Windows VM
# - tun1: To be created tunnel device for tun2socks to reach the victim network

### Offensive Windows configuration ###
# - Uses Linux ens36 IP as both default gateway and DNS server


# ===================
#    Configuration
# ===================
### Prerequisites ###

# Living Off the Foreign Land scripts
git clone https://github.com/bitsadmin/lofl.git
cd lofl

# Tun2socks
# Obtain tun2socks from https://github.com/xjasonlyu/tun2socks/releases/ (probably you need tun2socks-linux-amd64.zip)
wget https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-amd64.zip
unzip tun2socks-linux-amd64.zip

### Network ###
# Create tunnel interface
./create_tun.sh tun1

# Configure NAT
./iptables_nat.sh -f ens36 ens33
./iptables_nat.sh -f ens36 tun1

# Configure routes
ip link set tun1 up
ip route add 10.0.0.0/8 via 198.18.0.1 dev tun1

# Tun2socks
./tun2socks-linux-amd64 -device tun1 -proxy socks5://127.0.0.1:8080

### Dnsmasq ###
# Install
apt install dnsmasq # Debian
pacman -S dnsmasq   # Arch
yum install dnsmasq # Red Hat

# Configure
cat << EOF > /etc/dnsmasq.conf
# Port
port=5353

# Victim network DNS server
server=/victim.local/10.0.10.10
server=/10.0.10.in-addr.arpa/10.0.10.10

# Default DNS server
server=1.0.0.1
EOF

# Apply config
systemctl restart dnsmasq


### DNS ###
# Configure nameserver
echo nameserver 127.0.0.1 > /etc/resolv.conf
chattr -f +i /etc/resolv.conf

# DNS over TCP
apt install python3-dnslib
./dns_over_tcp.py


### CLDAP ###
apt install socat
ssh -N -L 127.0.0.1:8080:127.0.0.1:52001 USER@SERVER
./cldaproxy.sh victim.local

# ===================
#     Validation
# ===================
### Linux routing VM ###
# Check if DNS resolves
host -t A victim.local

# Check if SMB port is accessible
# Make sure to check tun2socks output
nmap -Pn -sT -p445 victim.local


### Offensive Windows VM ###
# Check if DNS resolves
Resolve-DnsName victim.local

# List shares
net.exe view \\victim.local /all
